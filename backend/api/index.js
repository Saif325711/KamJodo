const app = require('../src/app');
const { connectDB } = require('../src/config/db');

let dbInitialized = false;

module.exports = async (req, res) => {
  if (!dbInitialized) {
    try {
      await connectDB();
    } catch (_) {}
    dbInitialized = true;
  }
  return app(req, res);
};
