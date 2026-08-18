const express = require('express');
const router = express.Router();
const { sendOtp, verifyOtp, getMe, logout, quickLogin } = require('../../controllers/auth.controller');
const { authenticate } = require('../../middleware/auth');

// POST /api/v1/auth/quick-login (Name & Password login)
router.post('/quick-login', quickLogin);

// POST /api/v1/auth/send-otp
router.post('/send-otp', sendOtp);

// POST /api/v1/auth/verify-otp
router.post('/verify-otp', verifyOtp);

// GET /api/v1/auth/me  (protected)
router.get('/me', authenticate, getMe);

// POST /api/v1/auth/logout  (protected)
router.post('/logout', authenticate, logout);

module.exports = router;

