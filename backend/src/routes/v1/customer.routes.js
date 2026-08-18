const express = require('express');
const router = express.Router();
const {
  getMyProfile,
  updateMyProfile,
  getMyAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
} = require('../../controllers/customer.controller');
const { authenticate, requireRole } = require('../../middleware/auth');

// All customer routes require auth + customer role
router.use(authenticate, requireRole('customer'));

// Profile
router.get('/me', getMyProfile);
router.patch('/me', updateMyProfile);

// Addresses
router.get('/me/addresses', getMyAddresses);
router.post('/me/addresses', addAddress);
router.patch('/me/addresses/:addressId', updateAddress);
router.delete('/me/addresses/:addressId', deleteAddress);

module.exports = router;
