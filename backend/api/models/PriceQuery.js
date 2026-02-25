const mongoose = require('mongoose');

const priceQuerySchema = new mongoose.Schema(
  {
    crop: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },
    state: {
      type: String,
      trim: true,
      default: null,
    },
    pricesCount: {
      type: Number,
      default: 0,
    },
    recommendation: {
      type: String,
      default: null,
    },
    // TTL index: auto-delete after 30 days
    createdAt: {
      type: Date,
      default: Date.now,
      expires: 60 * 60 * 24 * 30, // 30 days in seconds
    },
  },
  {
    timestamps: true,
  }
);

priceQuerySchema.index({ crop: 1 });
priceQuerySchema.index({ state: 1 });
priceQuerySchema.index({ createdAt: -1 });

const PriceQuery = mongoose.model('PriceQuery', priceQuerySchema);

module.exports = PriceQuery;
