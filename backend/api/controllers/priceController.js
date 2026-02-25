const mandiService = require('../services/mandiService');
const cacheService = require('../services/cacheService');
const PriceQuery = require('../models/PriceQuery');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

const CACHE_TTL_SECONDS = 6 * 60 * 60; // 6 hours
const STALE_THRESHOLD_MS = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Generate a sell/hold recommendation based on price spread across mandis.
 * Logic:
 *   - Compare the most recent 3 entries vs overall average.
 *   - trend > 5% → prices trending up → Hold
 *   - trend < -5% → prices falling → Sell now
 *   - otherwise   → prices stable → Good time to sell
 *
 * @param {Array} prices
 * @returns {string}
 */
const generateRecommendation = (prices) => {
  if (!prices || prices.length === 0) {
    return 'No price data available. Please try a different crop or check back later.';
  }

  const avgPrice = prices.reduce((sum, p) => sum + p.modal_price, 0) / prices.length;

  const recent = prices.slice(0, Math.min(3, prices.length));
  const recentAvg = recent.reduce((sum, p) => sum + p.modal_price, 0) / recent.length;

  const trendPct = ((recentAvg - avgPrice) / avgPrice) * 100;

  if (trendPct > 5) {
    return 'Prices are trending upward. Consider holding your produce for better rates.';
  } else if (trendPct < -5) {
    return 'Prices are declining. Sell now to avoid further price drops.';
  } else {
    return 'Prices are stable. This is a good time to sell at current market rates.';
  }
};

/**
 * Check if the last updated date is considered stale (older than 24 hours).
 * @param {string} lastUpdated - ISO date string or date string
 * @returns {boolean}
 */
const isStale = (lastUpdated) => {
  if (!lastUpdated) return true;
  const diff = Date.now() - new Date(lastUpdated).getTime();
  return diff > STALE_THRESHOLD_MS;
};

/**
 * GET /api/price/mandi
 * Query params:
 *   - crop   (string, required) - e.g. "Wheat"
 *   - state  (string, optional) - e.g. "Punjab"
 *   - limit  (number, optional) - max results (default 20, max 50)
 */
const getMandiPrices = async (req, res) => {
  try {
    const { crop, state, limit: limitParam } = req.query;

    // Validate required param
    if (!crop || crop.trim() === '') {
      return errorResponse(res, 'crop query parameter is required', 400);
    }

    const cropClean = crop.trim();
    const stateClean = state ? state.trim() : null;
    const limit = Math.min(parseInt(limitParam, 10) || 20, 50);

    // Build cache key: price:wheat:punjab  or  price:wheat:all
    const cacheKey = `price:${cropClean.toLowerCase()}:${(stateClean || 'all').toLowerCase()}`;

    // --- Cache check ---
    const cached = cacheService.get(cacheKey);
    if (cached) {
      logger.info('Serving cached mandi prices', { cacheKey });
      return successResponse(res, {
        ...cached,
        cached: true,
        stale: isStale(cached.lastUpdated),
      });
    }

    // --- Live fetch from Data.gov.in ---
    const { prices, lastUpdated } = await mandiService.fetchMandiPrices(cropClean, stateClean, limit);

    const recommendation = generateRecommendation(prices);

    const result = {
      crop: cropClean,
      state: stateClean,
      prices,
      recommendation,
      lastUpdated,
      cached: false,
      stale: isStale(lastUpdated),
      totalMandis: prices.length,
    };

    // --- Persist to MongoDB (fire-and-forget, don't block response) ---
    PriceQuery.create({
      crop: cropClean.toLowerCase(),
      state: stateClean,
      pricesCount: prices.length,
      recommendation,
    }).catch((err) => logger.error('Failed to save price query to DB', { error: err.message }));

    // --- Cache result ---
    if (prices.length > 0) {
      cacheService.set(cacheKey, result, CACHE_TTL_SECONDS);
    }

    return successResponse(res, result);
  } catch (error) {
    logger.error('getMandiPrices error', { error: error.message });
    return errorResponse(res, 'Failed to fetch mandi prices. Please try again.', 500);
  }
};

/**
 * GET /api/price/crops
 * Returns the list of supported crops.
 */
const getSupportedCrops = (req, res) => {
  const crops = [
    'Wheat', 'Rice', 'Paddy', 'Cotton', 'Sugarcane',
    'Tomato', 'Potato', 'Onion', 'Maize', 'Soybean',
    'Groundnut', 'Mustard', 'Chilli', 'Garlic', 'Ginger',
    'Turmeric', 'Lentil', 'Chickpea', 'Moong', 'Urad',
    'Arhar', 'Bajra', 'Jowar', 'Ragi', 'Sunflower',
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
    cacheStats: cacheService.stats(),
  });
};

module.exports = { getMandiPrices, getSupportedCrops, healthCheck };
