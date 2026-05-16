const express = require('express');
const router = express.Router();
const { getLeaderboard, getXPLeaderboard } = require('../controllers/leaderboardController');
const { protect } = require('../middlewares/authMiddleware');

router.get('/', protect, getLeaderboard);
router.get('/xp', protect, getXPLeaderboard);

module.exports = router;
