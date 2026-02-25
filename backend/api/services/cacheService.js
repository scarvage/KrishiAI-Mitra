const NodeCache = require('node-cache');
const logger = require('../utils/logger');

// Default TTL: 6 hours (21600 seconds)
const cache = new NodeCache({ stdTTL: 21600, checkperiod: 600 });

/**
 * Retrieve a value from cache.
 * @param {string} key
 * @returns {any|null}
 */
const get = (key) => {
  const value = cache.get(key);
  if (value !== undefined) {
    logger.debug('Cache HIT', { key });
    return value;
  }
  logger.debug('Cache MISS', { key });
  return null;
};

/**
 * Store a value in cache.
 * @param {string} key
 * @param {any} value
 * @param {number} [ttl] - TTL in seconds; uses default if omitted
 */
const set = (key, value, ttl) => {
  const success = ttl !== undefined ? cache.set(key, value, ttl) : cache.set(key, value);
  logger.debug('Cache SET', { key, ttl: ttl || 'default' });
  return success;
};

/**
 * Delete a key from cache.
 * @param {string} key
 */
const del = (key) => {
  cache.del(key);
  logger.debug('Cache DEL', { key });
};

/**
 * Flush the entire cache.
 */
const flush = () => {
  cache.flushAll();
  logger.info('Cache flushed');
};

/**
 * Return cache statistics.
 */
const stats = () => cache.getStats();

module.exports = { get, set, del, flush, stats };
