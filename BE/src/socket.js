const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('./models/user.model.js');

const jwtSecret = process.env.JWT_SECRET;

let io;

const initializeSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
      credentials: true
    }
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token;
    const userId = socket.handshake.auth?.userId;

    if (!token || !userId) {
      return next(new Error('Authentication error'));
    }

    try {
      const decoded = jwt.verify(token, jwtSecret);
      const user = await User.findById(decoded.userId);

      if (!user) {
        return next(new Error('User not found'));
      }

      socket.userId = user._id.toString();
      socket.userRole = user.role;
      return next();
    } catch (error) {
      return next(new Error('Invalid token'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log(`[Socket] User connected: ${socket.userId} (role: ${socket.userRole})`);

    // Join user's personal room
    socket.join(`user_${socket.userId}`);

    // Join admin room if user is admin
    if (socket.userRole === 'admin') {
      socket.join('admin');
      console.log(`[Socket] Admin user ${socket.userId} joined admin room`);
    }

    // Handle chat room joining
    socket.on('join_chat_room', (data) => {
      const { otherUserId } = data;
      const chatRoom = [socket.userId, otherUserId].sort().join('_');
      socket.join(chatRoom);
      console.log(`[Socket] User ${socket.userId} joined chat room: ${chatRoom}`);
    });

    // Handle chat message
    socket.on('send_message', (data) => {
      const { receiverId, message } = data;
      const chatRoom = [socket.userId, receiverId].sort().join('_');
      
      // Emit to chat room
      io.to(chatRoom).emit('receive_message', {
        event: 'receive_message',
        data: {
          senderId: socket.userId,
          receiverId,
          message,
          createdAt: new Date().toISOString()
        },
        timestamp: new Date().toISOString()
      });

      console.log(`[Socket] Message sent in room ${chatRoom}`);
    });

    // Handle typing indicator
    socket.on('typing', (data) => {
      const { receiverId, isTyping } = data;
      const chatRoom = [socket.userId, receiverId].sort().join('_');
      
      io.to(chatRoom).emit('user_typing', {
        event: 'user_typing',
        data: {
          senderId: socket.userId,
          isTyping
        }
      });
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`[Socket] User disconnected: ${socket.userId}`);
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error(`[Socket] Error for user ${socket.userId}:`, error);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.io not initialized');
  }
  return io;
};

const emitOrderCreated = (userId, order) => {
  const io = getIO();
  io.to(`user_${userId}`).emit('order_created', {
    event: 'order_created',
    data: order,
    timestamp: new Date().toISOString()
  });

  // Also notify admins
  io.to('admin').emit('order_created', {
    event: 'order_created',
    data: order,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted order_created for order ${order._id}`);
};

const emitOrderUpdated = (orderId, order, userId) => {
  const io = getIO();

  // Notify the user who owns the order
  io.to(`user_${userId}`).emit('order_updated', {
    event: 'order_updated',
    data: order,
    timestamp: new Date().toISOString()
  });

  // Notify all admins
  io.to('admin').emit('order_updated', {
    event: 'order_updated',
    data: order,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted order_updated for order ${orderId}`);
};

const emitPaymentSuccess = (userId, order) => {
  const io = getIO();

  io.to(`user_${userId}`).emit('payment_success', {
    event: 'payment_success',
    data: order,
    timestamp: new Date().toISOString()
  });

  io.to('admin').emit('payment_success', {
    event: 'payment_success',
    data: order,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted payment_success for order ${order._id}`);
};

const emitPaymentFailed = (userId, order, reason = null) => {
  const io = getIO();

  io.to(`user_${userId}`).emit('payment_failed', {
    event: 'payment_failed',
    data: order,
    reason,
    timestamp: new Date().toISOString()
  });

  io.to('admin').emit('payment_failed', {
    event: 'payment_failed',
    data: order,
    reason,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted payment_failed for order ${order._id}`);
};

const emitOrderStatusChanged = (userId, order, oldStatus, newStatus) => {
  const io = getIO();

  io.to(`user_${userId}`).emit('order_status_changed', {
    event: 'order_status_changed',
    data: order,
    oldStatus,
    newStatus,
    timestamp: new Date().toISOString()
  });

  io.to('admin').emit('order_status_changed', {
    event: 'order_status_changed',
    data: order,
    oldStatus,
    newStatus,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted order_status_changed: ${oldStatus} -> ${newStatus}`);
};

const emitNotification = (userId, notification) => {
  const io = getIO();

  io.to(`user_${userId}`).emit('notification', {
    event: 'notification',
    data: notification,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted notification for user ${userId}`);
};

const emitChatMessage = (senderId, receiverId, message) => {
  const io = getIO();

  // Join chat room
  const chatRoom = [senderId.toString(), receiverId.toString()].sort().join('_');

  io.to(chatRoom).emit('receive_message', {
    event: 'receive_message',
    data: message,
    timestamp: new Date().toISOString()
  });

  // Also emit to receiver's personal room for notification
  io.to(`user_${receiverId}`).emit('chat_message', {
    event: 'chat_message',
    data: message,
    timestamp: new Date().toISOString()
  });

  console.log(`[Socket] Emitted chat_message in room ${chatRoom}`);
};

const emitTypingIndicator = (senderId, receiverId, isTyping) => {
  const io = getIO();
  const chatRoom = [senderId.toString(), receiverId.toString()].sort().join('_');

  io.to(chatRoom).emit('user_typing', {
    event: 'user_typing',
    data: {
      senderId,
      isTyping
    },
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  initializeSocket,
  getIO,
  emitOrderCreated,
  emitOrderUpdated,
  emitPaymentSuccess,
  emitPaymentFailed,
  emitOrderStatusChanged,
  emitNotification,
  emitChatMessage,
  emitTypingIndicator
};
