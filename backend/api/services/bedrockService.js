const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');
const logger = require('../utils/logger');

// Language code → full name for the AI prompt
const LANGUAGE_NAMES = {
  hi: 'Hindi',
  en: 'English',
  pa: 'Punjabi',
  mr: 'Marathi',
  gu: 'Gujarati',
  bn: 'Bengali',
  te: 'Telugu',
  ta: 'Tamil',
  kn: 'Kannada',
  ml: 'Malayalam',
  or: 'Odia',
  ur: 'Urdu',
};

// Fallback rule-based recommendation (used if Bedrock call fails)
const fallbackRecommendation = (prices, languageCode) => {
  if (!prices || prices.length === 0) {
    return languageCode === 'hi'
      ? 'कोई मूल्य डेटा उपलब्ध नहीं है। कृपया बाद में पुनः प्रयास करें।'
      : 'No price data available. Please try again later.';
  }
  const avgPrice = prices.reduce((sum, p) => sum + p.modal_price, 0) / prices.length;
  const recent = prices.slice(0, Math.min(3, prices.length));
  const recentAvg = recent.reduce((sum, p) => sum + p.modal_price, 0) / recent.length;
  const trendPct = ((recentAvg - avgPrice) / avgPrice) * 100;

  if (languageCode === 'hi') {
    if (trendPct > 5) return 'भाव ऊपर जा रहे हैं। बेहतर दाम के लिए थोड़ा रुकें।';
    if (trendPct < -5) return 'भाव गिर रहे हैं। अभी बेचना फायदेमंद रहेगा।';
    return 'भाव स्थिर हैं। अभी बेचना एक अच्छा विकल्प है।';
  }
  if (trendPct > 5) return 'Prices are trending upward. Consider holding for better rates.';
  if (trendPct < -5) return 'Prices are declining. Sell now to avoid further drops.';
  return 'Prices are stable. This is a good time to sell.';
};

const getClient = () => {
  return new BedrockRuntimeClient({
    region: process.env.AWS_REGION || 'us-east-1',
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
  });
};

/**
 * Build request body based on the model provider.
 * Supports: Anthropic Claude, Amazon Titan Text, Meta Llama.
 */
const buildRequestBody = (modelId, prompt) => {
  // Anthropic Claude models
  if (modelId.includes('anthropic') || modelId.includes('claude')) {
    return JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 300,
      messages: [{ role: 'user', content: prompt }],
    });
  }

  // Amazon Titan Text models
  if (modelId.includes('titan')) {
    return JSON.stringify({
      inputText: prompt,
      textGenerationConfig: {
        maxTokenCount: 300,
        temperature: 0.7,
        topP: 0.9,
      },
    });
  }

  // Meta Llama models
  if (modelId.includes('meta') || modelId.includes('llama')) {
    return JSON.stringify({
      prompt,
      max_gen_len: 300,
      temperature: 0.7,
      top_p: 0.9,
    });
  }

  // OpenAI-compatible models on Bedrock (e.g. openai.gpt-oss-20b-1:0)
  if (modelId.includes('openai') || modelId.includes('gpt')) {
    return JSON.stringify({
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 300,
      temperature: 0.7,
    });
  }

  // Google Gemma models on Bedrock (e.g. google.gemma-3-4b-it)
  // Bedrock serves Gemma using OpenAI chat format, NOT Google Vertex format
  if (modelId.includes('google') || modelId.includes('gemma')) {
    return JSON.stringify({
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 300,
      temperature: 0.7,
      top_p: 0.9,
    });
  }

  // Default to OpenAI chat format (most broadly compatible)
  return JSON.stringify({
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 300,
  });
};

/**
 * Parse response body based on the model provider.
 */
const parseResponseBody = (modelId, responseBody) => {
  // Anthropic Claude
  if (modelId.includes('anthropic') || modelId.includes('claude')) {
    return responseBody?.content?.[0]?.text?.trim();
  }

  // Amazon Titan Text
  if (modelId.includes('titan')) {
    return responseBody?.results?.[0]?.outputText?.trim();
  }

  // Meta Llama
  if (modelId.includes('meta') || modelId.includes('llama')) {
    return responseBody?.generation?.trim();
  }

  // OpenAI-compatible models (e.g. openai.gpt-oss-20b-1:0)
  if (modelId.includes('openai') || modelId.includes('gpt')) {
    return responseBody?.choices?.[0]?.message?.content?.trim();
  }

  // Google Gemma models on Bedrock (OpenAI chat format)
  if (modelId.includes('google') || modelId.includes('gemma')) {
    return responseBody?.choices?.[0]?.message?.content?.trim();
  }

  // Try all known patterns
  return responseBody?.choices?.[0]?.message?.content?.trim()
    || responseBody?.candidates?.[0]?.content?.parts?.[0]?.text?.trim()
    || responseBody?.content?.[0]?.text?.trim()
    || responseBody?.results?.[0]?.outputText?.trim()
    || responseBody?.generation?.trim();
};

