// DOM elements
const connectionStatus = document.getElementById('connection-status');
const doctorNameElement = document.getElementById('doctor-name');
const searchPatientInput = document.getElementById('search-patient');
const waitingPatientsList = document.getElementById('waiting-patients');
const allPatientsList = document.getElementById('all-patients');
const noChatSelected = document.getElementById('no-chat-selected');
const chatInterface = document.getElementById('chat-interface');
const messageContainer = document.getElementById('message-container');
const messageForm = document.getElementById('message-form');
const messageInput = document.getElementById('message-input');
const patientName = document.getElementById('patient-name');
const patientInfo = document.getElementById('patient-info');
const patientAvatar = document.getElementById('patient-avatar');
const viewProfileBtn = document.getElementById('view-profile');
const viewMedicalRecordsBtn = document.getElementById('view-medical-records');
const patientProfileModal = new bootstrap.Modal(document.getElementById('patientProfileModal'));
const patientProfileContent = document.getElementById('patient-profile-content');

// Doctor selection elements
const doctorSelectionModal = new bootstrap.Modal(document.getElementById('doctorSelectionModal'));
const doctorListElement = document.getElementById('doctor-list');
const selectedDoctorBar = document.getElementById('selected-doctor-bar');
const selectedDoctorAvatar = document.getElementById('selected-doctor-avatar');
const selectedDoctorName = document.getElementById('selected-doctor-name');
const selectedDoctorSpecialty = document.getElementById('selected-doctor-specialty');
const changeDoctorBtn = document.getElementById('change-doctor');

// Application state
let socket = null;
let selectedChatRoom = null;
let currentPatient = null;
let chatRooms = [];
let patients = {};
let messages = {};
let selectedDoctor = null;
let doctors = [];

// Initialize the application
document.addEventListener('DOMContentLoaded', initializeApp);

function initializeApp() {
    // Khởi tạo Supabase client
    try {
        supabase = supabaseClient.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        console.log('Supabase client initialized successfully');
    } catch (error) {
        console.error('Error initializing Supabase client:', error);
    }
    
    // Show doctor selection modal first
    showDoctorSelectionModal();
    attachEventListeners();
}

function showDoctorSelectionModal() {
    // Get all doctors from database
    loadDoctors().then(() => {
        // Show the modal for doctor selection
        doctorSelectionModal.show();
    });
}

function attachEventListeners() {
    // Patient search
    searchPatientInput.addEventListener('input', handlePatientSearch);
    
    // Message form submission
    messageForm.addEventListener('submit', handleSendMessage);
    
    // View profile button
    viewProfileBtn.addEventListener('click', handleViewProfile);
    
    // View medical records button
    viewMedicalRecordsBtn.addEventListener('click', handleViewMedicalRecords);
    
    // Change doctor button
    changeDoctorBtn.addEventListener('click', function() {
        selectedDoctor = null;
        selectedDoctorBar.classList.add('d-none');
        document.body.classList.remove('has-doctor-bar');
        showDoctorSelectionModal();
    });
}

// Doctor Loading Functions
async function loadDoctors() {
    try {
        // Get all doctors from the database
        const { data, error } = await supabase
            .from('doctors')
            .select('*')
            .order('name', { ascending: true });
        
        if (error) throw error;
        
        doctors = data || [];
        
        renderDoctorList();
    } catch (error) {
        console.error('Error loading doctors:', error);
        doctorListElement.innerHTML = `
            <div class="alert alert-danger">
                Error loading doctors. Please refresh the page and try again.
            </div>
        `;
    }
}

function renderDoctorList() {
    doctorListElement.innerHTML = '';
    
    if (doctors.length === 0) {
        doctorListElement.innerHTML = `
            <div class="alert alert-info">
                No doctors found in the database. Please add doctors to the system.
            </div>
        `;
        return;
    }
    
    doctors.forEach(doctor => {
        const doctorItem = createDoctorListItem(doctor);
        doctorListElement.appendChild(doctorItem);
    });
}

