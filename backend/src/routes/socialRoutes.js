const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { protect } = require('../middlewares/authMiddleware');

// Helper to format user for frontend SocialUser model
const formatSocialUser = (user) => {
  try {
    return {
      id: user._id.toString(),
      name: user.username || user.email?.split('@')[0] || 'User',
      steps: user.totalSteps || 0,
      location: user.district && user.state ? `${user.district}, ${user.state}` : (user.country || 'Unknown'),
      streak: user.streakCount || 0,
      xp: user.xp || 0,
      level: user.level || 1,
      profileImage: user.profileImage || ''
    };
  } catch (e) {
    return {
      id: user._id.toString(),
      name: 'User',
      steps: 0,
      location: 'Unknown'
    };
  }
};

// GET /social/friends
router.get('/friends', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('friends');
    res.json((user.friends || []).map(formatSocialUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /social/requests
router.get('/requests', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('incomingRequests');
    res.json((user.incomingRequests || []).map(formatSocialUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /social/sent-requests
router.get('/sent-requests', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('sentRequests');
    res.json((user.sentRequests || []).map(formatSocialUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /social/suggestions
router.get('/suggestions', protect, async (req, res) => {
  try {
    const currentUser = await User.findById(req.user._id);
    if (!currentUser) return res.status(404).json({ message: "User not found" });
    
    // Explicitly convert IDs to strings for robust comparison
    const friends = (currentUser.friends || []).map(id => id.toString());
    const incoming = (currentUser.incomingRequests || []).map(id => id.toString());
    const sent = (currentUser.sentRequests || []).map(id => id.toString());

    const excludeIds = [
      currentUser._id.toString(),
      ...friends,
      ...incoming,
      ...sent
    ];

    let suggestions = await User.find({
      _id: { $nin: excludeIds }
    }).limit(50).sort({ totalSteps: -1 });

    // Fallback: If suggestions empty, show some users (excluding self) even if they are friends
    // (Though usually we want to keep them separate, this helps debug if something is hidden)
    if (suggestions.length === 0) {
      suggestions = await User.find({
        _id: { $ne: currentUser._id }
      }).limit(10).sort({ createdAt: -1 });
    }

    res.json(suggestions.map(formatSocialUser));
  } catch (error) {
    console.error('Suggestions error:', error);
    res.status(500).json({ message: error.message });
  }
});


// GET /social/search?q=query
router.get('/search', protect, async (req, res) => {
  const { q } = req.query;
  if (!q) return res.json([]);

  try {
    const currentUser = await User.findById(req.user._id);
    
    // Search by username (case-insensitive)
    const users = await User.find({
      username: { $regex: q, $options: 'i' },
      _id: { $ne: req.user._id }
    }).limit(20);

    // Map through users and add relationship status if needed
    // But for now, just return formatted users
    res.json(users.map(formatSocialUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});


// POST /social/request/send
router.post('/request/send', protect, async (req, res) => {
  const { userId } = req.body;
  try {
    if (userId === req.user._id.toString()) {
      return res.status(400).json({ message: "Cannot send request to yourself" });
    }

    const [sender, receiver] = await Promise.all([
      User.findById(req.user._id),
      User.findById(userId)
    ]);

    if (!receiver) return res.status(404).json({ message: "User not found" });

    // Check if already friends or already sent
    if (sender.friends.includes(userId)) return res.status(400).json({ message: "Already friends" });
    if (sender.sentRequests.includes(userId)) return res.status(400).json({ message: "Request already sent" });

    sender.sentRequests.push(userId);
    receiver.incomingRequests.push(req.user._id);

    await Promise.all([sender.save(), receiver.save()]);
    res.json({ message: "Request sent" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /social/request/accept
router.post('/request/accept', protect, async (req, res) => {
  const { userId } = req.body;
  try {
    const [receiver, sender] = await Promise.all([
      User.findById(req.user._id),
      User.findById(userId)
    ]);

    if (!sender) return res.status(404).json({ message: "User not found" });

    // Remove from requests
    receiver.incomingRequests = receiver.incomingRequests.filter(id => id.toString() !== userId);
    sender.sentRequests = sender.sentRequests.filter(id => id.toString() !== req.user._id.toString());

    // Add to friends
    if (!receiver.friends.includes(userId)) receiver.friends.push(userId);
    if (!sender.friends.includes(req.user._id)) sender.friends.push(req.user._id);

    await Promise.all([receiver.save(), sender.save()]);
    res.json({ message: "Request accepted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /social/request/reject
router.post('/request/reject', protect, async (req, res) => {
  const { userId } = req.body;
  try {
    const [receiver, sender] = await Promise.all([
      User.findById(req.user._id),
      User.findById(userId)
    ]);

    receiver.incomingRequests = receiver.incomingRequests.filter(id => id.toString() !== userId);
    if (sender) {
      sender.sentRequests = sender.sentRequests.filter(id => id.toString() !== req.user._id.toString());
      await sender.save();
    }

    await receiver.save();
    res.json({ message: "Request rejected" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// POST /social/request/cancel
router.post('/request/cancel', protect, async (req, res) => {
  const { userId } = req.body;
  try {
    const [sender, receiver] = await Promise.all([
      User.findById(req.user._id),
      User.findById(userId)
    ]);

    sender.sentRequests = sender.sentRequests.filter(id => id.toString() !== userId);
    if (receiver) {
      receiver.incomingRequests = receiver.incomingRequests.filter(id => id.toString() !== req.user._id.toString());
      await receiver.save();
    }

    await sender.save();
    res.json({ message: "Request cancelled" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
