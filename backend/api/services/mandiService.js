const axios = require('axios');
const logger = require('../utils/logger');

// Data.gov.in Mandi Prices API
// Resource: Daily Market Prices (Agmarknet)
const DATA_GOV_BASE_URL = 'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

// Supported crops mapped to their API commodity names
const CROP_ALIASES = {
  wheat: 'Wheat',
  rice: 'Rice',
  paddy: 'Paddy',
  cotton: 'Cotton',
  sugarcane: 'Sugarcane',
  tomato: 'Tomato',
  potato: 'Potato',
  onion: 'Onion',
  maize: 'Maize',
  soybean: 'Soyabean',
  groundnut: 'Groundnut',
  mustard: 'Mustard',
  chilli: 'Chilli',
  garlic: 'Garlic',
  ginger: 'Ginger',
  turmeric: 'Turmeric',
  lentil: 'Lentil',
  chickpea: 'Gram',
  moong: 'Moong',
  urad: 'Urad',
  arhar: 'Arhar',
  bajra: 'Bajra',
  jowar: 'Jowar',
  ragi: 'Ragi',
  sunflower: 'Sunflower Seed',
};

/**
 * Normalize a crop name to a Data.gov.in commodity name.
 * Tries alias map first, then falls back to title-cased input.
 * @param {string} crop
 * @returns {string}
 */
const normalizeCrop = (crop) => {
  const lower = crop.trim().toLowerCase();
  return CROP_ALIASES[lower] || crop.trim().replace(/\b\w/g, (c) => c.toUpperCase());
};

/**
 * Parse DD/MM/YYYY date string (from Data.gov.in) to a JS Date.
 * Returns null if parsing fails.
 * @param {string} dateStr - e.g. "28/02/2026"
 * @returns {Date|null}
 */
const parseArrivalDate = (dateStr) => {
  if (!dateStr) return null;
  const parts = dateStr.split('/');
  if (parts.length !== 3) return null;
  const [dd, mm, yyyy] = parts;
  const d = new Date(`${yyyy}-${mm}-${dd}`);
  return isNaN(d.getTime()) ? null : d;
};

/**
 * Fetch mandi prices from Data.gov.in Agmarknet API.
 * @param {string} crop  - Crop name (e.g. "Wheat", "Rice")
 * @param {string|null} state - Optional state filter (e.g. "Punjab")
 * @param {number} [limit=20] - Max records to fetch
 * @returns {Promise<{ prices: Array, lastUpdated: string }>}
 */
const fetchMandiPrices = async (crop, state = null, limit = 20) => {
  const apiKey = process.env.DATA_GOV_API_KEY;
  if (!apiKey) {
    logger.warn('DATA_GOV_API_KEY not set; mandi API will fail');
  }

  const commodityName = normalizeCrop(crop);

  const params = {
    'api-key': apiKey,
    format: 'json',
    limit,
    'filters[commodity]': commodityName,
  };

  if (state) {
    params['filters[state]'] = state.trim();
  }

  try {
    logger.info('Fetching mandi prices', { commodity: commodityName, state, limit });

    const response = await axios.get(DATA_GOV_BASE_URL, {
      params,
      timeout: 8000,
    });

    const records = response.data?.records || [];

    const prices = records
      .map((record) => {
        const parsedDate = parseArrivalDate(record.arrival_date);
        return {
          mandi: record.market || 'Unknown',
          state: record.state || '',
          district: record.district || '',
          commodity: record.commodity || commodityName,
          variety: record.variety || '',
          modal_price: parseFloat(record.modal_price) || 0,
          min_price: parseFloat(record.min_price) || 0,
          max_price: parseFloat(record.max_price) || 0,
          arrival_date: parsedDate ? parsedDate.toISOString().split('T')[0] : record.arrival_date || null,
          _parsedDate: parsedDate,
        };
      })
      // Filter out records with no price data
      .filter((p) => p.modal_price > 0)
      // Sort most recent first
      .sort((a, b) => {
        if (!a._parsedDate) return 1;
        if (!b._parsedDate) return -1;
        return b._parsedDate - a._parsedDate;
      })
      // Remove internal _parsedDate field
      .map(({ _parsedDate, ...rest }) => rest);

    const lastUpdated = prices.length > 0 ? prices[0].arrival_date : new Date().toISOString();

    logger.info('Mandi prices fetched', { commodity: commodityName, count: prices.length });

    return { prices, lastUpdated };
  } catch (error) {
    logger.error('Mandi API request failed', {
      commodity: commodityName,
      error: error.message,
      status: error.response?.status,
    });

    // Return empty result so the controller can serve from cache or show message
    return { prices: [], lastUpdated: new Date().toISOString() };
  }
};

module.exports = { fetchMandiPrices, normalizeCrop };