function createDoctorListItem(doctor) {
    const div = document.createElement('div');
    div.className = 'doctor-item';
    
    // Check if this doctor is the selected one
    if (selectedDoctor && selectedDoctor.id === doctor.id) {
        div.classList.add('selected');
    }
    
    div.innerHTML = `
        <img src="${doctor.avatar_url || '../images/default_avatar.png'}" alt="${doctor.name}" class="avatar">
        <div class="doctor-name">${doctor.name}</div>
        <div class="doctor-specialty">${doctor.specialty || 'Đa khoa'}</div>
        <button class="doctor-select-btn">${selectedDoctor && selectedDoctor.id === doctor.id ? 'Đã chọn' : 'Chọn bác sĩ'}</button>
    `;
    
    div.addEventListener('click', () => {
        selectDoctor(doctor);
    });
    
    return div;
}

function selectDoctor(doctor) {
    // Set the selected doctor
    selectedDoctor = doctor;
    
    // Update UI to show selected doctor
    document.querySelectorAll('.doctor-item').forEach(item => {
        item.classList.remove('selected');
    });
    
    // Find the doctor item and add selected class
    const doctorItems = document.querySelectorAll('.doctor-item');
    for (const item of doctorItems) {
        const nameElement = item.querySelector('.doctor-name');
        if (nameElement && nameElement.textContent === doctor.name) {
            item.classList.add('selected');
        }
    }
    
    // Hide the doctor selection modal
    doctorSelectionModal.hide();
    
    // Ensure doctor exists in the users table before continuing
    ensureDoctorInUsersTable(doctor).then(() => {
        // Show selected doctor info bar
        updateDoctorBar();
        
        // Continue with application initialization
        handleDoctorSelection();
    }).catch(error => {
        console.error('Error ensuring doctor in users table:', error);
        // Still continue with the application even if synchronization fails
        updateDoctorBar();
        handleDoctorSelection();
    });
}

// Function to ensure that the doctor exists in the users table for authentication purposes
async function ensureDoctorInUsersTable(doctor) {
    try {
        // First check if the doctor already exists in the users table
        const { data, error } = await supabase
            .from('users')
            .select('id')
            .eq('id', doctor.id)
            .maybeSingle();
        
        // If doctor exists in users table, we're done
        if (data) {
            console.log('Doctor already exists in users table');
            return;
        }
        
        // If user table doesn't exist or doctor isn't in it, create the entry
        const userData = {
            id: doctor.id,
            email: doctor.email || `doctor_${doctor.id}@example.com`,
            doctor_id: doctor.id,
            user_type: 'doctor',
            created_at: new Date().toISOString(),
            display_name: doctor.name
        };
        
        // Insert the doctor into the users table
        const { error: insertError } = await supabase
            .from('users')
            .upsert([userData]);
        
        if (insertError) throw insertError;
        
        console.log('Successfully added doctor to users table');
    } catch (error) {
        console.error('Error ensuring doctor in users table:', error);
        throw error; // Re-throw the error to be handled by the caller
    }
}

function updateDoctorBar() {
    if (selectedDoctor) {
        // Update the doctor bar info
        selectedDoctorName.textContent = selectedDoctor.name;
        selectedDoctorSpecialty.textContent = selectedDoctor.specialty || 'Đa khoa';
        
        if (selectedDoctor.avatar_url) {
            selectedDoctorAvatar.src = selectedDoctor.avatar_url;
        } else {
            selectedDoctorAvatar.src = '../images/default_avatar.png';
        }
        
        // Show the doctor bar
        selectedDoctorBar.classList.remove('d-none');
        document.body.classList.add('has-doctor-bar');
        
        // Update the doctor name in the sidebar
        doctorNameElement.textContent = `Dr. ${selectedDoctor.name}`;
    } else {
        // Hide the doctor bar
        selectedDoctorBar.classList.add('d-none');
        document.body.classList.remove('has-doctor-bar');
    }
}

function handleDoctorSelection() {
    // Connect to Socket.io server
    connectSocket();
    
    // Set up Supabase real-time subscriptions
    setupSupabaseSubscriptions();
    
    // Load initial data
    loadInitialData();
}

