const User = require('../models/User');
const StepHistory = require('../models/StepHistory');
const config = require('../config/config');

const syncSteps = async (userId, newTotalSteps, timestamp) => {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  // 1. Basic Anti-Cheat: Only allow step increase
  if (newTotalSteps < user.totalSteps) {
    throw new Error('New step count cannot be lower than current count');
  }

  const stepDiff = newTotalSteps - user.totalSteps;
  if (stepDiff === 0) return user; // No change

  // 2. Advanced Anti-Cheat: Detect impossible jumps
  const now = Date.now();
  const timeDiffMinutes = (now - user.lastSyncAt.getTime()) / (1000 * 60);
  
  // Prevent duplicate syncs too close together
  if (now - user.lastSyncAt.getTime() < config.antiCheat.syncIntervalMin) {
    throw new Error('Syncing too frequently. Please wait a minute.');
  }

  // Check steps per minute (e.g., > 200 is highly suspicious for long periods)
  const stepsPerMinute = stepDiff / (timeDiffMinutes || 1);
  if (stepsPerMinute > config.antiCheat.maxStepsPerMinute && stepDiff > 500) {
     throw new Error('Unrealistic step rate detected. Anti-cheat triggered.');
  }

  // 3. Absolute cap per sync window
  if (stepDiff > config.antiCheat.maxStepsPerSync) {
    throw new Error('Step jump too large for a single sync.');
  }

  // Update User Stats
  user.totalSteps = newTotalSteps;
  user.todaySteps += stepDiff;
  user.weeklySteps += stepDiff;
  user.monthlySteps += stepDiff;
  
  // Calculate approximate calories and distance (0.04 cal/step, 0.0008 km/step)
  user.caloriesBurned += stepDiff * 0.04;
  user.distanceWalked += stepDiff * 0.0008;
  user.lastSyncAt = new Date();

  // Handle Leveling/XP (Simple logic: 1 XP per 10 steps)
  const xpGained = Math.floor(stepDiff / 10);
  user.xp += xpGained;
  user.level = Math.floor(Math.sqrt(user.xp / 100)) + 1;

  await user.save();

  // 4. Update/Create Daily Step History
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  await StepHistory.findOneAndUpdate(
    { userId, date: today },
    { 
      $inc: { 
        steps: stepDiff, 
        calories: stepDiff * 0.04, 
        distance: stepDiff * 0.0008,
        syncCount: 1
      },
      lastSyncSteps: newTotalSteps
    },
    { upsage: true, new: true, setDefaultsOnInsert: true }
  );

  return user;
};

module.exports = {
  syncSteps
};
