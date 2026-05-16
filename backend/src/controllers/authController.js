const authService = require('../services/authService');
const User = require('../models/User');

const googleLogin = async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ message: 'idToken is required' });
  }

  try {
    const payload = await authService.verifyGoogleToken(idToken);
    const { user, accessToken, refreshToken } = await authService.loginUser(payload);

    res.status(200).json({
      success: true,
      user,
      accessToken,
      refreshToken
    });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
};

const refreshToken = async (req, res) => {
  const { token } = req.body;

  if (!token) return res.status(400).json({ message: 'Refresh token is required' });

  try {
    const user = await User.findOne({ refreshToken: token });
    if (!user) return res.status(403).json({ message: 'Invalid refresh token' });

    const tokens = authService.generateTokens(user._id);
    user.refreshToken = tokens.refreshToken;
    await user.save();

    res.json({
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken
    });
  } catch (error) {
    res.status(403).json({ message: 'Token refresh failed' });
  }
};

const logout = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    user.refreshToken = null;
    await user.save();
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Logout failed' });
  }
};

const register = async (req, res) => {
  try {
    const { user, accessToken, refreshToken } = await authService.registerWithEmail(req.body);
    res.status(201).json({ success: true, user, accessToken, refreshToken });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const emailLogin = async (req, res) => {
  try {
    const { email, password } = req.body;
    const { user, accessToken, refreshToken } = await authService.loginWithEmail(email, password);
    res.json({ success: true, user, accessToken, refreshToken });
  } catch (error) {
    res.status(401).json({ message: error.message });
  }
};

module.exports = {
  googleLogin,
  refreshToken,
  logout,
  register,
  emailLogin
};