// Socket.io Functions
function connectSocket() {
    try {
        // Connect to Socket.io server
        socket = io(SOCKET_URL, {
            auth: {
                userId: selectedDoctor.id,
                userType: DOCTOR_ROLE
            }
        });
        
        // Socket connection events
        socket.on('connect', handleSocketConnect);
        socket.on('disconnect', handleSocketDisconnect);
        socket.on('error', handleSocketError);
        socket.on('chat:message', handleIncomingMessage);
        socket.on('chat:typing', handlePatientTyping);
    } catch (error) {
        console.error('Socket connection error:', error);
        connectionStatus.textContent = 'Connection Error';
        connectionStatus.className = 'badge bg-danger';
    }
}

function handleSocketConnect() {
    connectionStatus.textContent = 'Online';
    connectionStatus.className = 'badge bg-success';
}

function handleSocketDisconnect() {
    connectionStatus.textContent = 'Offline';
    connectionStatus.className = 'badge bg-secondary';
}

function handleSocketError(error) {
    console.error('Socket error:', error);
    connectionStatus.textContent = 'Error';
    connectionStatus.className = 'badge bg-danger';
}

// Define handleIncomingMessage function to fix the error
function handleIncomingMessage(data) {
    if (!data || !data.chatRoomId) return;
    
    // Handle incoming message from socket
    const message = {
        id: data.messageId || 'socket-' + Date.now(),
        chat_room_id: data.chatRoomId,
        sender_id: data.senderId,
        message: data.message,
        created_at: data.timestamp || new Date().toISOString()
    };
    
    // Add message to local storage
    handleNewMessage(message);
    
    // Update chat room with latest message
    updateChatRoom({
        id: data.chatRoomId,
        last_message: data.message,
        last_message_time: data.timestamp || new Date().toISOString(),
        unread_doctor: data.senderId !== selectedDoctor.id ? 1 : 0
    });
}

// Supabase Subscriptions
function setupSupabaseSubscriptions() {
    try {
        // Subscribe to chat rooms changes - using the proper Supabase realtime client approach
        const chatRoomSubscription = supabase
            .channel(REALTIME_SETTINGS.CHAT_ROOM_CHANNEL)
            .on('postgres_changes', {
                event: '*',
                schema: 'public',
                table: REALTIME_SETTINGS.CHAT_ROOM_CHANNEL
            }, handleChatRoomChange)
            .subscribe();
        
        console.log('Successfully subscribed to chat room changes');
    } catch (error) {
        console.error('Error setting up Supabase subscriptions:', error);
    }
    
    // Will set up message subscriptions for individual chat rooms when they are selected
}

function setupMessageSubscription(chatRoomId) {
    // Unsubscribe from previous subscription if any
    try {
        supabase.removeAllChannels();
        
        // Subscribe to new messages for this chat room using the proper method
        const messageSubscription = supabase
            .channel(`messages-${chatRoomId}`)
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: REALTIME_SETTINGS.CHAT_MESSAGE_CHANNEL,
                filter: `chat_room_id=eq.${chatRoomId}`
            }, payload => {
                handleNewMessage(payload.new);
            })
            .subscribe();
            
        console.log(`Successfully subscribed to messages for chat room ${chatRoomId}`);
    } catch (error) {
        console.error('Error setting up message subscription:', error);
    }
}

// Data Loading Functions
async function loadInitialData() {
    try {
        await Promise.all([
            loadChatRoomsForSelectedDoctor(),
            loadPatients()
        ]);
        
        renderChatRooms();
    } catch (error) {
        console.error('Error loading initial data:', error);
    }
}

async function loadChatRoomsForSelectedDoctor() {
    const { data, error } = await supabase
        .from('chat_rooms')
        .select('*')
        .eq('doctor_id', selectedDoctor.id)
        .order('last_message_time', { ascending: false });
    
    if (error) throw error;
    
    chatRooms = data || [];
}

async function loadPatients() {
    // Get all unique patient IDs from chat rooms
    const patientIds = [...new Set(chatRooms.map(room => room.patient_id))];
    
    if (patientIds.length === 0) return;
    
    const { data, error } = await supabase
        .from('patients')
        .select('*')
        .in('id', patientIds);
    
    if (error) throw error;
    
    // Convert to an object with ID as key for easy access
    patients = (data || []).reduce((acc, patient) => {
        acc[patient.id] = patient;
        return acc;
    }, {});
}

