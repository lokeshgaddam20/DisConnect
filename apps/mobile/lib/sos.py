from twilio.rest import Client

# Replace these variables with your actual Twilio credentials
account_sid = 'ACdfa535aa0b5047a2e87288c1b1b668f3'
auth_token = 'ee6da90c3b699907dcbd3b69ecb6ebea'

# Initialize Twilio client
client = Client(account_sid, auth_token)

# Create and send the message
message = client.messages.create(
    from_='+12566395858',  # Twilio phone number
    body='SOS! I need help with the climate crisis!',
    to='+917013399629'  # Recipient's phone number
)

# Print the message SID
print(message.sid)
