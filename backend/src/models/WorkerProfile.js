const mongoose = require('mongoose');

// GeoJSON Point schema for location
const pointSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    required: true,
    default: 'Point',
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    required: true,
  },
});

const workerProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    primaryCategoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      default: null,
    },
    categoryIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
      },
    ],
    experienceYears: {
      type: Number,
      default: 0,
      min: 0,
    },
    skills: {
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
    // GeoJSON location for geospatial queries
    location: {
      type: pointSchema,
      default: null,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
    ratingAverage: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },
    ratingCount: {
      type: Number,
      default: 0,
    },
    completedJobs: {
      type: Number,
      default: 0,
    },
    followersCount: {
      type: Number,
      default: 0,
    },
    verificationStatus: {
      type: String,
      enum: ['pending', 'verified', 'rejected', 'not_submitted'],
      default: 'not_submitted',
    },
    identityStatus: {
      type: String,
      enum: ['pending', 'verified', 'rejected', 'not_submitted'],
      default: 'not_submitted',
    },
    panStatus: {
      type: String,
      enum: ['pending', 'verified', 'rejected', 'not_submitted'],
      default: 'not_submitted',
    },
    about: {
      type: String,
      default: '',
      maxlength: 500,
    },
    // Availability schedule
    availableDays: {
      type: [String],
      default: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    },
    availableFrom: {
      type: String,
      default: '09:00',
    },
    availableTo: {
      type: String,
      default: '20:00',
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

// 2dsphere index for nearby-worker geospatial queries
workerProfileSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('WorkerProfile', workerProfileSchema);