async function loadMessages(chatRoomId) {
    const { data, error } = await supabase
        .from('chat_messages')
        .select('*')
        .eq('chat_room_id', chatRoomId)
        .order('created_at', { ascending: true });
    
    if (error) throw error;
    
    messages[chatRoomId] = data || [];
}

// UI Update Functions
function renderChatRooms() {
    renderWaitingPatients();
    renderAllPatients();
}

function renderWaitingPatients() {
    const waitingRooms = chatRooms.filter(room => room.unread_doctor > 0);
    waitingPatientsList.innerHTML = '';
    
    if (waitingRooms.length === 0) {
        waitingPatientsList.innerHTML = '<div class="p-3 text-center text-muted">Không có bệnh nhân đang chờ</div>';
        return;
    }
    
    waitingRooms.forEach(room => {
        const patient = patients[room.patient_id];
        if (!patient) return;
        
        const patientItem = createPatientListItem(patient, room, true);
        waitingPatientsList.appendChild(patientItem);
    });
}

function renderAllPatients() {
    allPatientsList.innerHTML = '';
    
    if (chatRooms.length === 0) {
        allPatientsList.innerHTML = '<div class="p-3 text-center text-muted">Không có cuộc trò chuyện nào</div>';
        return;
    }
    
    chatRooms.forEach(room => {
        const patient = patients[room.patient_id];
        if (!patient) return;
        
        const patientItem = createPatientListItem(patient, room);
        allPatientsList.appendChild(patientItem);
    });
}

function createPatientListItem(patient, chatRoom, isWaiting = false) {
    const div = document.createElement('div');
    div.className = 'patient-item d-flex align-items-center justify-content-between';
    if (selectedChatRoom === chatRoom.id) {
        div.classList.add('active');
    }
    
    const lastMessageTime = new Date(chatRoom.last_message_time);
    const timeString = formatTime(lastMessageTime);
    
    div.innerHTML = `
        <div class="d-flex align-items-center">
            <img src="${patient.avatar_url || '../images/default_avatar.png'}" alt="${patient.name}" class="avatar">
            <div class="patient-info">
                <div class="patient-name">${patient.name}</div>
                <div class="last-message">${chatRoom.last_message || 'Bắt đầu cuộc trò chuyện'}</div>
            </div>
        </div>
        <div class="d-flex flex-column align-items-end">
            <div class="message-time">${timeString}</div>
            ${chatRoom.unread_doctor > 0 ? `<div class="unread-badge">${chatRoom.unread_doctor}</div>` : ''}
        </div>
    `;
    
    div.addEventListener('click', () => selectChatRoom(chatRoom.id, patient));
    
    return div;
}

function renderMessages(chatRoomId) {
    messageContainer.innerHTML = '';
    
    const chatMessages = messages[chatRoomId] || [];
    
    if (chatMessages.length === 0) {
        messageContainer.innerHTML = '<div class="text-center text-muted my-4">Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện.</div>';
        return;
    }
    
    chatMessages.forEach(msg => {
        const isFromDoctor = msg.sender_id === selectedDoctor.id;
        const messageDiv = createMessageElement(msg, isFromDoctor);
        messageContainer.appendChild(messageDiv);
    });
    
    // Scroll to bottom
    messageContainer.scrollTop = messageContainer.scrollHeight;
}

function createMessageElement(message, isFromDoctor) {
    const div = document.createElement('div');
    div.className = `message ${isFromDoctor ? 'message-sent' : 'message-received'}`;
    
    const messageTime = new Date(message.created_at);
    const timeString = formatTime(messageTime, true);
    
    div.innerHTML = `
        <div>${message.message}</div>
        <div class="message-time">${timeString}</div>
    `;
    
    return div;
}

