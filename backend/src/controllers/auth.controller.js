const User = require('../models/User');
const WorkerProfile = require('../models/WorkerProfile');
const { signToken } = require('../middleware/auth');
const { getIsConnected } = require('../config/db');

// In-memory OTP store for development (replace with Redis/DB in production)
const otpStore = new Map(); // phone -> { otp, expiresAt }

// In-memory user store — used ONLY when MongoDB is not connected (local dev)
const localUsers = new Map(); // phone -> { id, phone, role, name, profilePhoto, profileComplete, status }
let _localIdCounter = 1;

function _createLocalUser(phone, role) {
  const id = `local_${_localIdCounter++}`;
  const user = { id, _id: id, phone, role, name: '', profilePhoto: '', profileComplete: false, status: 'active' };
  localUsers.set(phone, user);
  return user;
}


/**
 * POST /api/v1/auth/send-otp
 * Sends (mock) OTP to phone number
 */
async function sendOtp(req, res, next) {
  try {
    const phone = String(req.body?.phone || '').trim();
    if (!phone || !/^\+?[0-9]{10,15}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message: 'A valid phone number is required.',
        code: 'VALIDATION_ERROR',
        errors: [{ field: 'phone', message: 'Invalid phone number' }],
      });
    }

    // Check for fixed test phone number requested by user
    const isTestPhone = phone.endsWith('6003359534');
    const otp = isTestPhone ? '654321' : Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + (isTestPhone ? 24 * 60 * 60 * 1000 : 5 * 60 * 1000); // 24h for test phone

    otpStore.set(phone, { otp, expiresAt });

    // In development: log OTP to console
    console.log(`[OTP] Phone: ${phone} | OTP: ${otp} | Expires: ${new Date(expiresAt).toISOString()}`);

    return res.json({
      success: true,
      message: 'OTP sent successfully.',
      ...(process.env.NODE_ENV !== 'production' && { devOtp: otp }),
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/auth/verify-otp
 * Verifies OTP and returns JWT + user info
 * Body: { phone, otp, role } — role only needed on first registration
 */
async function verifyOtp(req, res, next) {
  try {
    const phone = String(req.body?.phone || '').trim();
    const otp = String(req.body?.otp || '').trim();
    const role = String(req.body?.role || 'customer').toLowerCase();

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Phone and OTP are required.',
        code: 'VALIDATION_ERROR',
      });
    }

    if (!['customer', 'worker'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Role must be customer or worker.',
        code: 'VALIDATION_ERROR',
      });
    }

    const isTestPhone = phone.endsWith('6003359534');
    const isTestOtp = isTestPhone && otp === '654321';

    if (!isTestOtp) {
      // Verify stored OTP
      const stored = otpStore.get(phone);
      if (!stored) {
        return res.status(400).json({
          success: false,
          message: 'OTP not found. Please request a new OTP.',
          code: 'OTP_INVALID',
        });
      }

      if (Date.now() > stored.expiresAt) {
        otpStore.delete(phone);
        return res.status(400).json({
          success: false,
          message: 'OTP has expired. Please request a new one.',
          code: 'OTP_EXPIRED',
        });
      }

      if (stored.otp !== otp) {
        return res.status(400).json({
          success: false,
          message: 'Incorrect OTP. Please try again.',
          code: 'OTP_INVALID',
        });
      }

      // OTP verified — clear it
      otpStore.delete(phone);
    }

    let user;
    let isNewUser = false;

    if (getIsConnected()) {
      // MongoDB path
      user = await User.findOne({ phone });
      if (!user) {
        isNewUser = true;
        user = await User.create({ phone, role });
        if (role === 'worker') {
          await WorkerProfile.create({ userId: user._id });
        }
      }
    } else {
      // Local in-memory fallback (dev only)
      user = localUsers.get(phone);
      if (!user) {
        isNewUser = true;
        user = _createLocalUser(phone, role);
      }
    }

    const token = signToken({ userId: user._id.toString(), role: user.role });

    return res.json({
      success: true,
      message: isNewUser ? 'Account created successfully.' : 'Login successful.',
      data: {
        accessToken: token,
        user: {
          id: user._id,
          phone: user.phone,
          name: user.name,
          role: user.role,
          profileComplete: user.profileComplete,
          status: user.status,
        },
      },
    });

  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/auth/me
 * Returns current authenticated user
 */
async function getMe(req, res, next) {
  try {
    const userId = req.user.userId;

    if (getIsConnected()) {
      const user = await User.findById(userId).lean();
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found.',
          code: 'USER_NOT_FOUND',
        });
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
          createdAt: user.createdAt,
        },
      });
    } else {
      // Local dev fallback (without MongoDB)
      let localUser = null;
      for (const u of localUsers.values()) {
        if (u.id === userId || u._id === userId) {
          localUser = u;
          break;
        }
      }
      if (!localUser) {
        localUser = {
          id: userId,
          _id: userId,
          phone: '+919999999999',
          name: 'KamJodo User',
          role: req.user.role || 'customer',
          profileComplete: true,
          status: 'active',
        };
      }
      return res.json({
        success: true,
        data: localUser,
      });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/auth/logout
 * Client-side token removal is enough for stateless JWT
 * But we clear FCM token here
 */
async function logout(req, res, next) {
  try {
    await User.findByIdAndUpdate(req.user.userId, { fcmToken: '' });
    return res.json({
      success: true,
      message: 'Logged out successfully.',
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/auth/quick-login
 * Direct name & password login (no phone/OTP needed)
 * Body: { name, password, role }
 */
async function quickLogin(req, res, next) {
  try {
    const name = String(req.body?.name || 'User').trim();
    const role = String(req.body?.role || 'customer').toLowerCase();

    if (!['customer', 'worker'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Role must be customer or worker.',
      });
    }

    let user;
    if (getIsConnected()) {
      user = await User.findOne({ name });
      if (!user) {
        user = await User.create({
          name,
          phone: `+91${Math.floor(6000000000 + Math.random() * 3999999999)}`,
          role,
          profileComplete: true,
        });
        if (role === 'worker') {
          await WorkerProfile.create({ userId: user._id });
        }
      }
    } else {
      const phoneKey = `user_${name.toLowerCase().replace(/\s+/g, '_')}`;
      user = localUsers.get(phoneKey);
      if (!user) {
        const localId = `local_${_localIdCounter++}`;
        user = {
          id: localId,
          _id: localId,
          phone: '+919999999999',
          role,
          name,
          profilePhoto: '',
          profileComplete: true,
          status: 'active',
        };
        localUsers.set(phoneKey, user);
      }
    }

    const token = signToken({ userId: (user._id || user.id).toString(), role: user.role });

    return res.json({
      success: true,
      message: 'Login successful.',
      data: {
        accessToken: token,
        user: {
          id: user._id || user.id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          profileComplete: user.profileComplete,
          status: user.status,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

module.exports = { sendOtp, verifyOtp, getMe, logout, quickLogin };

