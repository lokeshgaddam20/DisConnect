app = Flask(__name__)

# Replace these variables with your actual Twilio credentials
account_sid = 'ACdfa535aa0b5047a2e87288c1b1b668f3'
auth_token = 'ee6da90c3b699907dcbd3b69ecb6ebea'

# Initialize Twilio client
client = Client(account_sid, auth_token)

@app.route('/')
def index():

if __name__ == '__main__':
    app.run(debug=True)
