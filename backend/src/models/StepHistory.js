const mongoose = require('mongoose');

const stepHistorySchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true,
    index: true 
  },
  date: { 
    type: Date, 
    required: true,
    index: true
  },
  steps: { type: Number, default: 0 },
  calories: { type: Number, default: 0 },
  distance: { type: Number, default: 0 },
  
  // To detect spikes/cheating
  syncCount: { type: Number, default: 0 },
  lastSyncSteps: { type: Number, default: 0 }
}, {
  timestamps: true
});

// Composite index for efficient user-date lookups
stepHistorySchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('StepHistory', stepHistorySchema);