/**
 * Generate an AI-powered mandi recommendation using Amazon Bedrock.
 *
 * @param {string} crop - Crop name e.g. "Wheat"
 * @param {string|null} state - State name e.g. "Punjab"
 * @param {Array} prices - Array of price objects from Data.gov.in
 * @param {string} languageCode - ISO language code e.g. "hi", "en", "pa"
 * @returns {Promise<string>} AI-generated recommendation text
 */
const generateMandiRecommendation = async (crop, state, prices, languageCode = 'hi') => {
  const langName = LANGUAGE_NAMES[languageCode] || 'Hindi';

  if (!prices || prices.length === 0) {
    return fallbackRecommendation([], languageCode);
  }

  // Build price summary for the prompt
  const modalPrices = prices.map((p) => p.modal_price).filter((v) => v > 0);
  const avgPrice = Math.round(modalPrices.reduce((s, v) => s + v, 0) / modalPrices.length);
  const minPrice = Math.min(...modalPrices);
  const maxPrice = Math.max(...modalPrices);

  // Trend: compare most recent 3 vs overall average
  const recent = prices.slice(0, Math.min(3, prices.length));
  const recentAvg = recent.reduce((s, p) => s + p.modal_price, 0) / recent.length;
  const trendPct = (((recentAvg - avgPrice) / avgPrice) * 100).toFixed(1);
  const trendLabel = trendPct > 0 ? `+${trendPct}%` : `${trendPct}%`;

  // Top 3 mandis by modal price
  const top3 = prices
    .slice(0, 3)
    .map((p) => `${p.mandi} (₹${p.modal_price}/quintal)`)
    .join(', ');

  const locationContext = state ? `in ${state}` : 'across India';

  const prompt = `You are an expert agricultural advisor helping Indian farmers make informed selling decisions.

Current mandi price data for ${crop} ${locationContext}:
- Average modal price: ₹${avgPrice}/quintal
- Minimum price: ₹${minPrice}/quintal
- Maximum price: ₹${maxPrice}/quintal
- Recent price trend: ${trendLabel} compared to overall average
- Top mandis by price: ${top3}
- Total mandis reporting: ${prices.length}

Write a practical 2-3 sentence recommendation for a farmer in ${langName} advising whether to:
- SELL NOW (if prices are good or declining)
- HOLD and wait (if prices are likely to rise soon)
- WAIT for a better mandi (if price variation is high)

Be specific with price numbers. Write ONLY in ${langName} language. Do not include any English if the language is not English. Do not add any prefix like "Recommendation:" — just write the advice directly.`;

  // Skip Bedrock if credentials are not configured
  const accessKey = process.env.AWS_ACCESS_KEY_ID;
  const secretKey = process.env.AWS_SECRET_ACCESS_KEY;
  if (!accessKey || accessKey === 'your_key_here' || !secretKey || secretKey === 'your_secret_here') {
    logger.warn('AWS credentials not configured, using fallback recommendation');
    return fallbackRecommendation(prices, languageCode);
  }

  try {
    const bedrockClient = getClient();
    const modelId = process.env.BEDROCK_MODEL_ID || 'amazon.titan-text-express-v1';

    const body = buildRequestBody(modelId, prompt);

    const command = new InvokeModelCommand({
      modelId,
      contentType: 'application/json',
      accept: 'application/json',
      body,
    });

    logger.info('Calling Bedrock for recommendation', { crop, state, languageCode, modelId });

    const response = await bedrockClient.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const recommendation = parseResponseBody(modelId, responseBody);

    if (!recommendation) {
      throw new Error('Empty response from Bedrock');
    }

    logger.info('Bedrock recommendation generated', { crop, state, languageCode });
    return recommendation;
  } catch (error) {
    logger.error('Bedrock call failed, using fallback', {
      error: error.message,
      errorName: error.name,
      errorCode: error.$metadata?.httpStatusCode,
      crop,
      state,
      languageCode,
    });
    return fallbackRecommendation(prices, languageCode);
  }
};

module.exports = { generateMandiRecommendation };
