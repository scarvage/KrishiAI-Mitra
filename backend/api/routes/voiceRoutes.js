const express = require('express');
const voiceController = require('../controllers/voiceController');

const router = express.Router();

// POST /api/voice/query — send a query, get AI agricultural answer
router.post('/query', voiceController.handleVoiceQuery);

// GET /api/voice/health — health check
router.get('/health', voiceController.healthCheck);

module.exports = router;