function formatTime(date, includeSeconds = false) {
    if (isToday(date)) {
        return includeSeconds 
            ? `${date.getHours()}:${padZero(date.getMinutes())}:${padZero(date.getSeconds())}`
            : `${date.getHours()}:${padZero(date.getMinutes())}`;
    } else {
        return `${date.getDate()}/${date.getMonth() + 1} ${date.getHours()}:${padZero(date.getMinutes())}`;
    }
}

function isToday(date) {
    const today = new Date();
    return date.getDate() === today.getDate() &&
        date.getMonth() === today.getMonth() &&
        date.getFullYear() === today.getFullYear();
}

function padZero(num) {
    return num.toString().padStart(2, '0');
}

// Event Handlers
async function selectChatRoom(chatRoomId, patient) {
    // Set current selections
    selectedChatRoom = chatRoomId;
    currentPatient = patient;
    
    // Update UI
    updateChatHeader(patient);
    showChatInterface();
    
    // Mark messages as read
    await markAsRead(chatRoomId);
    
    // Load messages for this chat room
    if (!messages[chatRoomId]) {
        await loadMessages(chatRoomId);
    }
    
    // Setup real-time subscription for this chat room
    setupMessageSubscription(chatRoomId);
    
    // Render messages
    renderMessages(chatRoomId);
    
    // Update chat room lists (to remove unread badge)
    renderChatRooms();
    
    // Add active class to selected patient
    document.querySelectorAll('.patient-item').forEach(item => {
        item.classList.remove('active');
    });
    document.querySelectorAll('.patient-item').forEach(item => {
        if (item.querySelector('.patient-name').textContent === patient.name) {
            item.classList.add('active');
        }
    });
}

function updateChatHeader(patient) {
    patientName.textContent = patient.name;
    patientInfo.textContent = patient.email || '';
    if (patient.avatar_url) {
        patientAvatar.src = patient.avatar_url;
    } else {
        patientAvatar.src = '../images/default_avatar.png';
    }
}

function showChatInterface() {
    noChatSelected.classList.add('d-none');
    chatInterface.classList.remove('d-none');
}

async function markAsRead(chatRoomId) {
    try {
        const { error } = await supabase
            .from('chat_rooms')
            .update({ unread_doctor: 0 })
            .eq('id', chatRoomId);
        
        if (error) throw error;
        
        // Update local state
        const roomIndex = chatRooms.findIndex(r => r.id === chatRoomId);
        if (roomIndex >= 0) {
            chatRooms[roomIndex].unread_doctor = 0;
        }
    } catch (error) {
        console.error('Error marking messages as read:', error);
    }
}

async function handleSendMessage(event) {
    event.preventDefault();
    
    if (!selectedChatRoom || !currentPatient) return;
    
    const messageText = messageInput.value.trim();
    if (!messageText) return;
    
    // Clear input
    messageInput.value = '';
    
    try {
        const timestamp = new Date().toISOString();
        
        // First add to local UI for immediate feedback
        const newMessage = {
            id: 'temp-' + Date.now(),
            chat_room_id: selectedChatRoom,
            sender_id: selectedDoctor.id,
            message: messageText,
            created_at: timestamp
        };
        
        // Add to local messages
        if (!messages[selectedChatRoom]) messages[selectedChatRoom] = [];
        messages[selectedChatRoom].push(newMessage);
        
        // Update UI
        renderMessages(selectedChatRoom);
        
        // Update chat room with latest message
        await updateChatRoomWithMessage(selectedChatRoom, messageText, timestamp);
        
        // Send to Supabase
        const { data, error } = await supabase
            .from('chat_messages')
            .insert([{
                chat_room_id: selectedChatRoom,
                sender_id: selectedDoctor.id,
                message: messageText,
                created_at: timestamp
            }]);
        
        if (error) throw error;
        
        // Emit through Socket.io to notify the patient in real-time
        if (socket && socket.connected) {
            socket.emit('chat:message', {
                chatRoomId: selectedChatRoom,
                message: messageText,
                senderId: selectedDoctor.id,
                recipientId: currentPatient.id,
                timestamp: timestamp
            });
        }
    } catch (error) {
        console.error('Error sending message:', error);
    }
}

