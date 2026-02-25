const LOG_LEVELS = { error: 0, warn: 1, info: 2, debug: 3 };
const CURRENT_LEVEL = process.env.LOG_LEVEL || 'info';

const shouldLog = (level) => LOG_LEVELS[level] <= LOG_LEVELS[CURRENT_LEVEL];

const format = (level, message, meta) => {
  const ts = new Date().toISOString();
  const base = `[${ts}] [${level.toUpperCase()}] ${message}`;
  return meta ? `${base} ${JSON.stringify(meta)}` : base;
};

const logger = {
  error: (message, meta) => {
    if (shouldLog('error')) console.error(format('error', message, meta));
  },
  warn: (message, meta) => {
    if (shouldLog('warn')) console.warn(format('warn', message, meta));
  },
  info: (message, meta) => {
    if (shouldLog('info')) console.log(format('info', message, meta));
  },
  debug: (message, meta) => {
    if (shouldLog('debug')) console.log(format('debug', message, meta));
  },
};

module.exports = logger;
