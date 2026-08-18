const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

const JWT_SECRET = process.env.JWT_SECRET || 'kamjodo_dev_secret_change_in_production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '30d';

/**
 * Sign a JWT token for a user
 * @param {Object} payload - { userId, role }
 * @returns {string} JWT token
 */
function signToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

/**
 * Returns true if the string is a valid 24-char hex MongoDB ObjectId
 */
function isValidObjectId(id) {
  return typeof id === 'string' && mongoose.Types.ObjectId.isValid(id) && /^[a-fA-F0-9]{24}$/.test(id);
}

/**
 * Middleware: Verify JWT token from Authorization header
 * Attaches req.user = { userId, role } on success
 * Rejects tokens with invalid/local dev userIds (e.g. "local_5") when MongoDB is connected
 */
function authenticate(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required.',
      code: 'AUTH_REQUIRED',
    });
  }

  const token = authHeader.slice(7);

  // Skip validation for the offline dev fallback token — the controllers handle this
  if (token === 'dev_local_token_success' || token === 'cap_dev_local_token') {
    req.user = { userId: 'local_dev_offline', role: 'worker', isLocal: true };
    return next();
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const userId = decoded.userId;

    // If userId is a local dev string (not a valid ObjectId) but MongoDB IS connected,
    // force the client to re-authenticate with a real token
    const { getIsConnected } = require('../config/db');
    if (!isValidObjectId(userId) && getIsConnected()) {
      return res.status(401).json({
        success: false,
        message: 'Session expired. Please log in again.',
        code: 'SESSION_EXPIRED',
      });
    }

    req.user = { userId, role: decoded.role, isLocal: !isValidObjectId(userId) };
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token.',
      code: 'INVALID_TOKEN',
    });
  }
}

/**
 * Middleware factory: restrict to specific roles
 * Usage: requireRole('worker') or requireRole('admin')
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.',
        code: 'AUTH_REQUIRED',
      });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'You are not allowed to perform this action.',
        code: 'FORBIDDEN',
      });
    }
    next();
  };
}

module.exports = { signToken, authenticate, requireRole, isValidObjectId };
