const WorkerPost = require('../models/WorkerPost');
const WorkerProfile = require('../models/WorkerProfile');
const { getIsConnected } = require('../config/db');

// ─── In-Memory Fallback Store (used when MongoDB is not connected) ─────────────
const localPosts = new Map();  // postId -> post object
const localProfiles = new Map(); // userId -> workerProfile object
let _postIdCounter = 1;
let _profileIdCounter = 1;

/**
 * Get or auto-create a local worker profile for a userId (dev fallback)
 */
function _getOrCreateLocalProfile(userId) {
  if (localProfiles.has(userId)) return localProfiles.get(userId);
  const profile = {
    _id: `profile_${_profileIdCounter++}`,
    userId,
    category: 'general',
    isOnline: false,
    rating: 0,
    completedJobs: 0,
    verificationStatus: 'pending',
  };
  localProfiles.set(userId, profile);
  return profile;
}

/**
 * POST /api/v1/worker-posts
 * Worker creates a service post
 */
async function createPost(req, res, next) {
  try {
    const userId = req.user.userId;
    const { title, categoryId, description, startingPrice, serviceRadiusKm, images } = req.body;

    if (!title || String(title).trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Post title is required.', code: 'VALIDATION_ERROR' });
    }

    if (getIsConnected()) {
      // ── MongoDB path ───────────────────────────────────────────────────────────
      const profile = await WorkerProfile.findOne({ userId }).lean();
      if (!profile) {
        return res.status(404).json({ success: false, message: 'Worker profile not found. Please complete your profile first.', code: 'WORKER_NOT_FOUND' });
      }

      const post = await WorkerPost.create({
        workerId: profile._id,
        userId,
        categoryId: categoryId || null,
        title: String(title).trim(),
        description: String(description || '').trim(),
        startingPrice: Number(startingPrice) || 0,
        serviceRadiusKm: Number(serviceRadiusKm) || 10,
        images: Array.isArray(images) ? images : [],
      });

      return res.status(201).json({ success: true, message: 'Post created.', data: post });
    } else {
      // ── Local in-memory path (dev without MongoDB) ─────────────────────────────
      const profile = _getOrCreateLocalProfile(userId);

      const post = {
        _id: `post_${_postIdCounter++}`,
        workerId: profile._id,
        userId,
        categoryId: categoryId || null,
        title: String(title).trim(),
        description: String(description || '').trim(),
        startingPrice: Number(startingPrice) || 0,
        serviceRadiusKm: Number(serviceRadiusKm) || 10,
        images: Array.isArray(images) ? images : [],
        status: 'active',
        viewCount: 0,
        bookingCount: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      localPosts.set(post._id, post);
      return res.status(201).json({ success: true, message: 'Post created.', data: post });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/worker-posts/me/all
 * Get own posts
 */
async function getMyPosts(req, res, next) {
  try {
    const userId = req.user.userId;

    if (getIsConnected()) {
      const profile = await WorkerProfile.findOne({ userId }).lean();
      if (!profile) return res.status(404).json({ success: false, message: 'Worker profile not found.' });

      const posts = await WorkerPost.find({ workerId: profile._id, status: { $ne: 'deleted' } })
        .sort({ createdAt: -1 })
        .populate('categoryId', 'name iconKey')
        .lean();

      return res.json({ success: true, data: posts });
    } else {
      // Local fallback — return posts matching this userId
      const posts = Array.from(localPosts.values())
        .filter(p => p.userId === userId && p.status !== 'deleted')
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      return res.json({ success: true, data: posts });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/worker-posts
 * Public — get all active worker posts for feed
 */
async function getAllPosts(req, res, next) {
  try {
    if (getIsConnected()) {
      const posts = await WorkerPost.find({ status: 'active' })
        .sort({ createdAt: -1 })
        .populate('categoryId', 'name iconKey')
        .lean();
      return res.json({ success: true, data: posts });
    } else {
      const posts = Array.from(localPosts.values())
        .filter(p => p.status === 'active')
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      return res.json({ success: true, data: posts });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/workers/:workerId/posts
 * Public — get active posts for a worker
 */
async function getWorkerPosts(req, res, next) {
  try {
    if (getIsConnected()) {
      const posts = await WorkerPost.find({ workerId: req.params.workerId, status: 'active' })
        .sort({ createdAt: -1 })
        .populate('categoryId', 'name iconKey')
        .lean();
      return res.json({ success: true, data: posts });
    } else {
      const posts = Array.from(localPosts.values())
        .filter(p => p.workerId === req.params.workerId && p.status === 'active');
      return res.json({ success: true, data: posts });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/worker-posts/:postId
 */
async function getPost(req, res, next) {
  try {
    if (getIsConnected()) {
      const post = await WorkerPost.findById(req.params.postId)
        .populate('categoryId', 'name iconKey')
        .lean();
      if (!post) return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      await WorkerPost.findByIdAndUpdate(req.params.postId, { $inc: { viewCount: 1 } });
      return res.json({ success: true, data: post });
    } else {
      const post = localPosts.get(req.params.postId);
      if (!post) return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      post.viewCount = (post.viewCount || 0) + 1;
      return res.json({ success: true, data: post });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/worker-posts/:postId
 */
async function updatePost(req, res, next) {
  try {
    const userId = req.user.userId;

    if (getIsConnected()) {
      const profile = await WorkerProfile.findOne({ userId }).lean();
      if (!profile) return res.status(404).json({ success: false, message: 'Worker profile not found.' });
      const post = await WorkerPost.findOne({ _id: req.params.postId, workerId: profile._id });
      if (!post) return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      const allowed = ['title', 'description', 'categoryId', 'startingPrice', 'serviceRadiusKm', 'images'];
      for (const field of allowed) {
        if (req.body[field] !== undefined) post[field] = req.body[field];
      }
      await post.save();
      return res.json({ success: true, message: 'Post updated.', data: post });
    } else {
      const post = localPosts.get(req.params.postId);
      if (!post || post.userId !== userId) {
        return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      }
      const allowed = ['title', 'description', 'categoryId', 'startingPrice', 'serviceRadiusKm', 'images'];
      for (const field of allowed) {
        if (req.body[field] !== undefined) post[field] = req.body[field];
      }
      post.updatedAt = new Date().toISOString();
      localPosts.set(post._id, post);
      return res.json({ success: true, message: 'Post updated.', data: post });
    }
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/v1/worker-posts/:postId/status
 */
async function updatePostStatus(req, res, next) {
  try {
    const userId = req.user.userId;
    const allowedStatuses = ['active', 'paused', 'deleted'];
    const newStatus = String(req.body?.status || '').toLowerCase();
    if (!allowedStatuses.includes(newStatus)) {
      return res.status(400).json({ success: false, message: `Status must be one of: ${allowedStatuses.join(', ')}.` });
    }

    if (getIsConnected()) {
      const profile = await WorkerProfile.findOne({ userId }).lean();
      if (!profile) return res.status(404).json({ success: false, message: 'Worker profile not found.' });
      const post = await WorkerPost.findOneAndUpdate(
        { _id: req.params.postId, workerId: profile._id },
        { status: newStatus },
        { new: true }
      );
      if (!post) return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      return res.json({ success: true, message: `Post status updated to ${newStatus}.`, data: { status: post.status } });
    } else {
      const post = localPosts.get(req.params.postId);
      if (!post || post.userId !== userId) {
        return res.status(404).json({ success: false, message: 'Post not found.', code: 'NOT_FOUND' });
      }
      post.status = newStatus;
      post.updatedAt = new Date().toISOString();
      localPosts.set(post._id, post);
      return res.json({ success: true, message: `Post status updated to ${newStatus}.`, data: { status: newStatus } });
    }
  } catch (error) {
    next(error);
  }
}

module.exports = { createPost, getMyPosts, getAllPosts, getWorkerPosts, getPost, updatePost, updatePostStatus };
