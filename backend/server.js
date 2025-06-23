
const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*", // Allow all origins for mobile testing
    credentials: true
  }
});

// Middleware
app.use(express.json());
app.use(cookieParser());
app.use(cors({
  origin: true,
  credentials: true
}));

// In-memory storage (replace with database in production)
const users = [
  { id: 1, username: 'user1', password: bcrypt.hashSync('password1', 10), name: 'Demo User 1' },
  { id: 2, username: 'user2', password: bcrypt.hashSync('password2', 10), name: 'Demo User 2' },
  { id: 3, username: 'user3', password: bcrypt.hashSync('password3', 10), name: 'Demo User 3' },
  { id: 4, username: 'user4', password: bcrypt.hashSync('password4', 10), name: 'Demo User 4' }
];

const messages = [];
const activeUsers = new Map(); // socketId -> userId
const userSockets = new Map(); // userId -> socketId

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Flutter Chat Server is running!', 
    timestamp: new Date().toISOString(),
    activeUsers: activeUsers.size
  });
});

// Helper function to verify JWT from cookie
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
};

// REST API Routes

// Login endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    console.log(`Login attempt for: ${username}`);
    
    const user = users.find(u => u.username === username);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Create JWT token
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    // Set HTTP-only cookie
    res.cookie('auth_token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production', // Only secure in production
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
    });
    
    console.log(`✅ Login successful for: ${username}`);
    
    res.json({
      success: true,
      user: {
        id: user.id,
        username: user.username,
        name: user.name
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Logout endpoint
app.post('/api/logout', (req, res) => {
  res.clearCookie('auth_token');
  res.json({ success: true });
});

// Get current user endpoint
app.get('/api/me', (req, res) => {
  const token = req.cookies.auth_token;
  
  if (!token) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  const user = users.find(u => u.id === decoded.userId);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  res.json({
    id: user.id,
    username: user.username,
    name: user.name
  });
});

// Get all users (for chat list)
app.get('/api/users', (req, res) => {
  const token = req.cookies.auth_token;
  
  if (!token) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  // Return all users except the current user
  const otherUsers = users
    .filter(u => u.id !== decoded.userId)
    .map(u => ({
      id: u.id,
      username: u.username,
      name: u.name,
      online: userSockets.has(u.id)
    }));
  
  res.json(otherUsers);
});

// Get chat history between two users
app.get('/api/messages/:userId', (req, res) => {
  const token = req.cookies.auth_token;
  
  if (!token) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  const otherUserId = parseInt(req.params.userId);
  const userMessages = messages.filter(msg => 
    (msg.senderId === decoded.userId && msg.receiverId === otherUserId) ||
    (msg.senderId === otherUserId && msg.receiverId === decoded.userId)
  );
  
  res.json(userMessages);
});

// WebSocket handling
io.use((socket, next) => {
  const cookieString = socket.handshake.headers.cookie || '';
  const cookies = {};
  
  cookieString.split(';').forEach(cookie => {
    const [key, value] = cookie.trim().split('=');
    if (key && value) {
      cookies[key] = value;
    }
  });
  
  const token = cookies.auth_token;
  if (!token) {
    return next(new Error('Authentication error'));
  }
  
  const decoded = verifyToken(token);
  if (!decoded) {
    return next(new Error('Invalid token'));
  }
  
  socket.userId = decoded.userId;
  next();
});

io.on('connection', (socket) => {
  console.log('✅ User connected:', socket.userId);
  
  // Store socket connection
  activeUsers.set(socket.id, socket.userId);
  userSockets.set(socket.userId, socket.id);
  
  // Notify all users about online status
  io.emit('user_status', {
    userId: socket.userId,
    online: true
  });
  
  // Handle private messages
  socket.on('send_message', (data) => {
    const { receiverId, text } = data;
    
    console.log(`📨 Message from ${socket.userId} to ${receiverId}: ${text}`);
    
    const message = {
      id: Date.now(),
      senderId: socket.userId,
      receiverId: receiverId,
      text: text,
      timestamp: new Date().toISOString()
    };
    
    // Store message
    messages.push(message);
    
    // Send to receiver if online
    const receiverSocketId = userSockets.get(receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('new_message', message);
    }
    
    // Send back to sender for confirmation
    socket.emit('message_sent', message);
  });
  
  // Handle typing indicators
  socket.on('typing', (data) => {
    const { receiverId, isTyping } = data;
    const receiverSocketId = userSockets.get(receiverId);
    
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('user_typing', {
        userId: socket.userId,
        isTyping: isTyping
      });
    }
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('❌ User disconnected:', socket.userId);
    
    activeUsers.delete(socket.id);
    userSockets.delete(socket.userId);
    
    // Notify all users about offline status
    io.emit('user_status', {
      userId: socket.userId,
      online: false
    });
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log('📱 Demo users for testing:');
  console.log('  Username: user1, Password: password1');
  console.log('  Username: user2, Password: password2');
  console.log('  Username: user3, Password: password3');
  console.log('  Username: user4, Password: password4');
});