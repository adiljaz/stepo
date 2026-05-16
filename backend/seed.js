const mongoose = require('mongoose');
require('dotenv').config();
const { Achievement } = require('./src/models/Achievement');
const { Challenge } = require('./src/models/Challenge');

const seedData = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    // Clear existing
    await Achievement.deleteMany({});
    await Challenge.deleteMany({});

    const achievements = [
      { name: 'First Steps', description: 'Walk 1,000 steps', criteria: { type: 'steps', value: 1000 }, xpReward: 50 },
      { name: 'Hiking Pro', description: 'Walk 10,000 steps in a day', criteria: { type: 'steps', value: 10000 }, xpReward: 200 },
      { name: 'Consistency King', description: 'Maintain a 7-day streak', criteria: { type: 'streak', value: 7 }, xpReward: 500 }
    ];

    const challenges = [
      { title: 'Morning Jog', description: 'Complete 5,000 steps before 10 AM', type: 'daily', goalSteps: 5000, xpReward: 100 },
      { title: 'Weekly Warrior', description: '70,000 steps this week', type: 'weekly', goalSteps: 70000, xpReward: 1000 }
    ];

    await Achievement.insertMany(achievements);
    await Challenge.insertMany(challenges);

    console.log('Seed data inserted successfully');
    process.exit();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

seedData();
