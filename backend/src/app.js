const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const { connectDB, getIsConnected } = require('./config/db');
const Category = require('./models/Category');
const Theme = require('./models/Theme');
const { readStore, writeStore } = require('./utils/store');

const app = express();

function normalizeHexColor(value, fallback) {
  const text = String(value || '').trim();
  return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text) ? text : fallback;
}

function normalizeIconKey(value) {
  const text = String(value || '').trim().toLowerCase();
  const allowed = new Set(['taxi', 'plumbing', 'electric', 'tools', 'school', 'more', 'user']);
  return allowed.has(text) ? text : 'more';
}

// Security headers with Helmet
app.use(
  helmet({
    contentSecurityPolicy: false, // Allow inline styles/scripts for admin-web panel
  })
);

// CORS Configuration
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((item) => item.trim())
  : '*';

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins === '*' || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(null, true); // Permissive fallback for mobile apps & web
      }
    },
    credentials: true,
  })
);

app.use(express.json());

// Production Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300, // limit each IP to 300 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// ── API v1 Router (new versioned endpoints) ───────────────────────────────────
const v1Router = require('./routes/v1');
app.use('/api/v1', v1Router);

// Serve Admin Web Panel static files if available
const adminWebPath = path.join(__dirname, '..', '..', 'admin-web');
if (fs.existsSync(adminWebPath)) {
  app.use(express.static(adminWebPath));
}

// Health Check Endpoints
const healthHandler = (_req, res) => {
  res.json({
    success: true,
    message: 'KamJodo API is running',
    environment: process.env.NODE_ENV || 'development',
    database: getIsConnected() ? 'connected (MongoDB Atlas)' : 'local fallback (JSON store)',
  });
};

app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

// GET /categories (Supports MongoDB with JSON fallback)
app.get('/categories', async (_req, res, next) => {
  try {
    if (getIsConnected()) {
      let categories = await Category.find().sort({ createdAt: -1 }).lean();
      if (!categories || categories.length === 0) {
        // Seed default categories into MongoDB if empty
        const local = readStore().categories;
        await Category.insertMany(local);
        categories = await Category.find().sort({ createdAt: -1 }).lean();
      }
      return res.json({
        categories: categories.map((c) => ({
          name: c.name,
          iconKey: c.iconKey,
          imageUrl: c.imageUrl,
        })),
      });
    }

    return res.json({ categories: readStore().categories });
  } catch (error) {
    next(error);
  }
});

// POST /categories
app.post('/categories', async (req, res, next) => {
  try {
    const name = String(req.body?.name || '').trim();
    const iconKey = normalizeIconKey(req.body?.iconKey);
    const imageUrl = String(req.body?.imageUrl || '').trim();

    if (!name) {
      return res.status(400).json({ message: 'Category name is required.' });
    }

    if (getIsConnected()) {
      const exists = await Category.findOne({
        name: { $regex: new RegExp(`^${name}$`, 'i') },
      });

      if (exists) {
        return res.status(409).json({ message: 'Category already exists.' });
      }

      await Category.create({ name, iconKey, imageUrl });
      const nextCategories = await Category.find().sort({ createdAt: -1 }).lean();

      return res.status(201).json({
        message: 'Category added successfully.',
        categories: nextCategories.map((c) => ({
          name: c.name,
          iconKey: c.iconKey,
          imageUrl: c.imageUrl,
        })),
      });
    }

    // Local JSON store fallback
    const store = readStore();
    const exists = store.categories.some((category) => category.name.toLowerCase() === name.toLowerCase());

    if (exists) {
      return res.status(409).json({ message: 'Category already exists.' });
    }

    const nextCategories = [{ name, iconKey, imageUrl }, ...store.categories];
    writeStore({
      categories: nextCategories,
      theme: store.theme,
    });

    return res.status(201).json({ message: 'Category added successfully.', categories: nextCategories });
  } catch (error) {
    next(error);
  }
});

// DELETE /categories/:name
app.delete('/categories/:name', async (req, res, next) => {
  try {
    const name = String(req.params.name || '').trim();
    if (!name) {
      return res.status(400).json({ message: 'Category name is required.' });
    }

    if (getIsConnected()) {
      await Category.deleteOne({ name: { $regex: new RegExp(`^${name}$`, 'i') } });
      const nextCategories = await Category.find().sort({ createdAt: -1 }).lean();
      return res.json({
        message: 'Category deleted successfully.',
        categories: nextCategories.map((c) => ({ name: c.name, iconKey: c.iconKey, imageUrl: c.imageUrl })),
      });
    }

    const store = readStore();
    const nextCategories = store.categories.filter(
      (c) => c.name.toLowerCase() !== name.toLowerCase(),
    );
    writeStore({ categories: nextCategories, theme: store.theme });
    return res.json({ message: 'Category deleted successfully.', categories: nextCategories });
  } catch (error) {
    next(error);
  }
});

// GET /theme
app.get('/theme', async (_req, res, next) => {
  try {
    if (getIsConnected()) {
      let themeDoc = await Theme.findOne().lean();
      if (!themeDoc) {
        const localTheme = readStore().theme;
        themeDoc = await Theme.create(localTheme);
      }
      return res.json({
        appTitle: themeDoc.appTitle,
        primary: themeDoc.primary,
        secondary: themeDoc.secondary,
        tertiary: themeDoc.tertiary,
      });
    }

    return res.json(readStore().theme);
  } catch (error) {
    next(error);
  }
});

// PUT /theme
app.put('/theme', async (req, res, next) => {
  try {
    const store = readStore();
    const nextTheme = {
      appTitle: String(req.body?.appTitle || store.theme.appTitle || 'KamJodo').trim() || 'KamJodo',
      primary: normalizeHexColor(req.body?.primary, store.theme.primary),
      secondary: normalizeHexColor(req.body?.secondary, store.theme.secondary),
      tertiary: normalizeHexColor(req.body?.tertiary, store.theme.tertiary),
    };

    if (getIsConnected()) {
      let themeDoc = await Theme.findOne();
      if (!themeDoc) {
        themeDoc = await Theme.create(nextTheme);
      } else {
        themeDoc.appTitle = nextTheme.appTitle;
        themeDoc.primary = nextTheme.primary;
        themeDoc.secondary = nextTheme.secondary;
        themeDoc.tertiary = nextTheme.tertiary;
        await themeDoc.save();
      }
      return res.json({ message: 'Theme updated successfully.', theme: nextTheme });
    }

    writeStore({
      categories: store.categories,
      theme: nextTheme,
    });

    return res.json({ message: 'Theme updated successfully.', theme: nextTheme });
  } catch (error) {
    next(error);
  }
});

// 404 Handler
app.use((_req, res) => {
  res.status(404).json({ message: 'Endpoint not found.' });
});

// Global Centralized Error Handling Middleware (No stack traces in production)
app.use((err, _req, res, _next) => {
  console.error('[Error Middleware]:', err);
  const isProd = process.env.NODE_ENV === 'production';
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error.',
    ...(isProd ? {} : { stack: err.stack }),
  });
});

module.exports = app;
