const express = require('express');
const router = express.Router();
const Category = require('../../models/Category');
const { getIsConnected } = require('../../config/db');
const { authenticate, requireRole } = require('../../middleware/auth');
const fs = require('fs');
const path = require('path');

const storePath = path.join(__dirname, '..', '..', '..', 'data', 'store.json');

function readLocalCategories() {
  try {
    const raw = fs.readFileSync(storePath, 'utf8');
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed.categories) ? parsed.categories : [];
  } catch {
    return [];
  }
}

// GET /api/v1/categories  — Public
router.get('/', async (_req, res, next) => {
  try {
    if (getIsConnected()) {
      let cats = await Category.find().sort({ createdAt: -1 }).lean();
      if (!cats || cats.length === 0) {
        const local = readLocalCategories();
        await Category.insertMany(local);
        cats = await Category.find().sort({ createdAt: -1 }).lean();
      }
      return res.json({
        success: true,
        data: cats.map((c) => ({ id: c._id, name: c.name, iconKey: c.iconKey, imageUrl: c.imageUrl })),
      });
    }
    const cats = readLocalCategories();
    const mapped = cats.map((c) => {
      const catId = c.id || c._id || `cat_${c.name.toLowerCase().replace(/\s+/g, '_')}`;
      return { id: catId, _id: catId, name: c.name, iconKey: c.iconKey, imageUrl: c.imageUrl };
    });
    return res.json({ success: true, data: mapped });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/categories/:categoryId  — Public
router.get('/:categoryId', async (req, res, next) => {
  try {
    if (getIsConnected()) {
      const cat = await Category.findById(req.params.categoryId).lean();
      if (!cat) return res.status(404).json({ success: false, message: 'Category not found.', code: 'NOT_FOUND' });
      return res.json({ success: true, data: { id: cat._id, name: cat.name, iconKey: cat.iconKey, imageUrl: cat.imageUrl } });
    }
    return res.status(503).json({ success: false, message: 'Database not available for single category lookup.' });
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/categories  — Admin only
router.post('/', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const name = String(req.body?.name || '').trim();
    const iconKey = String(req.body?.iconKey || 'more').trim();
    const imageUrl = String(req.body?.imageUrl || '').trim();

    if (!name) {
      return res.status(400).json({ success: false, message: 'Category name is required.', code: 'VALIDATION_ERROR' });
    }

    if (getIsConnected()) {
      const exists = await Category.findOne({ name: { $regex: new RegExp(`^${name}$`, 'i') } });
      if (exists) return res.status(409).json({ success: false, message: 'Category already exists.', code: 'CONFLICT' });

      const cat = await Category.create({ name, iconKey, imageUrl });
      return res.status(201).json({ success: true, message: 'Category created.', data: cat });
    }

    return res.status(503).json({ success: false, message: 'Database not connected.' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
