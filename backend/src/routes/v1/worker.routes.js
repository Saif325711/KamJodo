const express = require('express');
const router = express.Router();
const {
  updateMyWorkerProfile,
  getMyWorkerProfile,
  getWorkerProfile,
  searchWorkers,
  setAvailability,
  followWorker,
  unfollowWorker,
  getFollowStatus,
} = require('../../controllers/worker.controller');
const { authenticate, requireRole } = require('../../middleware/auth');

// ─── Public routes ──────────────────────────────────────────────────────────

// GET /api/v1/workers  — Search workers (public)
router.get('/', searchWorkers);

// ⚠️ IMPORTANT: All /me/* and specific named routes MUST come before /:workerId

// ─── Worker-only routes ─────────────────────────────────────────────────────

// GET /api/v1/workers/me/profile  — Own profile
router.get('/me/profile', authenticate, requireRole('worker'), getMyWorkerProfile);

// PATCH /api/v1/workers/me/availability
router.patch('/me/availability', authenticate, requireRole('worker'), setAvailability);

// POST /api/v1/workers/onboarding  OR  PATCH /api/v1/workers/me
router.post('/onboarding', authenticate, requireRole('worker'), updateMyWorkerProfile);
router.patch('/me', authenticate, requireRole('worker'), updateMyWorkerProfile);

// GET /api/v1/workers/:workerId/posts  — public (must be before /:workerId)
const { getWorkerPosts } = require('../../controllers/workerPost.controller');
router.get('/:workerId/posts', getWorkerPosts);

// ─── Follow routes (customers only) ─────────────────────────────────────────

// POST /api/v1/workers/:workerId/follow
router.post('/:workerId/follow', authenticate, requireRole('customer'), followWorker);

// DELETE /api/v1/workers/:workerId/follow
router.delete('/:workerId/follow', authenticate, requireRole('customer'), unfollowWorker);

// GET /api/v1/workers/:workerId/follow-status
router.get('/:workerId/follow-status', authenticate, getFollowStatus);

// GET /api/v1/workers/:workerId/reviews  — public
const { getWorkerReviews } = require('../../controllers/review.controller');
router.get('/:workerId/reviews', getWorkerReviews);

// GET /api/v1/workers/:workerId  — Public worker profile (MUST be last)
router.get('/:workerId', getWorkerProfile);

module.exports = router;
