const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const stepRoutes = require('./stepRoutes');
const leaderboardRoutes = require('./leaderboardRoutes');

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/steps', stepRoutes);
router.use('/leaderboard', leaderboardRoutes);

module.exports = router;
