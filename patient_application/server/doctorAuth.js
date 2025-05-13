// Doctor authentication utilities
const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client (get these values from environment variables in a real app)
const supabaseUrl = process.env.SUPABASE_URL || 'https://cywiojhihrdkzporqblt.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5d2lvamhpaHJka3pwb3JxYmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MTcxMDAsImV4cCI6MjA2MDE5MzEwMH0.konPbBj9358ZJKKzVktlBmTCOAJWEvEU9fhFPHJjkSo';
const supabase = createClient(supabaseUrl, supabaseKey);

// Function to validate a doctor without inserting into users table
async function validateDoctor(doctorId) {
  try {
    console.log(`Validating doctor with ID: ${doctorId}`);
    
    // Check if doctor exists in doctors table
    const { data, error } = await supabase
      .from('doctors')
      .select('id, name, specialty')
      .eq('id', doctorId)
      .single();
    
    if (error) {
      console.log(`Error finding doctor: ${error.message}`);
      throw error;
    }
    
    console.log(`Doctor validated successfully: ${data?.name || 'Unknown'}`);
    
    // Return doctor data if found
    return { success: true, doctor: data };
  } catch (error) {
    console.error('Error validating doctor:', error);
    return { success: false, error };
  }
}

// Function to get patient ID from chat room
async function getPatientIdFromChatRoom(chatRoomId) {
  try {
    console.log(`Getting patient ID for chat room: ${chatRoomId}`);
    
    const { data, error } = await supabase
      .from('chat_rooms')
      .select('patient_id')
      .eq('id', chatRoomId)
      .single();
    
    if (error) {
      console.log(`Error finding chat room: ${error.message}`);
      throw error;
    }
    
    if (!data || !data.patient_id) {
      throw new Error('Patient ID not found in chat room');
    }
    
    console.log(`Found patient ID: ${data.patient_id} for chat room ${chatRoomId}`);
    return { success: true, patientId: data.patient_id };
  } catch (error) {
    console.error('Error getting patient ID:', error);
    return { success: false, error };
  }
}

// Export the functions properly
module.exports = {
  validateDoctor,
  getPatientIdFromChatRoom
};
