# RentToys - PRM393 Fullstack Project

RentToys is a fullstack toy rental platform built for PRM393 using Flutter (frontend), Node.js/Express (backend), and MongoDB (database).

## Description

The system allows users to browse rentable toys, place rental orders, pay by cash or PayPal, track order history, receive notifications, and use realtime chat/socket updates. It also includes an admin dashboard for managing products, categories, orders, and users.

## Features

- User authentication (register/login, JWT)
- Product browsing and search
- Category filtering
- Cart and checkout flow
- Order creation and order history
- Payment integration:
  - Cash checkout
  - PayPal checkout (approval URL + capture/sync)
- Realtime events with Socket.IO:
  - Order updates
  - Payment updates
  - Notifications
  - Chat messages and typing indicators
- Admin dashboard:
  - Overview stats
  - Product management
  - Category management
  - Order management
  - User statistics

## Tech Stack

- Frontend: Flutter, Provider, Dio, Socket.IO client, WebView
- Backend: Node.js, Express, Mongoose, JWT, Socket.IO
- Database: MongoDB
- Payment: PayPal Checkout API

## Project Structure

- `FE/` Flutter application
- `BE/` Node.js API server

## Run Instructions

### 1) Start Backend

```bash
cd BE
npm install
npm start
```

Backend default URL: `http://127.0.0.1:5000`

### 2) Start Frontend

```bash
cd FE
flutter pub get
flutter run -d chrome
```

Frontend uses API config in `FE/lib/config/api_config.dart`.

## Test Account

Use an existing seeded account from MongoDB, or create one via register endpoint/UI.

Example test credentials (if already created):

- Email: `test@example.com`
- Password: `123456`

If unavailable, register a new account from the app login/register flow.

## API List (Core)

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`

### Products/Categories

- `GET /api/products`
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

## Notes

- Ensure MongoDB is running locally at `mongodb://127.0.0.1:27017/toyrental` (or set env in backend).
- PayPal sandbox credentials must be configured in backend environment variables for full PayPal flow.
