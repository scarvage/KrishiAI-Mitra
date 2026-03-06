const huggingfaceService = require('../services/huggingfaceService');
const Diagnosis = require('../models/Diagnosis');
const { successResponse, errorResponse } = require('../utils/response');
const logger = require('../utils/logger');

const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB
const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

// Low-confidence message per language
const LOW_CONFIDENCE_MESSAGES = {
  hi: 'AI को तस्वीर की पहचान करने में कठिनाई हो रही है। बेहतर रोशनी में, पत्ती के पास से स्पष्ट फोटो लें।',
  en: 'AI could not identify the disease with high confidence. Please capture a clearer image in good lighting, close to the affected leaf.',
};

const getLowConfidenceMsg = (lang) =>
  LOW_CONFIDENCE_MESSAGES[lang] || LOW_CONFIDENCE_MESSAGES['en'];

/**
 * POST /api/disease/detect
 * Accepts multipart/form-data with field "image" (binary) OR JSON with { imageBase64, mimeType }.
 */
const detectDisease = async (req, res) => {
  try {
    let imageBuffer;
    let mimeType;

    // Support both multipart (req.file) and base64 JSON body
    if (req.file) {
      imageBuffer = req.file.buffer;
      mimeType = req.file.mimetype;
    } else if (req.body && req.body.imageBase64) {
      // Flutter sends base64-encoded image
      const base64Data = req.body.imageBase64.replace(/^data:image\/\w+;base64,/, '');
      imageBuffer = Buffer.from(base64Data, 'base64');
      mimeType = req.body.mimeType || 'image/jpeg';
    } else {
      return errorResponse(res, 'No image provided. Send "image" as multipart or "imageBase64" in JSON body.', 400);
    }

    // Validate size
    if (imageBuffer.length > MAX_IMAGE_SIZE) {
      return errorResponse(res, 'Image exceeds 5MB limit. Please compress the image before uploading.', 400);
    }

    // Validate MIME type
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return errorResponse(res, 'Only JPEG, PNG, or WebP images are accepted.', 400);
    }

    // Language for localized messages
    const SUPPORTED_LANGUAGES = ['hi', 'en', 'pa', 'mr', 'gu', 'bn', 'te', 'ta', 'kn', 'ml', 'or', 'ur'];
    let language = req.body.language;
    if (!SUPPORTED_LANGUAGES.includes(language)) {
      const header = req.headers['accept-language'] || '';
      const code = header.split(/[,;]/)[0].trim().split('-')[0].toLowerCase();
      language = SUPPORTED_LANGUAGES.includes(code) ? code : 'hi';
    }

    // Classify with HuggingFace / Bedrock
    logger.info('Starting disease classification', { mimeType, size: imageBuffer.length });
    const classification = await huggingfaceService.classifyDisease(imageBuffer);

    const result = {
      diseaseName: classification.diseaseName,
      diseaseNameHindi: classification.diseaseNameHindi,
      confidence: classification.confidence,
      confidencePercent: Math.round(classification.confidence * 100),
      severity: classification.severity,
      cropType: classification.cropType,
      treatments: classification.treatments,
      treatmentsHindi: classification.treatmentsHindi,
      lowConfidence: classification.lowConfidence,
      lowConfidenceMessage: classification.lowConfidence ? getLowConfidenceMsg(language) : null,
      language,
    };

    // Persist to MongoDB asynchronously
    Diagnosis.create({
      diseaseName: classification.diseaseName,
      diseaseNameHindi: classification.diseaseNameHindi,
      confidence: classification.confidence,
      severity: classification.severity,
      cropType: classification.cropType,
      treatments: classification.treatments,
      treatmentsHindi: classification.treatmentsHindi,
      lowConfidence: classification.lowConfidence,
      language,
    }).catch((err) => logger.error('Failed to persist diagnosis', { error: err.message }));

    logger.info('Disease detection complete', {
      disease: classification.diseaseName,
      confidence: classification.confidence,
    });

    return successResponse(res, result);
  } catch (error) {
    logger.error('detectDisease error', { error: error.message });

    // Friendly error messages
    if (error.message.includes('temporarily unavailable')) {
      return errorResponse(res, error.message, 503);
    }

    return errorResponse(res, 'Disease detection failed. Please try again with a clearer image.', 500);
  }
};

/**
 * GET /api/disease/health
 */
const healthCheck = (_req, res) => {
  return successResponse(res, { service: 'disease-detector', status: 'ok' });
};

module.exports = { detectDisease, healthCheck };
