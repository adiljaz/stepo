const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { protect } = require('../middlewares/authMiddleware');

router.get('/me', protect, async (req, res) => {
  res.json(req.user);
});

router.put('/profile', protect, async (req, res) => {
  const { district, state, country, username } = req.body;
  try {
    const user = await User.findById(req.user._id);
    if (district) user.district = district;
    if (state) user.state = state;
    if (country) user.country = country;
    if (username) user.username = username;
    
    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Update failed' });
  }
});

module.exports = router;
