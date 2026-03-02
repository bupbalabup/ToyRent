import http from 'http';
import app from './app.js';
import env from './config/env.js';
import connectDB from './config/db.js';

const startServer = async () => {
  await connectDB();

  const server = http.createServer(app);

  server.listen(env.port, () => {
    process.stdout.write(`Server running on port ${env.port}\n`);
  });

  const gracefulShutdown = async () => {
    server.close(() => process.exit(0));
  };

  process.on('SIGINT', gracefulShutdown);
  process.on('SIGTERM', gracefulShutdown);
};

startServer().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});
