const Review = require('../models/Review');
const Booking = require('../models/Booking');
const WorkerProfile = require('../models/WorkerProfile');
const { getIsConnected } = require('../config/db');

// Local fallback store
const localReviews = new Map();
let _reviewCounter = 1;

/**
 * POST /api/v1/bookings/:bookingId/review
 * Customer submits a review after a completed booking
 */
async function createReview(req, res, next) {
  try {
    const { bookingId } = req.params;
    const customerId = req.user.userId;
    const rating = parseInt(req.body?.rating);
    const comment = String(req.body?.comment || '').trim();

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5.',
        code: 'VALIDATION_ERROR',
      });
    }

    if (getIsConnected()) {
      // Verify booking exists and is completed
      const booking = await Booking.findById(bookingId).lean();
      if (!booking) {
        return res.status(404).json({ success: false, message: 'Booking not found.', code: 'BOOKING_NOT_FOUND' });
      }
      if (booking.customerId?.toString() !== customerId) {
        return res.status(403).json({ success: false, message: 'Not authorized to review this booking.', code: 'REVIEW_NOT_ALLOWED' });
      }
      if (!['service_completed', 'payment_pending', 'paid', 'rated'].includes(booking.status)) {
        return res.status(400).json({ success: false, message: 'Can only review completed bookings.', code: 'REVIEW_NOT_ALLOWED' });
      }

      // Check if review already exists (unique index enforces this too)
      const existing = await Review.findOne({ bookingId });
      if (existing) {
        return res.status(409).json({ success: false, message: 'Review already submitted.', code: 'REVIEW_ALREADY_EXISTS' });
      }

      const review = await Review.create({
        bookingId,
        customerId,
        workerId: booking.workerId,
        rating,
        comment,
      });

      // Update worker's rating average
      await _recalculateWorkerRating(booking.workerId.toString());

      // Update booking status to rated
      await Booking.findByIdAndUpdate(bookingId, { status: 'rated' });

      return res.status(201).json({ success: true, message: 'Review submitted.', data: review });
    } else {
      // Local fallback
      const reviewId = `review_${_reviewCounter++}`;
      const review = { id: reviewId, bookingId, customerId, rating, comment, createdAt: new Date() };
      localReviews.set(reviewId, review);
      return res.status(201).json({ success: true, message: 'Review submitted (local dev).', data: review });
    }
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'Review already submitted.', code: 'REVIEW_ALREADY_EXISTS' });
    }
    next(error);
  }
}

/**
 * GET /api/v1/workers/:workerId/reviews
 */
async function getWorkerReviews(req, res, next) {
  try {
    const { workerId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    if (!getIsConnected()) {
      return res.json({ success: true, data: { reviews: [], pagination: { total: 0, page, limit } } });
    }

    const skip = (page - 1) * limit;
    const [reviews, total] = await Promise.all([
      Review.find({ workerId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('customerId', 'name profilePhoto')
        .lean(),
      Review.countDocuments({ workerId }),
    ]);

    return res.json({
      success: true,
      data: {
        reviews: reviews.map((r) => ({
          id: r._id,
          rating: r.rating,
          comment: r.comment,
          customer: r.customerId
            ? { name: r.customerId.name, profilePhoto: r.customerId.profilePhoto }
            : { name: 'Anonymous' },
          createdAt: r.createdAt,
        })),
        pagination: { page, limit, total, pages: Math.ceil(total / limit) },
      },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Helper: Recalculate worker rating average ────────────────────────────────
async function _recalculateWorkerRating(workerId) {
  try {
    const result = await Review.aggregate([
      { $match: { workerId: require('mongoose').Types.ObjectId.createFromHexString(workerId) } },
      { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } },
    ]);

    if (result.length > 0) {
      await WorkerProfile.findByIdAndUpdate(workerId, {
        ratingAverage: Math.round(result[0].avg * 10) / 10,
        ratingCount: result[0].count,
      });
    }
  } catch (_) {}
}

module.exports = { createReview, getWorkerReviews };
