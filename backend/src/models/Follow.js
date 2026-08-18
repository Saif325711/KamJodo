const mongoose = require('mongoose');

const followSchema = new mongoose.Schema(
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
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate follows
followSchema.index({ customerId: 1, workerId: 1 }, { unique: true });

module.exports = mongoose.model('Follow', followSchema);
