const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema(
  {
    query: { type: String, required: true, trim: true },
    answer: { type: String, required: true },
    language: { type: String, default: 'hi', maxlength: 5 },
    tokensUsed: { type: Number, default: 0 },
    cached: { type: Boolean, default: false },
    sessionId: { type: String, index: true },
  },
  {
    timestamps: true,
    // Auto-expire conversations after 30 days
    expireAfterSeconds: 2592000,
  }
);

conversationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 2592000 });
conversationSchema.index({ language: 1, query: 1 });

module.exports = mongoose.model('Conversation', conversationSchema);
