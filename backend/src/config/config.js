const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  port: process.env.PORT || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongodbUri: process.env.MONGODB_URI,
  googleClientId: process.env.GOOGLE_CLIENT_ID,
  jwtSecret: process.env.JWT_SECRET,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
  jwtAccessExpiration: '1h',
  jwtRefreshExpiration: '7d',
  redisUrl: process.env.REDIS_URL,
  antiCheat: {
    maxStepsPerSync: 15000, // Maximum steps allowed in a single sync
    maxStepsPerMinute: 200,   // High-intensity running threshold
    syncIntervalMin: 60000,  // Minimum 1 minute between syncs
  }
};

module.exports = config;
