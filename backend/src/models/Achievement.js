const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  icon: { type: String },
  criteria: {
    type: { type: String, enum: ['steps', 'streak', 'level'], required: true },
    value: { type: Number, required: true }
  },
  xpReward: { type: Number, default: 0 }
});

const userAchievementSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  achievementId: { type: mongoose.Schema.Types.ObjectId, ref: 'Achievement', required: true },
  unlockedAt: { type: Date, default: Date.now }
});

module.exports = {
  Achievement: mongoose.model('Achievement', achievementSchema),
  UserAchievement: mongoose.model('UserAchievement', userAchievementSchema)
};
