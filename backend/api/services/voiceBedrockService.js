const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');
const logger = require('../utils/logger');

// System prompts per language code
const SYSTEM_PROMPTS = {
  hi: 'आप एक अनुभवी कृषि विशेषज्ञ हैं जो भारतीय किसानों की मदद करते हैं। सरल, व्यावहारिक हिंदी में जवाब दें। जवाब 3-4 वाक्यों में दें।',
  en: 'You are an experienced agricultural expert helping Indian farmers. Provide clear, practical advice in simple English. Keep your answer to 3-4 sentences.',
  pa: 'ਤੁਸੀਂ ਇੱਕ ਤਜਰਬੇਕਾਰ ਖੇਤੀਬਾੜੀ ਮਾਹਰ ਹੋ ਜੋ ਭਾਰਤੀ ਕਿਸਾਨਾਂ ਦੀ ਮਦਦ ਕਰਦੇ ਹੋ। ਸਰਲ ਪੰਜਾਬੀ ਵਿੱਚ ਜਵਾਬ ਦਿਓ।',
  mr: 'तुम्ही एक अनुभवी कृषी तज्ञ आहात जे भारतीय शेतकऱ्यांना मदत करतात. सोप्या मराठीत उत्तर द्या.',
  gu: 'તમે એક અનુભવી કૃષિ નિષ્ણાત છો જે ભારતીય ખેડૂતોને મદદ કરો છો. સરળ ગુજરાતીમાં જવાબ આપો.',
  bn: 'আপনি একজন অভিজ্ঞ কৃষি বিশেষজ্ঞ যিনি ভারতীয় কৃষকদের সাহায্য করেন। সহজ বাংলায় উত্তর দিন।',
  te: 'మీరు భారతీయ రైతులకు సహాయం చేసే అనుభవజ్ఞుడైన వ్యవసాయ నిపుణులు. సరళమైన తెలుగులో సమాధానం ఇవ్వండి.',
  ta: 'நீங்கள் இந்திய விவசாயிகளுக்கு உதவும் அனுபவமிக்க விவசாய நிபுணர். எளிய தமிழில் பதிலளிக்கவும்.',
  kn: 'ನೀವು ಭಾರತೀಯ ರೈತರಿಗೆ ಸಹಾಯ ಮಾಡುವ ಅನುಭವಿ ಕೃಷಿ ತಜ್ಞರು. ಸರಳ ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ.',
  ml: 'നിങ്ങൾ ഇന്ത്യൻ കർഷകരെ സഹായിക്കുന്ന പരിചയസമ്പന്നനായ കൃഷി വിദഗ്ധനാണ്. ലളിതമായ മലയാളത്തിൽ ഉത്തരം നൽകുക.',
  or: 'ଆପଣ ଜଣେ ଅଭିଜ୍ଞ କୃଷି ବିଶେଷଜ୍ଞ ଯିଏ ଭାରତୀୟ କୃଷକଙ୍କୁ ସାହାଯ୍ୟ କରନ୍ତି। ସରଳ ଓଡ଼ିଆ ଭାଷାରେ ଉତ୍ତର ଦିଅନ୍ତୁ।',
  ur: 'آپ ایک تجربہ کار زرعی ماہر ہیں جو ہندوستانی کسانوں کی مدد کرتے ہیں۔ سادہ اردو میں جواب دیں۔',
};

const LANGUAGE_NAMES = {
  hi: 'Hindi', en: 'English', pa: 'Punjabi', mr: 'Marathi',
  gu: 'Gujarati', bn: 'Bengali', te: 'Telugu', ta: 'Tamil',
  kn: 'Kannada', ml: 'Malayalam', or: 'Odia', ur: 'Urdu',
};

// Rule-based fallback when Bedrock is unavailable
const FALLBACK_RESPONSES = {
  hi: 'मैं अभी आपकी मदद करने में असमर्थ हूं क्योंकि AI सेवा उपलब्ध नहीं है। कृपया कुछ देर बाद पुनः प्रयास करें।',
  en: 'I am unable to assist right now as the AI service is unavailable. Please try again in a few moments.',
};

const getFallback = (lang) => FALLBACK_RESPONSES[lang] || FALLBACK_RESPONSES['en'];

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
 * Build request body for various Bedrock model providers.
 */
