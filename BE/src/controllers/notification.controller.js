import Notification from '../models/notification.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';

export const getMyNotifications = asyncHandler(async (req, res) => {
  const notifications = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 });
  return sendResponse(res, 200, 'Notifications fetched', { notifications });
});

export const markNotificationAsRead = asyncHandler(async (req, res) => {
  const notification = await Notification.findById(req.params.id);

  if (!notification) {
    throw new AppError('Notification not found', 404);
  }

  if (notification.userId.toString() !== req.user._id.toString()) {
    throw new AppError('Forbidden', 403);
  }

  notification.isRead = true;
  await notification.save();

  return sendResponse(res, 200, 'Notification marked as read', { notification });
});
