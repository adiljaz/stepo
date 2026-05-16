const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String }, // Optional for Google users
  profileImage: { type: String },
  googleId: { type: String, unique: true, sparse: true },
  
  // Step Stats
  totalSteps: { type: Number, default: 0, index: true },
  todaySteps: { type: Number, default: 0 },
  weeklySteps: { type: Number, default: 0 },
  monthlySteps: { type: Number, default: 0 },
  
  // Fitness Stats
  caloriesBurned: { type: Number, default: 0 },
  distanceWalked: { type: Number, default: 0 }, // In KM
  
  // Gamification
  level: { type: Number, default: 1 },
  xp: { type: Number, default: 0, index: true },
  streakCount: { type: Number, default: 0 },
  lastSyncAt: { type: Date, default: Date.now },
  
  // Location for Regional Leaderboards
  district: { type: String, index: true },
  state: { type: String, index: true },
  country: { type: String, index: true },
  
  // Social
  friends: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  incomingRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  sentRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  
  createdAt: { type: Date, default: Date.now }
}, {
  timestamps: true
});

// Indexes for Leaderboards
userSchema.index({ totalSteps: -1 });
userSchema.index({ country: 1, totalSteps: -1 });
userSchema.index({ state: 1, totalSteps: -1 });
userSchema.index({ district: 1, totalSteps: -1 });
userSchema.index({ xp: -1 });

module.exports = mongoose.model('User', userSchema);
