require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');
const logger = require('./api/utils/logger');

// Route modules
const priceRoutes = require('./api/routes/priceRoutes');
const voiceRoutes = require('./api/routes/voiceRoutes');
const diseaseRoutes = require('./api/routes/diseaseRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------

const isProduction = process.env.NODE_ENV === 'production';

app.use(cors({
  origin: isProduction ? process.env.CORS_ORIGIN || '*' : '*',
}));
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
app.use('/api/voice', voiceRoutes);
app.use('/api/disease', diseaseRoutes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Route not found' });
});

// Global error handler
app.use((err, _req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(err.status || 500).json({
    success: false,
    error: isProduction ? 'Internal server error' : err.message,
  });
});

// ---------------------------------------------------------------------------
// Process-level error handlers (production safety net)
// ---------------------------------------------------------------------------

process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception — shutting down', { error: err.message, stack: err.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection — shutting down', { reason: String(reason) });
  process.exit(1);
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const start = async () => {
  try {
    await connectDB();
    app.listen(PORT, HOST, () => {
      logger.info(`KrishiAI Mitra backend running on ${HOST}:${PORT} (${process.env.NODE_ENV || 'development'})`);
      logger.info('Routes available:');
      logger.info('  GET /health');
      logger.info('  GET /api/price/mandi?crop=<crop>&state=<state>');
      logger.info('  GET /api/price/crops');
      logger.info('  GET /api/price/health');
      logger.info('  POST /api/voice/query');
      logger.info('  GET  /api/voice/health');
      logger.info('  POST /api/disease/detect');
      logger.info('  GET  /api/disease/health');
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
};

start();
