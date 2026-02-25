/**
 * Send a successful JSON response.
 * @param {import('express').Response} res
 * @param {object} data  - Payload to include in `data` field
 * @param {number} [statusCode=200]
 */
const successResponse = (res, data, statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    data,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Send an error JSON response.
 * @param {import('express').Response} res
 * @param {string} message - Human-readable error message
 * @param {number} [statusCode=500]
 * @param {object} [details] - Optional extra details (omitted in production)
 */
const errorResponse = (res, message, statusCode = 500, details = null) => {
  const body = {
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
  };

  if (details && process.env.NODE_ENV !== 'production') {
    body.details = details;
  }

  return res.status(statusCode).json(body);
};

module.exports = { successResponse, errorResponse };
