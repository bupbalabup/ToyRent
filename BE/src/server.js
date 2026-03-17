require('dotenv/config');
const http = require('http');
const app = require('./app.js');
const connectDB = require('./config/db.js');
const { initializeSocket } = require('./socket.js');

connectDB();

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

// Create HTTP server for Socket.io
const server = http.createServer(app);

// Initialize Socket.io
initializeSocket(server);

server.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
  console.log(`WebSocket available at ws://${HOST}:${PORT}`);
});