const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    default: 'Point',
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    default: [0, 0],
  },
});

const addressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    label: {
      type: String,
      trim: true,
      default: 'Home',
    },
    addressLine: {
      type: String,
      trim: true,
      required: true,
    },
    city: {
      type: String,
      trim: true,
      default: '',
    },
    state: {
      type: String,
      trim: true,
      default: '',
    },
    postalCode: {
      type: String,
      trim: true,
      default: '',
    },
    location: {
      type: pointSchema,
      default: null,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

addressSchema.index({ userId: 1 });

module.exports = mongoose.model('Address', addressSchema);
