const User = require('../models/User');
const WorkerProfile = require('../models/WorkerProfile');
const Follow = require('../models/Follow');
const { getIsConnected } = require('../config/db');

// In-memory worker profile store (dev without MongoDB)
const localWorkerProfiles = new Map(); // userId -> profile

function _getOrCreateLocalProfile(userId, name) {
  if (localWorkerProfiles.has(userId)) return localWorkerProfiles.get(userId);
  const profile = {
    _id: `profile_${userId}`,
    userId,
    name: name || 'Worker',
    isOnline: false,
    isAvailable: true,
    ratingAverage: 0,
    ratingCount: 0,
    completedJobs: 0,
    followersCount: 0,
    verificationStatus: 'pending',
    skills: [],
    categoryIds: [],
    about: '',
    profileComplete: false,
  };
  localWorkerProfiles.set(userId, profile);
  return profile;
}

/**
 * POST /api/v1/workers/onboarding   OR   PATCH /api/v1/workers/me
 * Create or update worker profile
 */
async function updateMyWorkerProfile(req, res, next) {
  try {
    const userId = req.user.userId;
    const allowedFields = [
      'about', 'primaryCategoryId', 'categoryIds', 'experienceYears',
      'skills', 'startingPrice', 'serviceRadiusKm', 'location',
      'availableDays', 'availableFrom', 'availableTo',
    ];

    const updates = {};
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    }

    // Update User name/photo if provided
    const userUpdates = {};
    if (req.body.fullName) userUpdates.name = String(req.body.fullName).trim();
    if (req.body.profilePhoto) userUpdates.profilePhoto = String(req.body.profilePhoto).trim();
    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(userId, userUpdates);
    }

    // Check if profile looks complete
    const existing = await WorkerProfile.findOne({ userId });
    const merged = { ...(existing?.toObject() || {}), ...updates };

    const isComplete = !!(
      merged.primaryCategoryId &&
      merged.experienceYears >= 0 &&
      merged.skills?.length > 0
    );
    updates.profileComplete = isComplete;

    const profile = await WorkerProfile.findOneAndUpdate(
      { userId },
      { $set: updates },
      { new: true, upsert: true, lean: true }
    );

    if (isComplete) {
      await User.findByIdAndUpdate(userId, { profileComplete: true });
    }

    return res.json({
      success: true,
      message: 'Worker profile updated.',
      data: profile,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/workers/me
 * Get own worker profile
 */
async function getMyWorkerProfile(req, res, next) {
  try {
    const userId = req.user.userId;

    if (getIsConnected()) {
      const profile = await WorkerProfile.findOne({ userId })
        .populate('primaryCategoryId', 'name iconKey')
        .populate('categoryIds', 'name iconKey')
        .lean();

      if (!profile) {
        // Auto-create profile if missing (e.g. old accounts)
        const newProfile = await WorkerProfile.create({ userId });
        const user = await User.findById(userId).lean();
        return res.json({
          success: true,
          data: { ...newProfile.toObject(), name: user?.name, profilePhoto: user?.profilePhoto, phone: user?.phone },
        });
      }

      const user = await User.findById(userId).lean();
      return res.json({
        success: true,
        data: { ...profile, name: user?.name, profilePhoto: user?.profilePhoto, phone: user?.phone },
      });
    } else {
      // Local dev fallback
      const profile = _getOrCreateLocalProfile(userId);
      return res.json({ success: true, data: profile });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/workers/:workerId
 * Public worker profile — does NOT expose PAN or documents
 */
async function getWorkerProfile(req, res, next) {
  try {
    const profile = await WorkerProfile.findById(req.params.workerId)
      .populate('primaryCategoryId', 'name iconKey')
      .populate('categoryIds', 'name iconKey')
      .lean();

    if (!profile) {
      return res.status(404).json({ success: false, message: 'Worker not found.', code: 'WORKER_NOT_FOUND' });
    }

    const user = await User.findById(profile.userId).lean();

    return res.json({
      success: true,
      data: {
        id: profile._id,
        name: user?.name || '',
        profilePhoto: user?.profilePhoto || '',
        category: profile.primaryCategoryId,
        categories: profile.categoryIds,
        skills: profile.skills,
        experienceYears: profile.experienceYears,
        ratingAverage: profile.ratingAverage,
        ratingCount: profile.ratingCount,
        completedJobs: profile.completedJobs,
        serviceRadiusKm: profile.serviceRadiusKm,
        startingPrice: profile.startingPrice,
        followersCount: profile.followersCount,
        verificationStatus: profile.verificationStatus,
        identityVerified: profile.identityStatus === 'verified',
        panVerified: profile.panStatus === 'verified',
        isOnline: profile.isOnline,
        isAvailable: profile.isAvailable,
        about: profile.about,
        // Never expose: panStatus raw, identity docs, location history
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/workers
 * Search workers — supports category, geospatial nearby, rating, availability filters
 */
async function searchWorkers(req, res, next) {
  try {
    const {
      categoryId,
      latitude,
      longitude,
      radiusKm = 20,
      minRating,
      availableNow,
      verifiedOnly,
      search,
      page = 1,
      limit = 20,
    } = req.query;

    const filter = { profileComplete: true };

    if (categoryId) {
      filter.$or = [
        { primaryCategoryId: categoryId },
        { categoryIds: categoryId },
      ];
    }

    if (minRating) {
      filter.ratingAverage = { $gte: parseFloat(minRating) };
    }

    if (availableNow === 'true') {
      filter.isOnline = true;
      filter.isAvailable = true;
    }

    if (verifiedOnly === 'true') {
      filter.verificationStatus = 'verified';
    }

    // Geospatial query — nearby workers
    if (latitude && longitude) {
      filter.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)],
          },
          $maxDistance: parseFloat(radiusKm) * 1000, // meters
        },
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const workers = await WorkerProfile.find(filter)
      .populate('primaryCategoryId', 'name iconKey')
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await WorkerProfile.countDocuments(filter);

    // Enrich with user name/photo
    const workerIds = workers.map((w) => w.userId);
    const users = await User.find({ _id: { $in: workerIds } }).lean();
    const userMap = Object.fromEntries(users.map((u) => [u._id.toString(), u]));

    const results = workers.map((w) => {
      const user = userMap[w.userId?.toString()] || {};
      return {
        id: w._id,
        name: user.name || '',
        profilePhoto: user.profilePhoto || '',
        category: w.primaryCategoryId,
        skills: w.skills,
        ratingAverage: w.ratingAverage,
        ratingCount: w.ratingCount,
        completedJobs: w.completedJobs,
        startingPrice: w.startingPrice,
        serviceRadiusKm: w.serviceRadiusKm,
        isOnline: w.isOnline,
        isAvailable: w.isAvailable,
        verificationStatus: w.verificationStatus,
        identityVerified: w.identityStatus === 'verified',
      };
    });

    return res.json({
      success: true,
      data: {
        workers: results,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/workers/me/availability
 */
async function setAvailability(req, res, next) {
  try {
    const userId = req.user.userId;
    const { isOnline, isAvailable } = req.body;
    const updates = {};
    if (isOnline !== undefined) updates.isOnline = Boolean(isOnline);
    if (isAvailable !== undefined) updates.isAvailable = Boolean(isAvailable);

    if (getIsConnected()) {
      await WorkerProfile.findOneAndUpdate({ userId }, updates);
    } else {
      // Local dev fallback
      const profile = _getOrCreateLocalProfile(userId);
      Object.assign(profile, updates);
      localWorkerProfiles.set(userId, profile);
    }

    return res.json({
      success: true,
      message: `Worker is now ${updates.isOnline ? 'online' : 'offline'}.`,
      data: updates,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/workers/:workerId/follow
 */
async function followWorker(req, res, next) {
  try {
    const workerId = req.params.workerId;
    const customerId = req.user.userId;

    const existing = await Follow.findOne({ customerId, workerId });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Already following.', code: 'ALREADY_FOLLOWING' });
    }

    await Follow.create({ customerId, workerId });
    await WorkerProfile.findByIdAndUpdate(workerId, { $inc: { followersCount: 1 } });

    return res.status(201).json({ success: true, message: 'Following worker.' });
  } catch (error) {
    next(error);
  }
}

/**
 * DELETE /api/v1/workers/:workerId/follow
 */
async function unfollowWorker(req, res, next) {
  try {
    const workerId = req.params.workerId;
    const customerId = req.user.userId;

    const result = await Follow.findOneAndDelete({ customerId, workerId });
    if (!result) {
      return res.status(404).json({ success: false, message: 'Not following.', code: 'NOT_FOLLOWING' });
    }

    await WorkerProfile.findByIdAndUpdate(workerId, { $inc: { followersCount: -1 } });
    return res.json({ success: true, message: 'Unfollowed worker.' });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/workers/:workerId/follow-status
 */
async function getFollowStatus(req, res, next) {
  try {
    const follow = await Follow.findOne({ customerId: req.user.userId, workerId: req.params.workerId });
    return res.json({ success: true, data: { isFollowing: !!follow } });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  updateMyWorkerProfile,
  getMyWorkerProfile,
  getWorkerProfile,
  searchWorkers,
  setAvailability,
  followWorker,
  unfollowWorker,
  getFollowStatus,
};
