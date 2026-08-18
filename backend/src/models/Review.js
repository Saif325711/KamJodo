const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    bookingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
      required: true,
    },
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
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      trim: true,
      default: '',
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// One review per booking — prevents duplicates
reviewSchema.index({ bookingId: 1 }, { unique: true });
reviewSchema.index({ workerId: 1 });
reviewSchema.index({ customerId: 1 });

module.exports = mongoose.model('Review', reviewSchema);