async function updateChatRoomWithMessage(chatRoomId, message, timestamp) {
    try {
        const { error } = await supabase
            .from('chat_rooms')
            .update({
                last_message: message,
                last_message_time: timestamp,
                unread_patient: supabase.sql('unread_patient + 1')
            })
            .eq('id', chatRoomId);
        
        if (error) throw error;
        
        // Update local state
        const roomIndex = chatRooms.findIndex(r => r.id === chatRoomId);
        if (roomIndex >= 0) {
            chatRooms[roomIndex].last_message = message;
            chatRooms[roomIndex].last_message_time = timestamp;
            chatRooms[roomIndex].unread_patient = (chatRooms[roomIndex].unread_patient || 0) + 1;
        }
    } catch (error) {
        console.error('Error updating chat room:', error);
    }
}

function handlePatientSearch(event) {
    const searchTerm = event.target.value.toLowerCase();
    
    // Filter chat rooms by patient name
    document.querySelectorAll('.patient-item').forEach(item => {
        const patientName = item.querySelector('.patient-name').textContent.toLowerCase();
        if (patientName.includes(searchTerm)) {
            item.style.display = '';
        } else {
            item.style.display = 'none';
        }
    });
}

function handleChatRoomChange(payload) {
    if (!payload) return;
    
    if (payload.eventType === 'UPDATE') {
        updateChatRoom(payload.new);
    } else if (payload.eventType === 'INSERT') {
        addNewChatRoom(payload.new);
    }
}

function updateChatRoom(updatedRoom) {
    // Find and update the chat room in our local state
    const index = chatRooms.findIndex(room => room.id === updatedRoom.id);
    
    if (index >= 0) {
        chatRooms[index] = {...chatRooms[index], ...updatedRoom};
    } else {
        chatRooms.push(updatedRoom);
    }
    
    // If this room doesn't have a patient loaded, load it
    if (updatedRoom.patient_id && !patients[updatedRoom.patient_id]) {
        loadPatientInfo(updatedRoom.patient_id);
    }
    
    // Update UI
    renderChatRooms();
    
    // If this is the selected room, update messages if there's a new one
    if (selectedChatRoom === updatedRoom.id && updatedRoom.unread_doctor > 0) {
        // Reload messages
        loadMessages(updatedRoom.id).then(() => {
            renderMessages(updatedRoom.id);
            markAsRead(updatedRoom.id);
        });
    }
}

function addNewChatRoom(newRoom) {
    // Check if this room is for the current doctor
    if (newRoom.doctor_id !== selectedDoctor.id) return;
    
    // Add to our local state
    chatRooms.push(newRoom);
    
    // Load patient info if needed
    if (!patients[newRoom.patient_id]) {
        loadPatientInfo(newRoom.patient_id);
    }
    
    // Update UI
    renderChatRooms();
}

async function loadPatientInfo(patientId) {
    try {
        const { data, error } = await supabase
            .from('patients')
            .select('*')
            .eq('id', patientId)
            .single();
        
        if (error) throw error;
        
        if (data) {
            patients[patientId] = data;
            renderChatRooms();
        }
    } catch (error) {
        console.error(`Error loading patient info for ID ${patientId}:`, error);
    }
}

function handleNewMessage(message) {
    // Add message to local state
    if (!messages[message.chat_room_id]) {
        messages[message.chat_room_id] = [];
    }
    
    messages[message.chat_room_id].push(message);
    
    // If this is for the currently selected chat, render it
    if (selectedChatRoom === message.chat_room_id) {
        renderMessages(message.chat_room_id);
    }
}

function handlePatientTyping(data) {
    if (!data || !data.chatRoomId || data.chatRoomId !== selectedChatRoom) return;
    
    // Show typing indicator
    showTypingIndicator();
    
    // Clear previous timeout if exists
    if (window.typingTimeout) {
        clearTimeout(window.typingTimeout);
    }
    
    // Set timeout to hide indicator after 3 seconds
    window.typingTimeout = setTimeout(hideTypingIndicator, 3000);
}

