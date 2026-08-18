const User = require('../models/User');
const Address = require('../models/Address');

/**
 * GET /api/v1/customers/me
 */
async function getMyProfile(req, res, next) {
  try {
    const user = await User.findById(req.user.userId).lean();
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.', code: 'USER_NOT_FOUND' });
    }
    return res.json({
      success: true,
      data: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        profilePhoto: user.profilePhoto,
        role: user.role,
        status: user.status,
        profileComplete: user.profileComplete,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/customers/me
 * Allowed: name, email, profilePhoto
 * NOT allowed: role, status, isAdmin, verificationStatus
 */
async function updateMyProfile(req, res, next) {
  try {
    const allowedFields = ['name', 'email', 'profilePhoto'];
    const updates = {};

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates[field] = String(req.body[field]).trim();
      }
    }

    // Mark profile complete if name is set
    if (updates.name && updates.name.length > 0) {
      updates.profileComplete = true;
    }

    const user = await User.findByIdAndUpdate(req.user.userId, updates, { new: true, lean: true });
    return res.json({
      success: true,
      message: 'Profile updated.',
      data: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        email: user.email,
        profilePhoto: user.profilePhoto,
        profileComplete: user.profileComplete,
      },
    });
  } catch (error) {
    next(error);
  }
}

// ─── Addresses ───────────────────────────────────────────────────────────────

/**
 * GET /api/v1/customers/me/addresses
 */
async function getMyAddresses(req, res, next) {
  try {
    const addresses = await Address.find({ userId: req.user.userId }).lean();
    return res.json({ success: true, data: addresses });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/customers/me/addresses
 */
async function addAddress(req, res, next) {
  try {
    const { label, addressLine, city, state, postalCode, location } = req.body;

    if (!addressLine) {
      return res.status(400).json({
        success: false,
        message: 'addressLine is required.',
        code: 'VALIDATION_ERROR',
      });
    }

    const address = await Address.create({
      userId: req.user.userId,
      label: label || 'Home',
      addressLine,
      city: city || '',
      state: state || '',
      postalCode: postalCode || '',
      location: location || null,
    });

    return res.status(201).json({ success: true, message: 'Address added.', data: address });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/customers/me/addresses/:addressId
 */
async function updateAddress(req, res, next) {
  try {
    const address = await Address.findOne({ _id: req.params.addressId, userId: req.user.userId });
    if (!address) {
      return res.status(404).json({ success: false, message: 'Address not found.', code: 'NOT_FOUND' });
    }

    const allowedFields = ['label', 'addressLine', 'city', 'state', 'postalCode', 'location', 'isDefault'];
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) address[field] = req.body[field];
    }

    await address.save();
    return res.json({ success: true, message: 'Address updated.', data: address });
  } catch (error) {
    next(error);
  }
}

/**
 * DELETE /api/v1/customers/me/addresses/:addressId
 */
async function deleteAddress(req, res, next) {
  try {
    const result = await Address.findOneAndDelete({ _id: req.params.addressId, userId: req.user.userId });
    if (!result) {
      return res.status(404).json({ success: false, message: 'Address not found.', code: 'NOT_FOUND' });
    }
    return res.json({ success: true, message: 'Address deleted.' });
  } catch (error) {
    next(error);
  }
}

module.exports = { getMyProfile, updateMyProfile, getMyAddresses, addAddress, updateAddress, deleteAddress };
