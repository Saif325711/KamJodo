const fs = require('fs');
const path = require('path');

// Use a writable location in serverless environments (Vercel, AWS Lambda, etc.).
// Local development falls back to ../../data/store.json.
const storePath = process.env.STORE_PATH
  ? path.resolve(process.env.STORE_PATH)
  : process.env.VERCEL || process.env.AWS_LAMBDA_FUNCTION_NAME
    ? path.join('/tmp', 'store.json')
    : path.join(__dirname, '..', '..', 'data', 'store.json');

const defaultStore = {
  categories: [
    { name: 'Driver', iconKey: 'taxi', imageUrl: '' },
    { name: 'Plumber', iconKey: 'plumbing', imageUrl: '' },
    { name: 'Electrician', iconKey: 'electric', imageUrl: '' },
    { name: 'Mechanic', iconKey: 'tools', imageUrl: '' },
    { name: 'Teacher', iconKey: 'school', imageUrl: '' },
  ],
  theme: {
    appTitle: 'KamJodo',
    primary: '#7A0000',
    secondary: '#B31217',
    tertiary: '#FF5F6D',
  },
};

function ensureStore() {
  try {
    const directoryPath = path.dirname(storePath);
    if (!fs.existsSync(directoryPath)) {
      fs.mkdirSync(directoryPath, { recursive: true });
    }
    if (!fs.existsSync(storePath)) {
      fs.writeFileSync(storePath, JSON.stringify(defaultStore, null, 2));
    }
  } catch (err) {
    console.warn('[store] Could not persist store file:', err.message);
  }
}

function readStore() {
  ensureStore();
  try {
    const raw = fs.readFileSync(storePath, 'utf8');
    const parsed = JSON.parse(raw);
    return {
      categories: Array.isArray(parsed.categories) ? parsed.categories : defaultStore.categories,
      theme: parsed.theme || defaultStore.theme,
    };
  } catch (err) {
    console.warn('[store] Could not read store file:', err.message);
    return { ...defaultStore };
  }
}

function writeStore(store) {
  ensureStore();
  try {
    fs.writeFileSync(storePath, JSON.stringify(store, null, 2));
    return true;
  } catch (err) {
    console.warn('[store] Could not write store file:', err.message);
    return false;
  }
}

module.exports = {
  storePath,
  defaultStore,
  ensureStore,
  readStore,
  writeStore,
};
