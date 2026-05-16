const User = require('../models/User');

const getLeaderboard = async (req, res) => {
  const { type, country, state, district, limit = 50, page = 1 } = req.query;
  const skip = (page - 1) * limit;

  let query = {};
  
  if (type === 'country') query.country = country;
  if (type === 'state') query.state = state;
  if (type === 'district') query.district = district;

  try {
    const leaderboard = await User.find(query)
      .select('username profileImage totalSteps xp level country state district')
      .sort({ totalSteps: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      data: leaderboard,
      pagination: {
        total,
        page: parseInt(page),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch leaderboard' });
  }
};

const getXPLeaderboard = async (req, res) => {
  try {
    const leaderboard = await User.find()
      .select('username profileImage xp level')
      .sort({ xp: -1 })
      .limit(50);
    res.json(leaderboard);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch XP leaderboard' });
  }
};

module.exports = {
  getLeaderboard,
  getXPLeaderboard
};
