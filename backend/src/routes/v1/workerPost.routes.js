const express = require('express');
const router = express.Router();
const {
  createPost, getMyPosts, getAllPosts, getWorkerPosts, getPost, updatePost, updatePostStatus,
} = require('../../controllers/workerPost.controller');
const { authenticate, requireRole } = require('../../middleware/auth');

// Public — get all active posts for customer feed
router.get('/', getAllPosts);

// Worker only — own posts
router.get('/me/all', authenticate, requireRole('worker'), getMyPosts);

// Worker only — create post
router.post('/', authenticate, requireRole('worker'), createPost);

// Worker only — update post
router.patch('/:postId/status', authenticate, requireRole('worker'), updatePostStatus);
router.patch('/:postId', authenticate, requireRole('worker'), updatePost);

// Public — single post by ID (MUST be last to avoid matching "me")
router.get('/:postId', getPost);

module.exports = router;
