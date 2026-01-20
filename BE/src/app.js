const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/auth.routes.js');
const categoryRoutes = require('./routes/category.routes.js');
const toyRoutes = require('./routes/toy.routes.js');
const { getToys } = require('./controllers/toy.controller.js');
const orderRoutes = require('./routes/order.routes.js');
const paymentRoutes = require('./routes/payment.routes.js');
const notificationRoutes = require('./routes/notification.routes.js');

const sendResponse = (res, statusCode, message, data = {}) => {
	return res.status(statusCode).json({
		success: statusCode >= 200 && statusCode < 300,
		message,
		data
	});
};

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

app.get('/health', (req, res) => sendResponse(res, 200, 'OK', { uptime: process.uptime() }));

app.get('/api/payment/success', (req, res) => {
	return sendResponse(res, 200, 'PayPal payment callback: success', {
		status: 'SUCCESS',
		query: req.query
	});
});

app.get('/api/payment/error', (req, res) => {
	return sendResponse(res, 200, 'PayPal payment callback: error', {
		status: 'ERROR',
		query: req.query
	});
});

app.get('/api/payment/cancel', (req, res) => {
	return sendResponse(res, 200, 'PayPal payment callback: cancel', {
		status: 'CANCEL',
		query: req.query
	});
});

app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/toys', toyRoutes);
app.use('/api/products', toyRoutes);
app.get('/api/search', getToys);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/notifications', notificationRoutes);

app.use((req, res) => sendResponse(res, 404, 'Route not found', {}));

app.use((err, req, res, next) => {
	const statusCode = Number(err?.statusCode) || 500;
	const message = err?.message || 'Internal server error';

	if (statusCode >= 500) {
		console.error(err);
	}

	return sendResponse(res, statusCode, message, err?.data || {});
});

module.exports = app;