const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const stepRoutes = require('./stepRoutes');
const leaderboardRoutes = require('./leaderboardRoutes');
const socialRoutes = require('./socialRoutes');

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/steps', stepRoutes);
router.use('/leaderboard', leaderboardRoutes);
router.use('/social', socialRoutes);

module.exports = router;
