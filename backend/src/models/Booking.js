const mongoose = require('mongoose');

// Valid booking statuses and allowed transitions
const BOOKING_STATUSES = [
  'requested',
  'accepted',
  'worker_on_the_way',
  'arrived',
  'service_started',
  'service_completed',
  'payment_pending',
  'paid',
  'rated',
  'rejected',
  'cancelled_by_customer',
  'cancelled_by_worker',
  'expired',
  'disputed',
];

// Legal forward transitions — backend enforces these
const VALID_TRANSITIONS = {
  requested: ['accepted', 'rejected', 'cancelled_by_customer', 'expired'],
  accepted: ['worker_on_the_way', 'cancelled_by_customer', 'cancelled_by_worker'],
  worker_on_the_way: ['arrived', 'cancelled_by_worker'],
  arrived: ['service_started'],
  service_started: ['service_completed'],
  service_completed: ['payment_pending'],
  payment_pending: ['paid'],
  paid: ['rated'],
};

const pointSchema = new mongoose.Schema({
  type: { type: String, enum: ['Point'], default: 'Point' },
  coordinates: { type: [Number], default: [0, 0] },
});

const bookingSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'WorkerProfile',
      required: true,
    },
    workerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      default: null,
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'WorkerPost',
      default: null,
    },
    status: {
      type: String,
      enum: BOOKING_STATUSES,
      default: 'requested',
    },
    scheduledAt: {
      type: Date,
      default: null,
    },
    description: {
      type: String,
      trim: true,
      default: '',
      maxlength: 500,
    },
    notes: {
      type: String,
      trim: true,
      default: '',
    },
    // Customer location at time of booking
    customerLocation: {
      type: pointSchema,
      default: null,
    },
    customerAddress: {
      addressLine: { type: String, default: '' },
      city: { type: String, default: '' },
      state: { type: String, default: '' },
    },
    // Worker live location during active booking
    workerLocation: {
      type: pointSchema,
      default: null,
    },
    // Pricing
    estimatedPrice: { type: Number, default: 0 },
    finalPrice: { type: Number, default: 0 },
    // Rejection/cancellation info
    rejectionReason: { type: String, default: '' },
    cancellationReason: { type: String, default: '' },
    // Timestamps for each status
    acceptedAt: { type: Date, default: null },
    workerOnTheWayAt: { type: Date, default: null },
    arrivedAt: { type: Date, default: null },
    startedAt: { type: Date, default: null },
    completedAt: { type: Date, default: null },
    cancelledAt: { type: Date, default: null },
    paidAt: { type: Date, default: null },
  },
  {
    timestamps: true,
  }
);

bookingSchema.index({ customerId: 1, status: 1 });
bookingSchema.index({ workerId: 1, status: 1 });

// Static helper to validate state transitions
bookingSchema.statics.isValidTransition = function (currentStatus, nextStatus) {
  const allowed = VALID_TRANSITIONS[currentStatus];
  return Array.isArray(allowed) && allowed.includes(nextStatus);
};

module.exports = mongoose.model('Booking', bookingSchema);
module.exports.BOOKING_STATUSES = BOOKING_STATUSES;
module.exports.VALID_TRANSITIONS = VALID_TRANSITIONS;
