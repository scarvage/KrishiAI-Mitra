const mandiService = require('../services/mandiService');
const bedrockService = require('../services/bedrockService');
const PriceQuery = require('../models/PriceQuery');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

const SUPPORTED_LANGUAGES = ['hi', 'en', 'pa', 'mr', 'gu', 'bn', 'te', 'ta', 'kn', 'ml', 'or', 'ur'];

/**
 * Extract and validate language code from Accept-Language header.
 * Falls back to 'hi' (Hindi) if not provided or unsupported.
 * @param {string|undefined} header
 * @returns {string}
 */
const parseLanguageCode = (header) => {
  if (!header) return 'hi';
  const code = header.split(/[,;]/)[0].trim().split('-')[0].toLowerCase();
  return SUPPORTED_LANGUAGES.includes(code) ? code : 'hi';
};

/**
 * GET /api/price/mandi
 * Query params:
 *   - crop   (string, required) - e.g. "Wheat"
 *   - state  (string, optional) - e.g. "Punjab"
 *   - limit  (number, optional) - max results (default 20, max 50)
 * Headers:
 *   - Accept-Language (string, optional) - e.g. "hi", "en", "pa" — default "hi"
 */
const getMandiPrices = async (req, res) => {
  try {
    const { crop, state, limit: limitParam } = req.query;
    const languageCode = parseLanguageCode(req.headers['accept-language']);

    // Validate required param
    if (!crop || crop.trim() === '') {
      return errorResponse(res, 'crop query parameter is required', 400);
    }

    const cropClean = crop.trim();
    const stateClean = state ? state.trim() : null;
    const limit = Math.min(parseInt(limitParam, 10) || 20, 50);

    // --- Live fetch from Data.gov.in ---
    const { prices, lastUpdated } = await mandiService.fetchMandiPrices(cropClean, stateClean, limit);

    // --- AI recommendation via Amazon Bedrock (Claude) ---
    const recommendation = await bedrockService.generateMandiRecommendation(
      cropClean,
      stateClean,
      prices,
      languageCode
    );

    const result = {
      crop: cropClean,
      state: stateClean,
      prices,
      recommendation,
      language: languageCode,
      lastUpdated,
      totalMandis: prices.length,
    };

    // --- Persist to MongoDB (fire-and-forget, non-blocking) ---
    PriceQuery.create({
      crop: cropClean.toLowerCase(),
      state: stateClean,
      pricesCount: prices.length,
      recommendation,
    }).catch((err) => logger.error('Failed to save price query to DB', { error: err.message }));

    return successResponse(res, result);
  } catch (error) {
    logger.error('getMandiPrices error', { error: error.message });
    return errorResponse(res, 'Failed to fetch mandi prices. Please try again.', 500);
  }
};

/**
 * GET /api/price/crops
 * Returns the list of 10 major supported crops.
 */
const getSupportedCrops = (req, res) => {
  const crops = [
    'Wheat', 'Rice', 'Cotton', 'Sugarcane', 'Maize',
    'Soybean', 'Onion', 'Potato', 'Tomato', 'Mustard',
  ];
  return successResponse(res, { crops });
};

/**
 * GET /api/price/health
 * Lightweight health-check for this feature.
 */
const healthCheck = (req, res) => {
  return successResponse(res, {
    service: 'price-checker',
    status: 'ok',
  });
};

module.exports = { getMandiPrices, getSupportedCrops, healthCheck };
