const express = require('express');
const multer = require('multer');
const diseaseController = require('../controllers/diseaseController');

// Store upload in memory (buffer) — no disk writes
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (_req, file, cb) => {
    if (['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, and WebP images are accepted'));
    }
  },
});

const router = express.Router();

// POST /api/disease/detect — multipart image OR JSON { imageBase64, mimeType, language }
router.post('/detect', upload.single('image'), diseaseController.detectDisease);

// GET /api/disease/health
router.get('/health', diseaseController.healthCheck);

module.exports = router;
