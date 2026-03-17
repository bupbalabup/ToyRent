const Chat = require('../models/chat.model.js');
const User = require('../models/user.model.js');
const { emitChatMessage } = require('../socket.js');
const mongoose = require('mongoose');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const getChatMessages = async (req, res, next) => {
  try {
    const { userId: otherUserId } = req.params;
    const currentUserId = req.user._id;

    if (!mongoose.Types.ObjectId.isValid(otherUserId)) {
      return res.status(400).json({ success: false, message: 'Invalid userId', data: {} });
    }

    // Verify the user exists
    const otherUser = await User.findById(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ success: false, message: 'User not found', data: {} });
    }

    // Fetch messages between the two users
    const messages = await Chat.find({
      $or: [
        { senderId: currentUserId, receiverId: otherUserId },
        { senderId: otherUserId, receiverId: currentUserId }
      ]
    })
      .sort({ createdAt: 1 })
      .populate('senderId', 'name email avatar')
      .populate('receiverId', 'name email avatar');

    // Mark unread messages as read
    await Chat.updateMany(
      { senderId: otherUserId, receiverId: currentUserId, isRead: false },
      { isRead: true, readAt: new Date() }
    );

    return res.status(200).json({
      success: true,
      message: 'Messages fetched',
      data: { messages }
    });
  } catch (error) {
    return next(error);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const { receiverId, message } = req.body;
    const senderId = req.user._id;

    if (!receiverId || !message) {
      throw new AppError('receiverId and message are required', 400);
    }

    if (!mongoose.Types.ObjectId.isValid(receiverId)) {
      throw new AppError('Invalid receiverId', 400);
    }

    if (message.trim().length === 0) {
      throw new AppError('Message cannot be empty', 400);
    }

    if (senderId.toString() === receiverId.toString()) {
      throw new AppError('Cannot send message to yourself', 400);
    }

    // Verify receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) {
      throw new AppError('Receiver not found', 404);
    }

    // Create and save message
    const chat = new Chat({
      senderId,
      receiverId,
      message: message.trim()
    });

    await chat.save();

    // Populate sender and receiver info
    await chat.populate('senderId', 'name email avatar');
    await chat.populate('receiverId', 'name email avatar');

    emitChatMessage(senderId.toString(), receiverId.toString(), chat.toObject());

    return res.status(201).json({
      success: true,
      message: 'Message sent',
      data: { message: chat }
    });
  } catch (error) {
    return next(error);
  }
};

const getConversationList = async (req, res, next) => {
  try {
    const userId = req.user._id;
    const { isAdmin } = req.query;

    let query;
    if (isAdmin === 'true') {
      // Admin sees all conversations
      query = {};
    } else {
      // Regular user sees conversations with admins only or their own conversations
      const admins = await User.find({ role: 'admin' }).select('_id');
      const adminIds = admins.map(a => a._id);
      query = {
        $or: [
          { senderId: userId, receiverId: { $in: adminIds } },
          { senderId: { $in: adminIds }, receiverId: userId }
        ]
      };
    }

    // Get last message from each conversation
    const conversations = await Chat.aggregate([
      { $match: query },
      {
        $group: {
          _id: {
            conversation: {
              $cond: [
                { $lt: ['$senderId', '$receiverId'] },
                { sender: '$senderId', receiver: '$receiverId' },
                { sender: '$receiverId', receiver: '$senderId' }
              ]
            }
          },
          lastMessage: { $last: '$$ROOT' },
          unreadCount: {
            $sum: {
              $cond: [
                { $and: [{ $eq: ['$receiverId', userId] }, { $eq: ['$isRead', false] }] },
                1,
                0
              ]
            }
          }
        }
      },
      { $sort: { 'lastMessage.createdAt': -1 } },
      {
        $lookup: {
          from: 'users',
          localField: '_id.conversation.sender',
          foreignField: '_id',
          as: 'sender'
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id.conversation.receiver',
          foreignField: '_id',
          as: 'receiver'
        }
      },
      { $unwind: '$sender' },
      { $unwind: '$receiver' }
    ]);

    return res.status(200).json({
      success: true,
      message: 'Conversations fetched',
      data: { conversations }
    });
  } catch (error) {
    return next(error);
  }
};

const getChatTargets = async (req, res, next) => {
  try {
    const isAdmin = req.user.role === 'admin';
    const roleFilter = isAdmin ? 'user' : 'admin';

    const users = await User.find({ role: roleFilter })
      .select('_id name email')
      .sort({ name: 1 });

    return res.status(200).json({
      success: true,
      message: 'Chat targets fetched',
      data: { users }
    });
  } catch (error) {
    return next(error);
  }
};

const markChatAsRead = async (req, res, next) => {
  try {
    const { userId: otherUserId } = req.params;
    const currentUserId = req.user._id;

    if (!mongoose.Types.ObjectId.isValid(otherUserId)) {
      return res.status(400).json({ success: false, message: 'Invalid userId', data: {} });
    }

    await Chat.updateMany(
      { senderId: otherUserId, receiverId: currentUserId, isRead: false },
      { isRead: true, readAt: new Date() }
    );

    return res.status(200).json({
      success: true,
      message: 'Chat marked as read',
      data: {}
    });
  } catch (error) {
    return next(error);
  }
};

const deleteConversation = async (req, res, next) => {
  try {
    const { userId: otherUserId } = req.params;
    const currentUserId = req.user._id;

    if (!mongoose.Types.ObjectId.isValid(otherUserId)) {
      return res.status(400).json({ success: false, message: 'Invalid userId', data: {} });
    }

    const otherUser = await User.findById(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ success: false, message: 'User not found', data: {} });
    }

    const result = await Chat.deleteMany({
      $or: [
        { senderId: currentUserId, receiverId: otherUserId },
        { senderId: otherUserId, receiverId: currentUserId }
      ]
    });

    return res.status(200).json({
      success: true,
      message: 'Conversation deleted',
      data: { deletedCount: result.deletedCount }
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  getChatMessages,
  sendMessage,
  getConversationList,
  getChatTargets,
  markChatAsRead,
  deleteConversation
};
