const stepService = require('../services/stepService');
const StepHistory = require('../models/StepHistory');

const syncSteps = async (req, res) => {
  const { totalSteps, timestamp } = req.body;

  if (totalSteps === undefined) {
    return res.status(400).json({ message: 'totalSteps is required' });
  }

  try {
    const updatedUser = await stepService.syncSteps(req.user._id, totalSteps, timestamp);
    res.status(200).json({
      success: true,
      user: updatedUser
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const getHistory = async (req, res) => {
  try {
    const history = await StepHistory.find({ userId: req.user._id })
      .sort({ date: -1 })
      .limit(30);
    res.json(history);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch history' });
  }
};

module.exports = {
  syncSteps,
  getHistory
};
