const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*', // Trong môi trường production, chỉ định chính xác các nguồn được phép
    methods: ['GET', 'POST']
  }
});

// Theo dõi người dùng đã kết nối
const connectedUsers = {};

io.on('connection', (socket) => {
  console.log('Người dùng đã kết nối:', socket.id);
  
  // Lưu thông tin người dùng từ xác thực
  const userId = socket.handshake.auth.userId;
  const userType = socket.handshake.auth.userType;
  
  if (userId) {
    connectedUsers[userId] = {
      socketId: socket.id,
      userType: userType
    };
    console.log(`${userType} với ID ${userId} đã kết nối`);
  }
  
  // Xử lý tin nhắn chat
  socket.on('chat:message', (data) => {
    console.log('Tin nhắn nhận được:', data);
    
    // Chuyển tiếp tin nhắn tới người nhận nếu họ đang kết nối
    if (connectedUsers[data.recipientId]) {
      io.to(connectedUsers[data.recipientId].socketId).emit('chat:message', data);
    }
  });
  
  // Xử lý chỉ báo đang nhập
  socket.on('chat:typing', (data) => {
    if (connectedUsers[data.recipientId]) {
      io.to(connectedUsers[data.recipientId].socketId).emit('chat:typing', data);
    }
  });
  
  // Xử lý ngắt kết nối
  socket.on('disconnect', () => {
    // Xóa khỏi danh sách người dùng đã kết nối
    for (const [key, value] of Object.entries(connectedUsers)) {
      if (value.socketId === socket.id) {
        console.log(`${value.userType} với ID ${key} đã ngắt kết nối`);
        delete connectedUsers[key];
        break;
      }
    }
  });
});

// Tạo một endpoint đơn giản để kiểm tra server hoạt động
app.get('/', (req, res) => {
  res.send('Socket.io Server đang chạy');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Socket.io server đang chạy trên cổng ${PORT}`);
});