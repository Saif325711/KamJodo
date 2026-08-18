const express = require('express');
const router = express.Router();

// Mount all v1 route modules
router.use('/auth', require('./auth.routes'));
router.use('/customers', require('./customer.routes'));
router.use('/workers', require('./worker.routes'));
router.use('/categories', require('./category.routes'));
router.use('/worker-posts', require('./workerPost.routes'));
router.use('/bookings', require('./booking.routes'));

// API v1 health check
router.get('/health', (_req, res) => {
  res.json({ success: true, message: 'KamJodo API v1 is running', version: '1.0' });
});

module.exports = router;

