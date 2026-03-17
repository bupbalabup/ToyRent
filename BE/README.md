# RentToys Backend API

Node.js + Express + MongoDB backend for RentToys.

## Description

This backend provides authentication, product/category data, rental order processing, payment processing (cash and PayPal), notifications, chat, and realtime socket events.

## Features

- JWT authentication and authorization
- Mongoose models for users, toys, categories, orders, payments, notifications, rental schedules
- REST APIs with unified response format: `success`, `message`, `data`
- Order lifecycle management
- Payment processing:
  - Cash payment completion
  - PayPal checkout/capture/sync
- Realtime events using Socket.IO

## Tech Stack

- Node.js
- Express
- MongoDB + Mongoose
- JWT
- Socket.IO

## Setup

### 1) Install dependencies

```bash
npm install
```

### 2) Configure environment

Create `.env` with at least:

```env
PORT=5000
HOST=0.0.0.0
MONGODB_URI=mongodb://127.0.0.1:27017/toyrental
JWT_SECRET=your_jwt_secret

PAYPAL_CLIENT_ID=your_sandbox_client_id
PAYPAL_CLIENT_SECRET=your_sandbox_client_secret
PAYPAL_BASE_URL=https://api-m.sandbox.paypal.com
PAYPAL_SUCCESS_URL=http://127.0.0.1:5000/api/payment/success
PAYPAL_CANCEL_URL=http://127.0.0.1:5000/api/payment/cancel
```

### 3) Run server

```bash
npm start
```

Server starts on `http://127.0.0.1:5000`.

## API List

### Health

- `GET /health`

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`

### Products and Categories

- `GET /api/products`
- `GET /api/toys`
- `GET /api/categories`
- `GET /api/search`

### Orders

- `POST /api/orders`
- `GET /api/orders/me`
- `GET /api/orders/:id`
- `PATCH /api/orders/:id/status` (admin)
- `GET /api/orders/admin/all` (admin)

### Payments

- `POST /api/payments/checkout`
- `GET /api/payments/paypal/orders/:orderId/sync?paypalOrderId=...`
- `POST /api/payments/paypal/orders/:orderId/capture`
- `POST /api/payments/orders/:orderId/expire`

### Notifications

- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PATCH /api/notifications/:id/read`
- `PATCH /api/notifications/read-all`

### Chat

- `GET /api/chat`
- `GET /api/chat/:userId`
- `POST /api/chat`
- `PATCH /api/chat/:userId/read`

## Test Account

Use seeded MongoDB users or register a new user via API/UI.

## Response Format

All endpoints return:

```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```
