require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');
const logger = require('./api/utils/logger');

// Route modules
const priceRoutes = require('./api/routes/priceRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Simple request logger
app.use((req, _res, next) => {
  logger.info(`${req.method} ${req.originalUrl}`);
  next();
});

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// Health check for the whole server
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Feature routes
app.use('/api/price', priceRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// Global error handler
app.use((err, _req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ success: false, error: 'Internal server error' });
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const start = async () => {
  try {
    await connectDB();
    app.listen(PORT, () => {
      logger.info(`KrishiAI Mitra backend running on port ${PORT}`);
      logger.info('Routes available:');
      logger.info('  GET /health');
      logger.info('  GET /api/price/mandi?crop=<crop>&state=<state>');
      logger.info('  GET /api/price/crops');
      logger.info('  GET /api/price/health');
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
};

start();
