const voiceBedrockService = require('../services/voiceBedrockService');
const Conversation = require('../models/Conversation');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

const SUPPORTED_LANGUAGES = ['hi', 'en', 'pa', 'mr', 'gu', 'bn', 'te', 'ta', 'kn', 'ml', 'or', 'ur'];

/**
 * Sanitize user input to prevent injection.
 */
const sanitizeQuery = (input) => {
  if (typeof input !== 'string') return '';
  return input.trim().slice(0, 500); // max 500 chars
};

const parseLanguageCode = (header) => {
  if (!header) return 'hi';
  const code = header.split(/[,;]/)[0].trim().split('-')[0].toLowerCase();
  return SUPPORTED_LANGUAGES.includes(code) ? code : 'hi';
};

/**
 * POST /api/voice/query
 * Body: { query: string, language?: string, sessionId?: string, history?: [{role, text}] }
 */
const handleVoiceQuery = async (req, res) => {
  try {
    const { query, sessionId, history = [] } = req.body;

    // Prefer explicit body language over header
    let languageCode = req.body.language;
    if (!SUPPORTED_LANGUAGES.includes(languageCode)) {
      languageCode = parseLanguageCode(req.headers['accept-language']);
    }

    // Validate input
    const cleanQuery = sanitizeQuery(query);
    if (!cleanQuery) {
      return errorResponse(res, 'query field is required and must be a non-empty string', 400);
    }

    // Validate history shape
    const validHistory = Array.isArray(history)
      ? history.filter((m) => m && typeof m.role === 'string' && typeof m.text === 'string').slice(-6)
      : [];

    // Call Bedrock AI
    const { answer, tokensUsed } = await voiceBedrockService.generateVoiceResponse(
      cleanQuery,
      languageCode,
      validHistory
    );

    const responseData = {
      query: cleanQuery,
      answer,
      language: languageCode,
      tokensUsed,
    };

    // Persist to MongoDB asynchronously (fire-and-forget)
    Conversation.create({
      query: cleanQuery,
      answer,
      language: languageCode,
      tokensUsed,
      sessionId: sessionId || null,
    }).catch((err) => logger.error('Failed to persist conversation', { error: err.message }));

    return successResponse(res, responseData);
  } catch (error) {
    logger.error('handleVoiceQuery error', { error: error.message });
    return errorResponse(res, 'Failed to process voice query. Please try again.', 500);
  }
};

/**
 * GET /api/voice/health
 */
const healthCheck = (_req, res) => {
  return successResponse(res, { service: 'voice-assistant', status: 'ok' });
};

module.exports = { handleVoiceQuery, healthCheck };
