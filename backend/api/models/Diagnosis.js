const mongoose = require('mongoose');

const diagnosisSchema = new mongoose.Schema(
  {
    imageHash: { type: String, default: null, index: true },
    imageUrl: { type: String, default: null },
    diseaseName: { type: String, required: true },
    diseaseNameHindi: { type: String, default: '' },
    confidence: { type: Number, required: true, min: 0, max: 1 },
    severity: { type: String, enum: ['none', 'low', 'medium', 'high'], default: 'medium' },
    cropType: { type: String, default: 'Unknown' },
    treatments: { type: [String], default: [] },
    treatmentsHindi: { type: [String], default: [] },
    detectedLabels: { type: [String], default: [] },
    lowConfidence: { type: Boolean, default: false },
    language: { type: String, default: 'hi' },
  },
  {
    timestamps: true,
    expireAfterSeconds: 604800, // 7-day TTL
  }
);

diagnosisSchema.index({ createdAt: 1 }, { expireAfterSeconds: 604800 });

module.exports = mongoose.model('Diagnosis', diagnosisSchema);