function showTypingIndicator() {
    // Remove existing typing indicator
    hideTypingIndicator();
    
    // Add new typing indicator
    const typingDiv = document.createElement('div');
    typingDiv.id = 'typing-indicator';
    typingDiv.className = 'message message-received';
    typingDiv.innerHTML = '<div>Bệnh nhân đang nhập...</div>';
    
    messageContainer.appendChild(typingDiv);
    messageContainer.scrollTop = messageContainer.scrollHeight;
}

function hideTypingIndicator() {
    const indicator = document.getElementById('typing-indicator');
    if (indicator) {
        indicator.remove();
    }
}

async function handleViewProfile() {
    if (!currentPatient) return;
    
    patientProfileContent.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"></div></div>';
    patientProfileModal.show();
    
    try {
        // Get additional patient info from the patients table if needed
        const { data, error } = await supabase
            .from('patients')
            .select('*, medical_records:medical_records(*)')
            .eq('id', currentPatient.id)
            .single();
        
        if (error) throw error;
        
        // Populate patient profile modal
        patientProfileContent.innerHTML = `
            <div class="text-center mb-4">
                <img src="${data.avatar_url || '../images/default_avatar.png'}" alt="${data.name}" 
                     class="rounded-circle" style="width: 100px; height: 100px; object-fit: cover;">
                <h4 class="mt-2">${data.name}</h4>
                <p class="text-muted">${data.email || 'No email provided'}</p>
            </div>
            
            <div class="patient-details">
                <p><strong>Tuổi:</strong> ${data.age || 'Không có thông tin'}</p>
                <p><strong>Giới tính:</strong> ${formatGender(data.gender) || 'Không có thông tin'}</p>
                <p><strong>Địa chỉ:</strong> ${data.address || 'Không có thông tin'}</p>
                <p><strong>Số điện thoại:</strong> ${data.phone || 'Không có thông tin'}</p>
                <p><strong>Nhóm máu:</strong> ${data.blood_type || 'Không có thông tin'}</p>
                <p><strong>Tiền sử bệnh:</strong> ${data.medical_history || 'Không có thông tin'}</p>
                <p><strong>Dị ứng:</strong> ${data.allergies || 'Không có'}</p>
            </div>
        `;
    } catch (error) {
        console.error('Error loading patient profile:', error);
        patientProfileContent.innerHTML = `<div class="alert alert-danger">Error loading patient profile: ${error.message}</div>`;
    }
}

function formatGender(gender) {
    if (!gender) return null;
    
    const genderMap = {
        'male': 'Nam',
        'female': 'Nữ',
        'other': 'Khác'
    };
    
    return genderMap[gender.toLowerCase()] || gender;
}

async function handleViewMedicalRecords() {
    if (!currentPatient) return;
    
    patientProfileContent.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"></div></div>';
    patientProfileModal.show();
    
    try {
        // Get medical records for this patient
        const { data, error } = await supabase
            .from('medical_records')
            .select('*')
            .eq('patient_id', currentPatient.id)
            .order('record_date', { ascending: false });
        
        if (error) throw error;
        
        if (data && data.length > 0) {
            let recordsHtml = '<h4>Hồ sơ y tế</h4><div class="list-group">';
            
            data.forEach(record => {
                recordsHtml += `
                    <div class="list-group-item">
                        <div class="d-flex w-100 justify-content-between">
                            <h5 class="mb-1">${record.diagnosis || 'Khám tổng quát'}</h5>
                            <small>${formatDate(record.record_date)}</small>
                        </div>
                        <p class="mb-1">${record.description || 'Không có mô tả'}</p>
                        <small>Bác sĩ: ${record.doctor_name || 'Không có thông tin'}</small>
                    </div>
                `;
            });
            
            recordsHtml += '</div>';
            patientProfileContent.innerHTML = recordsHtml;
        } else {
            patientProfileContent.innerHTML = '<div class="alert alert-info">Bệnh nhân này chưa có hồ sơ y tế</div>';
        }
    } catch (error) {
        console.error('Error loading medical records:', error);
        patientProfileContent.innerHTML = `<div class="alert alert-danger">Error loading medical records: ${error.message}</div>`;
    }
}

function formatDate(dateString) {
    if (!dateString) return '';
    
    const date = new Date(dateString);
    return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
}