const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  type: { type: String, enum: ['daily', 'weekly', 'milestone'], required: true },
  goalSteps: { type: Number, required: true },
  xpReward: { type: Number, required: true },
  expiresAt: { type: Date },
  isActive: { type: Boolean, default: true }
}, {
  timestamps: true
});

const userChallengeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  challengeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge', required: true },
  currentSteps: { type: Number, default: 0 },
  isCompleted: { type: Boolean, default: false },
  completedAt: { type: Date }
});

module.exports = {
  Challenge: mongoose.model('Challenge', challengeSchema),
  UserChallenge: mongoose.model('UserChallenge', userChallengeSchema)
};