const buildRequestBody = (modelId, systemPrompt, query) => {
  if (modelId.includes('anthropic') || modelId.includes('claude')) {
    return JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 500,
      system: systemPrompt,
      messages: [{ role: 'user', content: query }],
    });
  }

  if (modelId.includes('titan')) {
    return JSON.stringify({
      inputText: `${systemPrompt}\n\nUser: ${query}\nAssistant:`,
      textGenerationConfig: { maxTokenCount: 500, temperature: 0.7, topP: 0.9 },
    });
  }

  if (modelId.includes('meta') || modelId.includes('llama')) {
    return JSON.stringify({
      prompt: `<s>[INST] <<SYS>>\n${systemPrompt}\n<</SYS>>\n\n${query} [/INST]`,
      max_gen_len: 500,
      temperature: 0.7,
      top_p: 0.9,
    });
  }

  if (modelId.includes('gemma')) {
    return JSON.stringify({
      messages: [
        { role: 'user', content: `${systemPrompt}\n\n${query}` },
      ],
      max_tokens: 500,
      temperature: 0.7,
      top_p: 0.9,
    });
  }

  // OpenAI-chat-compatible fallback
  return JSON.stringify({
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: query },
    ],
    max_tokens: 500,
    temperature: 0.7,
    top_p: 0.9,
  });
};

/**
 * Parse response text from the Bedrock response body.
 */
const parseResponseBody = (modelId, body) => {
  if (modelId.includes('anthropic') || modelId.includes('claude')) {
    return body?.content?.[0]?.text?.trim();
  }
  if (modelId.includes('titan')) {
    return body?.results?.[0]?.outputText?.trim();
  }
  if (modelId.includes('meta') || modelId.includes('llama')) {
    return body?.generation?.trim();
  }
  if (modelId.includes('gemma')) {
    return (
      body?.outputs?.[0]?.text?.trim() ||
      body?.choices?.[0]?.message?.content?.trim() ||
      body?.content?.[0]?.text?.trim()
    );
  }
  // OpenAI-chat-compatible fallback
  return (
    body?.choices?.[0]?.message?.content?.trim() ||
    body?.content?.[0]?.text?.trim() ||
    body?.results?.[0]?.outputText?.trim() ||
    body?.generation?.trim()
  );
};

/**
 * Generate an agricultural AI response via Amazon Bedrock.
 *
 * @param {string} query        - User's question
 * @param {string} languageCode - ISO language code (e.g. 'hi', 'en')
 * @param {string[]} history    - Optional prior conversation context (alternating user/assistant)
 * @returns {Promise<{answer: string, tokensUsed: number}>}
 */
const generateVoiceResponse = async (query, languageCode = 'hi', history = []) => {
  const langName = LANGUAGE_NAMES[languageCode] || 'Hindi';
  const systemPrompt = SYSTEM_PROMPTS[languageCode] || SYSTEM_PROMPTS['en'];

  // Check credentials
  const accessKey = process.env.AWS_ACCESS_KEY_ID;
  const secretKey = process.env.AWS_SECRET_ACCESS_KEY;
  if (!accessKey || accessKey === 'your_key_here' || !secretKey || secretKey === 'your_secret_here') {
    logger.warn('AWS credentials not configured, using fallback voice response');
    return { answer: getFallback(languageCode), tokensUsed: 0 };
  }

  const modelId = process.env.BEDROCK_MODEL_ID || 'amazon.titan-text-express-v1';

  // Append context note to query if conversation history exists
  let contextualQuery = query;
  if (history.length > 0) {
    const context = history
      .slice(-4) // last 2 turns
      .map((m) => `${m.role === 'user' ? 'Farmer' : 'Expert'}: ${m.text}`)
      .join('\n');
    contextualQuery = `[Previous conversation:\n${context}]\n\nFarmer's new question: ${query}`;
  }

  try {
    const bedrockClient = getClient();
    const body = buildRequestBody(modelId, systemPrompt, contextualQuery);

    const command = new InvokeModelCommand({
      modelId,
      contentType: 'application/json',
      accept: 'application/json',
      body,
    });

    logger.info('Calling Bedrock for voice response', { languageCode, langName, modelId });

    const response = await bedrockClient.send(command);
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const answer = parseResponseBody(modelId, responseBody);

    if (!answer) {
      throw new Error('Empty response from Bedrock');
    }

    const tokensUsed =
      responseBody?.usage?.output_tokens ||
      responseBody?.usage?.completion_tokens ||
      responseBody?.inputTextTokenCount ||
      0;

    logger.info('Bedrock voice response generated', { languageCode, tokensUsed });
    return { answer, tokensUsed };
  } catch (error) {
    logger.error('Bedrock voice call failed, using fallback', {
      error: error.message,
      code: error.$metadata?.httpStatusCode,
      languageCode,
    });
    return { answer: getFallback(languageCode), tokensUsed: 0 };
  }
};

module.exports = { generateVoiceResponse };
