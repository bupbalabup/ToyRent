import dotenv from 'dotenv';

dotenv.config();

const env = {
  port: Number(process.env.PORT) || 5000,
  mongoUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  nodeEnv: process.env.NODE_ENV || 'development',
  momoApiUrl: process.env.MOMO_API_URL,
  momoApiKey: process.env.MOMO_API_KEY,
  momoSecretKey: process.env.MOMO_SECRET_KEY,
  sepayApiUrl: process.env.SEPAY_API_URL,
  sepayApiKey: process.env.SEPAY_API_KEY,
  locationApiBase: process.env.LOCATION_API_BASE || 'https://provinces.open-api.vn/api'
};

if (!env.mongoUri) {
  throw new Error('MONGODB_URI is required');
}

if (!env.jwtSecret) {
  throw new Error('JWT_SECRET is required');
}

export default env;
