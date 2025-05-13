// Chat utilities for doctor portal
// This file handles chat-related functions and avoids any doctor-user synchronization

async function sendChatMessage(supabase, chatRoomId, doctorId, message) {
  try {
    const timestamp = new Date().toISOString();
    
    console.log("Sending message with doctor ID as sender:", doctorId);
    
    // Giờ có thể trực tiếp sử dụng ID của bác sĩ làm sender_id
    // vì đã xóa ràng buộc khóa ngoại trong database
    const { data: messageData, error: messageError } = await supabase
      .from('chat_messages')
      .insert({
        chat_room_id: chatRoomId,
        sender_id: doctorId, // Sử dụng ID của bác sĩ làm sender_id
        doctor_id: doctorId, // Giữ trường doctor_id để tương thích ngược
        sender_type: 'doctor', // Thêm trường này nếu bạn đã thêm vào database
        message: message,
        created_at: timestamp
      })
      .select();
    
    if (messageError) throw messageError;
    
    // 2. Update the chat room without using a stored procedure
    // Get current unread count
    const { data: chatRoomData, error: getRoomError } = await supabase
      .from('chat_rooms')
      .select('unread_patient')
      .eq('id', chatRoomId)
      .single();
    
    if (getRoomError) throw getRoomError;
    
    // Increment unread count
    const currentUnreadCount = chatRoomData.unread_patient || 0;
    
    // Update chat room
    const { error: updateError } = await supabase
      .from('chat_rooms')
      .update({
        last_message: message,
        last_message_time: timestamp,
        unread_patient: currentUnreadCount + 1
      })
      .eq('id', chatRoomId);
    
    if (updateError) throw updateError;
    
    return { success: true, messageData };
  } catch (error) {
    console.error('Error sending chat message:', error);
    return { success: false, error };
  }
}

// Export functions
window.chatUtils = {
  sendChatMessage
};
