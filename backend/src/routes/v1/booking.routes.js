const express = require('express');
const router = express.Router();
const {
  createBooking,
  getBooking,
  getMyBookings,
  acceptBooking,
  rejectBooking,
  updateBookingStatus,
  cancelBooking,
  updateWorkerLocation,
} = require('../../controllers/booking.controller');
const { createReview, getWorkerReviews } = require('../../controllers/review.controller');
const { authenticate, requireRole } = require('../../middleware/auth');

// All booking routes require auth
router.use(authenticate);

// GET /api/v1/bookings/me
router.get('/me', getMyBookings);

// POST /api/v1/bookings  (customer only)
router.post('/', requireRole('customer'), createBooking);

// GET /api/v1/bookings/:bookingId
router.get('/:bookingId', getBooking);

// Worker actions
router.post('/:bookingId/accept', requireRole('worker'), acceptBooking);
router.post('/:bookingId/reject', requireRole('worker'), rejectBooking);

// Status update (worker-driven)
router.patch('/:bookingId/status', requireRole('worker'), updateBookingStatus);

// Cancel (customer or worker)
router.post('/:bookingId/cancel', cancelBooking);

// Worker location update during active booking
router.post('/:bookingId/location', requireRole('worker'), updateWorkerLocation);

// Reviews
router.post('/:bookingId/review', requireRole('customer'), createReview);

module.exports = router;
