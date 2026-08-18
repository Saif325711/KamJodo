const mongoose = require('mongoose');

const workerPostSchema = new mongoose.Schema(
  {
    workerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'WorkerProfile',
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    description: {
      type: String,
      trim: true,
      default: '',
      maxlength: 1000,
    },
    images: {
      type: [String],
      default: [],
    },
    startingPrice: {
      type: Number,
      default: 0,
      min: 0,
    },
    serviceRadiusKm: {
      type: Number,
      default: 10,
      min: 1,
    },
    status: {
      type: String,
      enum: ['active', 'paused', 'expired', 'rejected', 'deleted'],
      default: 'active',
    },
    viewCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

workerPostSchema.index({ workerId: 1, status: 1 });
workerPostSchema.index({ categoryId: 1, status: 1 });

module.exports = mongoose.model('WorkerPost', workerPostSchema);
