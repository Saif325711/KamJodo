const Booking = require('../models/Booking');
const WorkerProfile = require('../models/WorkerProfile');
const User = require('../models/User');

// In-memory fallback store for bookings (when MongoDB is not connected)
const { getIsConnected } = require('../config/db');
const localBookings = new Map();
let _bookingCounter = 1;

// ─── Helpers ─────────────────────────────────────────────────────────────────

function _enrichBooking(booking, customerUser, workerProfile, workerUser) {
  return {
    id: booking._id || booking.id,
    status: booking.status,
    description: booking.description,
    notes: booking.notes,
    scheduledAt: booking.scheduledAt,
    estimatedPrice: booking.estimatedPrice,
    finalPrice: booking.finalPrice,
    customerAddress: booking.customerAddress,
    customerLocation: booking.customerLocation,
    customer: customerUser
      ? { id: customerUser._id, name: customerUser.name, phone: customerUser.phone, profilePhoto: customerUser.profilePhoto }
      : null,
    worker: workerProfile
      ? {
          id: workerProfile._id,
          name: workerUser?.name || '',
          profilePhoto: workerUser?.profilePhoto || '',
          ratingAverage: workerProfile.ratingAverage,
          completedJobs: workerProfile.completedJobs,
          startingPrice: workerProfile.startingPrice,
        }
      : null,
    createdAt: booking.createdAt,
    acceptedAt: booking.acceptedAt,
    arrivedAt: booking.arrivedAt,
    startedAt: booking.startedAt,
    completedAt: booking.completedAt,
  };
}

// ─── Create Booking ───────────────────────────────────────────────────────────

/**
 * POST /api/v1/bookings
 * Customer creates a booking request
 */
