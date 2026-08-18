const app = require('./src/app');
const { connectDB } = require('./src/config/db');

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '::';

async function startServer() {
  // Connect to MongoDB Atlas (if MONGODB_URI is provided in environment)
  await connectDB();

  const server = app.listen(PORT, HOST, () => {
    console.log(`KamJodo API server running at http://${HOST}:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });

  // Graceful shutdown handling
  const shutdown = (signal) => {
    console.log(`\nReceived ${signal}. Gracefully shutting down KamJodo server...`);
    server.close(() => {
      console.log('HTTP server closed.');
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

startServer();
