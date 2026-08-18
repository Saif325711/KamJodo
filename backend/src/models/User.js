const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    name: {
      type: String,
      trim: true,
      default: '',
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      default: '',
    },
    profilePhoto: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      enum: ['customer', 'worker', 'admin'],
      required: true,
    },
    status: {
      type: String,
      enum: ['active', 'suspended', 'pending'],
      default: 'active',
    },
    fcmToken: {
      type: String,
      default: '',
    },
    profileComplete: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);