async function createBooking(req, res, next) {
  try {
    const customerId = req.user.userId;
    const {
      workerId,
      categoryId,
      postId,
      description,
      notes,
      scheduledAt,
      estimatedPrice,
      customerLocation,
      customerAddress,
    } = req.body;

    if (!workerId) {
      return res.status(400).json({ success: false, message: 'workerId is required.', code: 'VALIDATION_ERROR' });
    }

    const bookingData = {
      customerId,
      workerId,
      categoryId: categoryId || null,
      postId: postId || null,
      description: String(description || '').trim(),
      notes: String(notes || '').trim(),
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      estimatedPrice: Number(estimatedPrice) || 0,
      customerLocation: customerLocation || null,
      customerAddress: customerAddress || {},
      status: 'requested',
    };

    let booking;
    if (getIsConnected()) {
      booking = await Booking.create(bookingData);
    } else {
      const id = `booking_${_bookingCounter++}`;
      booking = { ...bookingData, id, _id: id, createdAt: new Date() };
      localBookings.set(id, booking);
    }

    return res.status(201).json({
      success: true,
      message: 'Booking request created.',
      data: { bookingId: booking._id || booking.id, status: booking.status },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Get Booking ──────────────────────────────────────────────────────────────

/**
 * GET /api/v1/bookings/:bookingId
 * Only customer, assigned worker, or admin can view
 */
async function getBooking(req, res, next) {
  try {
    const { bookingId } = req.params;
    const { userId, role } = req.user;

    let booking;
    if (getIsConnected()) {
      booking = await Booking.findById(bookingId).lean();
    } else {
      booking = localBookings.get(bookingId);
    }

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.', code: 'BOOKING_NOT_FOUND' });
    }

    // Authorization check
    const isCustomer = booking.customerId?.toString() === userId;
    const workerProfile = getIsConnected() ? await WorkerProfile.findById(booking.workerId).lean() : null;
    const isWorker = workerProfile?.userId?.toString() === userId;
    const isAdmin = role === 'admin';

    if (!isCustomer && !isWorker && !isAdmin) {
      return res.status(403).json({ success: false, message: 'Not authorized.', code: 'UNAUTHORIZED_BOOKING_ACCESS' });
    }

    const customerUser = getIsConnected() ? await User.findById(booking.customerId).lean() : null;
    const workerUser = getIsConnected() && workerProfile ? await User.findById(workerProfile.userId).lean() : null;

    return res.json({ success: true, data: _enrichBooking(booking, customerUser, workerProfile, workerUser) });
  } catch (error) {
    next(error);
  }
}

// ─── My Bookings ──────────────────────────────────────────────────────────────

/**
 * GET /api/v1/bookings/me
 * Customer: their bookings.  Worker: their job requests
 */
async function getMyBookings(req, res, next) {
  try {
    const { userId, role } = req.user;
    const { status, page = 1, limit = 20 } = req.query;

    const filter = {};
    if (status) filter.status = status;

    let bookings = [];

    if (getIsConnected()) {
      if (role === 'customer') {
        filter.customerId = userId;
      } else if (role === 'worker') {
        const profile = await WorkerProfile.findOne({ userId }).lean();
        if (profile) filter.workerId = profile._id;
      }
      const skip = (parseInt(page) - 1) * parseInt(limit);
      bookings = await Booking.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .lean();
    } else {
      // Local fallback
      bookings = Array.from(localBookings.values())
        .filter((b) => role === 'customer' ? b.customerId === userId : true)
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    return res.json({ success: true, data: bookings });
  } catch (error) {
    next(error);
  }
}

// ─── Worker accepts booking (ATOMIC) ─────────────────────────────────────────

/**
 * POST /api/v1/bookings/:bookingId/accept
 * Worker only — atomic update ensures only one worker can claim
 */
async function acceptBooking(req, res, next) {
  try {
    const { userId } = req.user;
    const { bookingId } = req.params;

    const workerProfile = getIsConnected()
      ? await WorkerProfile.findOne({ userId }).lean()
      : null;

    let booking;

    if (getIsConnected()) {
      // Atomic conditional update — only succeeds if still 'requested'
      booking = await Booking.findOneAndUpdate(
        { _id: bookingId, status: 'requested' },
        {
          status: 'accepted',
          acceptedAt: new Date(),
          workerUserId: userId,
          ...(workerProfile && { workerId: workerProfile._id }),
        },
        { new: true }
      );

      if (!booking) {
        return res.status(409).json({
          success: false,
          message: 'This booking is no longer available.',
          code: 'BOOKING_NOT_AVAILABLE',
        });
      }
    } else {
      booking = localBookings.get(bookingId);
      if (!booking || booking.status !== 'requested') {
        return res.status(409).json({ success: false, message: 'Booking not available.', code: 'BOOKING_NOT_AVAILABLE' });
      }
      booking.status = 'accepted';
      booking.acceptedAt = new Date();
      localBookings.set(bookingId, booking);
    }

    return res.json({
      success: true,
      message: 'Booking accepted.',
      data: { bookingId: booking._id || booking.id, status: booking.status },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Reject Booking ───────────────────────────────────────────────────────────

/**
 * POST /api/v1/bookings/:bookingId/reject
 */
async function rejectBooking(req, res, next) {
  try {
    const reason = String(req.body?.reason || '').trim();
    const { bookingId } = req.params;

    let booking;
    if (getIsConnected()) {
      booking = await Booking.findOneAndUpdate(
        { _id: bookingId, status: 'requested' },
        { status: 'rejected', rejectionReason: reason },
        { new: true }
      );
    } else {
      booking = localBookings.get(bookingId);
      if (booking && booking.status === 'requested') {
        booking.status = 'rejected';
        booking.rejectionReason = reason;
        localBookings.set(bookingId, booking);
      }
    }

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found or already processed.', code: 'BOOKING_NOT_FOUND' });
    }
    return res.json({ success: true, message: 'Booking rejected.', data: { status: 'rejected' } });
  } catch (error) {
    next(error);
  }
}

// ─── Update Status ────────────────────────────────────────────────────────────

/**
 * PATCH /api/v1/bookings/:bookingId/status
 * Worker updates: worker_on_the_way → arrived → service_started → service_completed
 */
async function updateBookingStatus(req, res, next) {
  try {
    const newStatus = String(req.body?.status || '').toLowerCase();
    const { bookingId } = req.params;

    let booking;
    if (getIsConnected()) {
      booking = await Booking.findById(bookingId);
    } else {
      booking = localBookings.get(bookingId);
    }

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found.', code: 'BOOKING_NOT_FOUND' });
    }

    // Validate transition
    const isValid = Booking.isValidTransition
      ? Booking.isValidTransition(booking.status, newStatus)
      : true; // fallback for local store

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from '${booking.status}' to '${newStatus}'.`,
        code: 'INVALID_BOOKING_STATUS',
      });
    }

    // Apply timestamp for each status
    const statusTimestamps = {
      worker_on_the_way: { workerOnTheWayAt: new Date() },
      arrived: { arrivedAt: new Date() },
      service_started: { startedAt: new Date() },
      service_completed: { completedAt: new Date() },
      paid: { paidAt: new Date() },
    };

    const updates = { status: newStatus, ...statusTimestamps[newStatus] };

    if (getIsConnected()) {
      await Booking.findByIdAndUpdate(bookingId, updates);
    } else {
      Object.assign(booking, updates);
      localBookings.set(bookingId, booking);
    }

    return res.json({ success: true, message: `Status updated to ${newStatus}.`, data: { status: newStatus } });
  } catch (error) {
    next(error);
  }
}

// ─── Cancel Booking ───────────────────────────────────────────────────────────

/**
 * POST /api/v1/bookings/:bookingId/cancel
 */
async function cancelBooking(req, res, next) {
  try {
    const { userId, role } = req.user;
    const reason = String(req.body?.reason || '').trim();
    const { bookingId } = req.params;

    const cancelStatus = role === 'worker' ? 'cancelled_by_worker' : 'cancelled_by_customer';

    // Only allow cancellation of requested or accepted bookings
    const cancellableStatuses = ['requested', 'accepted'];

    let booking;
    if (getIsConnected()) {
      booking = await Booking.findOneAndUpdate(
        { _id: bookingId, status: { $in: cancellableStatuses } },
        { status: cancelStatus, cancellationReason: reason, cancelledAt: new Date() },
        { new: true }
      );
    } else {
      booking = localBookings.get(bookingId);
      if (booking && cancellableStatuses.includes(booking.status)) {
        booking.status = cancelStatus;
        booking.cancellationReason = reason;
        booking.cancelledAt = new Date();
        localBookings.set(bookingId, booking);
      } else {
        booking = null;
      }
    }

    if (!booking) {
      return res.status(400).json({
        success: false,
        message: 'Booking cannot be cancelled at this stage.',
        code: 'INVALID_BOOKING_STATUS',
      });
    }

    return res.json({ success: true, message: 'Booking cancelled.', data: { status: cancelStatus } });
  } catch (error) {
    next(error);
  }
}

// ─── Update Worker Location During Active Booking ─────────────────────────────

/**
 * POST /api/v1/bookings/:bookingId/location
 */
async function updateWorkerLocation(req, res, next) {
  try {
    const { latitude, longitude } = req.body;
    const { bookingId } = req.params;

    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'latitude and longitude are required.' });
    }

    const workerLocation = { type: 'Point', coordinates: [parseFloat(longitude), parseFloat(latitude)] };

    if (getIsConnected()) {
      await Booking.findByIdAndUpdate(bookingId, { workerLocation });
    } else {
      const booking = localBookings.get(bookingId);
      if (booking) { booking.workerLocation = workerLocation; localBookings.set(bookingId, booking); }
    }

    return res.json({ success: true, message: 'Location updated.' });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createBooking,
  getBooking,
  getMyBookings,
  acceptBooking,
  rejectBooking,
  updateBookingStatus,
  cancelBooking,
  updateWorkerLocation,
};
