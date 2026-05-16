const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const config = require('../config/config');
const User = require('../models/User');

const client = new OAuth2Client(config.googleClientId);

const verifyGoogleToken = async (idToken) => {
  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: config.googleClientId,
    });
    return ticket.getPayload();
  } catch (error) {
    throw new Error('Invalid Google Token');
  }
};

const generateTokens = (userId) => {
  const accessToken = jwt.sign({ userId }, config.jwtSecret, {
    expiresIn: config.jwtAccessExpiration,
  });
  const refreshToken = jwt.sign({ userId }, config.jwtRefreshSecret, {
    expiresIn: config.jwtRefreshExpiration,
  });
  return { accessToken, refreshToken };
};

const loginUser = async (googlePayload) => {
  const { sub: googleId, email, name, picture } = googlePayload;

  let user = await User.findOne({ googleId });

  if (!user) {
    user = await User.create({
      googleId,
      email,
      username: name,
      profileImage: picture,
      country: 'Unknown',
      state: 'Unknown',
      district: 'Unknown'
    });
  }

  const { accessToken, refreshToken } = generateTokens(user._id);
  
  user.refreshToken = refreshToken;
  await user.save();

  return { user, accessToken, refreshToken };
};

const registerWithEmail = async (userData) => {
  const { username, email, password } = userData;

  const existingUser = await User.findOne({ email });
  if (existingUser) throw new Error('User already exists');

  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  const user = await User.create({
    username,
    email,
    password: hashedPassword,
    country: 'Unknown',
    state: 'Unknown',
    district: 'Unknown'
  });

  const { accessToken, refreshToken } = generateTokens(user._id);
  user.refreshToken = refreshToken;
  await user.save();

  return { user, accessToken, refreshToken };
};

const loginWithEmail = async (email, password) => {
  const user = await User.findOne({ email });
  if (!user || !user.password) throw new Error('Invalid credentials');

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) throw new Error('Invalid credentials');

  const { accessToken, refreshToken } = generateTokens(user._id);
  user.refreshToken = refreshToken;
  await user.save();

  return { user, accessToken, refreshToken };
};

module.exports = {
  verifyGoogleToken,
  generateTokens,
  loginUser,
  registerWithEmail,
  loginWithEmail,
};
