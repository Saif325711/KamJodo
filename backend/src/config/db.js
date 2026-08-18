const mongoose = require('mongoose');

let isConnected = false;

async function connectDB() {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    console.log('[Database] MONGODB_URI is not set. Operating with local store fallback.');
    return false;
  }

  if (isConnected) {
    return true;
  }

  try {
    const conn = await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000,
    });

    isConnected = true;
    console.log(`[Database] MongoDB Connected: ${conn.connection.host}/${conn.connection.name}`);

    mongoose.connection.on('error', (err) => {
      console.error('[Database] MongoDB connection error:', err.message);
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('[Database] MongoDB connection lost.');
      isConnected = false;
    });

    return true;
  } catch (error) {
    console.error('[Database] Failed to connect to MongoDB:', error.message);
    return false;
  }
}

function getIsConnected() {
  return isConnected && mongoose.connection.readyState === 1;
}

module.exports = {
  connectDB,
  getIsConnected,
};
