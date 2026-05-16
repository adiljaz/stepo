const express = require('express');
const router = express.Router();
const { syncSteps, getHistory } = require('../controllers/stepController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/sync', protect, syncSteps);
router.get('/history', protect, getHistory);

module.exports = router;
