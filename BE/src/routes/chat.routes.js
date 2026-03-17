const { Router } = require('express');
const {
  getChatMessages,
  sendMessage,
  getConversationList,
  getChatTargets,
  markChatAsRead,
  deleteConversation
} = require('../controllers/chat.controller.js');
const { protect } = require('../middlewares/auth.middleware.js');

const router = Router();

// Get all conversations
router.get('/', protect, getConversationList);

// Get available chat targets (admins for users, users for admins)
router.get('/targets', protect, getChatTargets);

// Get messages with specific user
router.get('/:userId', protect, getChatMessages);

// Send message
router.post('/', protect, sendMessage);

// Mark chat with user as read
router.patch('/:userId/read', protect, markChatAsRead);

// Delete chat conversation with user
router.delete('/:userId', protect, deleteConversation);

module.exports = router;
