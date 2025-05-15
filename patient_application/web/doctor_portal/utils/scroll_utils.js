// Scroll utilities for doctor portal messages
document.addEventListener('DOMContentLoaded', function() {
    // Observe message container for changes (new messages)
    const messageContainer = document.getElementById('message-container');
    if (messageContainer) {
        // Create a mutation observer that will watch for new messages
        const observer = new MutationObserver(function(mutations) {
            // When new messages are added, scroll to the bottom
            scrollMessageContainerToBottom();
        });
        
        // Start observing the container for DOM changes
        observer.observe(messageContainer, { 
            childList: true, 
            subtree: true 
        });
    }
});

// Function to scroll the message container to the bottom
function scrollMessageContainerToBottom() {
    const messageContainer = document.getElementById('message-container');
    if (messageContainer) {
        setTimeout(() => {
            messageContainer.scrollTop = messageContainer.scrollHeight;
        }, 100);
    }
}

// Export functions for use elsewhere
window.scrollUtils = {
    scrollMessageContainerToBottom
};
