const mongoose = require('mongoose');

const themeSchema = new mongoose.Schema(
  {
    appTitle: {
      type: String,
      default: 'KamJodo',
      trim: true,
    },
    primary: {
      type: String,
      default: '#7A0000',
      trim: true,
    },
    secondary: {
      type: String,
      default: '#B31217',
      trim: true,
    },
    tertiary: {
      type: String,
      default: '#FF5F6D',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Theme', themeSchema);
