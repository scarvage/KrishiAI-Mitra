const express = require('express');
const router = express.Router();
const priceController = require('../controllers/priceController');

/**
 * GET /api/price/mandi
 * Fetch live/cached mandi prices for a crop.
 *
 * Query params:
 *   crop   (required) - e.g. "Wheat"
 *   state  (optional) - e.g. "Punjab"
 *   limit  (optional) - max results, default 20
 *
 * Flutter integration:
 *   GET https://<host>/api/price/mandi?crop=Wheat&state=Punjab
 */
router.get('/mandi', priceController.getMandiPrices);

/**
 * GET /api/price/crops
 * Returns the list of supported crop names (useful for autocomplete in Flutter).
 */
router.get('/crops', priceController.getSupportedCrops);

/**
 * GET /api/price/health
 * Health-check endpoint for the price-checker service.
 */
router.get('/health', priceController.healthCheck);

module.exports = router;
