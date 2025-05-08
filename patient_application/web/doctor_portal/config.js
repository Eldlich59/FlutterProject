// Supabase configuration
const SUPABASE_URL = 'https://cywiojhihrdkzporqblt.supabase.co'; // Your Supabase project URL
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5d2lvamhpaHJka3pwb3JxYmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MTcxMDAsImV4cCI6MjA2MDE5MzEwMH0.konPbBj9358ZJKKzVktlBmTCOAJWEvEU9fhFPHJjkSo'; // Your Supabase anon key

// Socket.io server configuration
const SOCKET_URL = 'http://localhost:3000'; // Socket.io server chạy trên localhost port 3000

// Khởi tạo Supabase client sẽ được thực hiện sau khi trang web đã load
let supabase;

// Settings for realtime subscriptions
const REALTIME_SETTINGS = {
  CHAT_ROOM_CHANNEL: 'chat_rooms',
  CHAT_MESSAGE_CHANNEL: 'chat_messages'
};

// Doctor role identifier - used to ensure only doctors can access this portal
const DOCTOR_ROLE = 'doctor';