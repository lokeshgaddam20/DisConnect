import requests
from flask import Flask, request, jsonify, redirect
from dotenv import load_dotenv
import google.generativeai as genai 
import os
import json
from novu.api import EventApi
from novu.dto.subscriber import SubscriberDto
from novu.api.subscriber import SubscriberApi
from novu.dto.event import InputEventDto

from firebase_admin import credentials, initialize_app,firestore
load_dotenv()
cred = credentials.Certificate({
  "type": "service_account",
  "project_id": "sahayaa-9bc84",
  "private_key_id": "3197d5f6ee2b638c96ae0f62c73d35e71d70d50a",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCT1kGju9rTeSqj\nCAvAbiSL7Ju7P3x1RwgP5sjuZ4r0DwXE2Q1g4t+ho1XlSQPySHRxps376S7W+OC/\nbcScQnV+73lCkXyXd0ZadHqnDxH3nLvGf2p1r7hbyya9N6A+v/5qoYgvmz+lxE10\njiIw9sfC1aM5GMbpOS0oqW3FVbpytFfweoCJVQOfewpgbI/RuMEVUvXvhwiCnBIt\nRShX4l/+glD22idBr38b6bxYQihCnzeycg35gekKZPzshjwxGoxiGxXoHEZDSIcS\nAVsUb0XalAO1tbFmfPpEDKt0QKmQ0ytgktr0RcReH9eWCPNzoT7XFqfIkRodL/Q3\nGparN6D5AgMBAAECgf9TJiQhfe4Zijr7jJy6IhxzMySrIcZwPhwx1WamzLl6oOov\ngoFyB33yGehkGCmOSg6mCERn57SJdHiewLAYCHPNUSOQ2AM35qiuzOnoPgb9AUpx\nFurNW708cfvbd+pXYMiexhgIIGmE1iePqlNe9sNOuUTJ6iISvKCJnjONf0MT/+qu\nfmBvA5bVZsIR4TOXKGcHGRgcPhn2Y0XyEn3lv9r27pmeuIxJ0Ti6iepwdz2aPnvn\nOytvGbkx6fwnPjawQTthmN8t6pcfI2uplW5O7My5c8JrjfFq6hxORQQj6QDzx1lX\nQGgOZbtcKvQ8xPM6636f0N0C6elOEICi20hS7aECgYEAyMYYgnuZaIhs0j9WNQub\nyqtlSA8HeWrTSFtigki4kuM2vWqEWiCIcx261CHsT1aD9npYVGjABuqbO9OdNrDy\nVIAIcmMN5YkGf5/i7leag8rglUGZXZomwsd+32cNPunqlHYv7EHFLqJq6rS+CDo+\n+O+NxRXYkj4xHH9fj+/m8iECgYEAvICAQxQTbO/PKUpA9nJnjN0mCStwC5R1IHIH\nAqpOEkOBGKEGmyhbDxJwPKE5DjaieNbR3COy3Hy86iRh77gSCV15lODsUJvsKwNi\ncDBuiA/L24fTeiXVUI3hNUifGNCIr8q5Hk2CBgCh67DEcvdvjcI9BhID6PLRc8Vq\nIEPeA9kCgYEAiIKoh4+ibwDTfOCzrL2H3/VJmAUf/94yajA4en0XgkgbIA8cjmsw\nW5ULQtEN66PXde8Zv8q5RfqeMb9gVZ9aJToohB31hOv2DzCXC5dk59c5fEJuFMaL\nNESQbzWSPASwCuGRFAJkH6EvMQZTbySrTHcU3bxM1KKUodu5DhT/4gECgYEAg3OA\n/kYTvdYFux+C6dmiCIN3sNFP02N1wmiCJwOoaegVMJ2qQ60CwyHyjvVHGnhTGL2F\nn2RtqIB8JTO18DuGqG09CetIIHZ7XQuBLAc6LTwGx1KS0Q1tEj2+nS/FcsKJbz2J\nlm4qjBEI2ZlthVazvkGD2KXbgClEkt1KQrHRMxECgYAOTK1M9iQ/9uNQIOyc1Ias\ncvfT1yvyDFuKSTUAWt7dajvvq4Vy1NTwgMGfCo+KfKHoUFK13Uq9x048IzW+IfFM\nn6wpJX/He1Syi/PvqeXESzawybMdM7cs3jcl4+h8X52AmohH298ysHM5vAyjoVYw\nl5mdfwFMaM/2th88C+T+Iw==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-s1bgs@sahayaa-9bc84.iam.gserviceaccount.com",
  "client_id": "104623286205366640503",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-s1bgs%40sahayaa-9bc84.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
)
# cred = credentials.Certificate(r'apps\flask\firebase.json')
firebase_app = initialize_app(cred)
db=firestore.client()


WEATHER_API=os.getenv('WEATHERAPI_API_KEY')
GEMINI_API=os.getenv('GEMINI_API_KEY')
NOVU_KEY=os.getenv('NOVUS_API_KEY')

app = Flask(__name__)



@app.route('/', methods=['GET'])
def index():
    return '<samp>🔼 Sahaya Flask for Backend?</samp>'


@app.route('/api/gemini/',methods = ['GET'])
def gemini():
    city = request.args.get('city')
    URL = f"http://api.weatherapi.com/v1/forecast.json?key={WEATHER_API}&q={city}&days=2&aqi=yes&alerts=yes"
    weather_pattern = requests.get(URL).json()
    genai.configure(api_key=GEMINI_API)
    model = genai.GenerativeModel('gemini-pro')

    # commented prompt for the model
    """prompt= This is the current weather at {city}. consider the data {weather_pattern} to determine the warninng text which is given in json file and then
    Give me a 1-2 Line warning incase of any Thunderstorm, Hurricane, Tornadoo, Tsunami, Hailstorm, Cyclone, Heatwave etc.
    The message should contain the time it is anticipated and what calamity.
    Also give me few precatuionary measures to be prepared for the particular calamity in {city}.
    Warn only if the calamity is less than 48 hours ahead.

    The response should be of a json of this schema 
    'Color': (Red or Orange or yellow - based on siverity of the climate action.) 1 word (red/orange/yellow/white)
    'weather': (The weather at the moment) 1 word [sunny/clowdy/partly-clowdy/rainy/thunderstorm/snow]
    'time' : ETA for the calamity to happen (time remaining to encounter the drastic climate change) in hours
    'Alert': (The warning about the predicted time and calamity) 1-2 lines [short and crisp & Give the nearest first occurence of such change in weather] the data from the json
    'Precautions': (Few precautions to take - based on the siverity (color) of the calamity) In points format. Tailor it to the particular city based on the input data given [A list of strings - each point is a string element in the list]
    Incase, at current, a calamity is going on, (like its raining, etc), Give a response in the above format with a Green 'color' and Alert should consist of the Time the disaster will decrese or will get back to normal. Give the nearest first occurence.
    Also, if the weather is normal, give the response with color 'white' and the rest of the response. Give recomendations and alert for airQuality if the color is'white' (the weather is not bad - cloudy, sunny, etc). If the airQuality is good and has no harm. """
    
    # Strictly give the output as a json
    prompt = f"""This is the current weather at {city}: {weather_pattern}. Analyze this data to generate a warning if there's a forecast of any severe weather events like Thunderstorms, Hurricanes, Tornadoes, Tsunamis, Hailstorms, Cyclones, or Heatwaves within the next 48 hours. The warning should include the type of event, its anticipated time of occurrence, and precautionary measures specific to {city}."

    "Please format the response according to the following JSON schema: "
    "  'Color': 'Specify the color based on the severity of the weather event. Use Red for high severity, Orange for moderate severity, Yellow for mild severity, and White if there are no severe events.', "
    "  'weather': 'Current weather condition in one word (e.g., sunny, cloudy, rainy, thunderstorm, snow, clear).', "
    "  'time': 'Estimated time of arrival (ETA) in hours for the severe weather event.', [null / exact remaining time]"
    "  'Alert': 'A concise 1-2 line warning about the predicted weather event, including the nearest first occurrence.', [null - if the weather is normal/fine / alert msg if the weather is about to change or is different from usual] "
    "  'Precautions': 'A list of precautionary measures tailored to the specific weather event and the city in question. Each measure should be a string element in the list.' [if the weather is all good, then dont give any precautions - empty list]"

    "In case a severe weather event is currently happening, use a Green color in the response and include the estimated time when the event will diminish or return to normal. For normal weather conditions (e.g., sunny or cloudy), use a White color and provide recommendations and alerts related to air quality. Include alerts for air quality only if it's harmful."""
    response = model.generate_content(prompt)
    #print(response.text)
    dic = json.loads(response.text)
    return jsonify(dic)


def add_data_to_firestore(collection_name, key, data):
    doc_ref = db.collection(collection_name).document(key)
    current_data = doc_ref.get().to_dict()
    if current_data and key in current_data:
        if isinstance(current_data[key], list):
            current_data[key].append(data)
        else:
            current_data[key] = [current_data[key], data]
    else:
        current_data = {key: [data]}

    doc_ref.set(current_data)


@app.route('/api/post/',methods = ['POST'])
def add_details():
    try:
        data = request.get_json()
        if 'mode' not in data:
            raise ValueError("Missing 'mode' key in the request.")

        key = data['mode']
        data.pop('mode')
        add_data_to_firestore('needs_and_gives', key, data)
        return jsonify({'message': 'success'}), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500



@app.route('/api/v1/', methods=['GET'])
def get_data_from_firestore():
    doc_ref = db.collection('needs_and_gives')
    docs = doc_ref.stream()
    data_list = []
    
    for doc in docs:
        data_list.append(doc.to_dict())
    
    # Accessing dictionaries by index
    result = {"need":data_list[0]["need"],"give":data_list[0]["give"]}
    return jsonify(result)





def add_sub(sub_id,phone):

    if (SubscriberApi("https://api.novu.co", NOVU_KEY).get(sub_id)):
        return 0
    else:
        subscriber = SubscriberDto(
            email="",
            subscriber_id=sub_id, #This is what the subscriber_id looks like
            first_name="",  # Optional
            last_name="",  # Optional
            phone=phone,  # Optional
            avatar="",  # Optional
            )
        novu = SubscriberApi("https://api.novu.co", NOVU_KEY).create(subscriber)
        return 1
@app.route('/api/v1/sendtxt', methods=['POST'])
def send_message():
    sub = request.form.get('sub')
    event_api = EventApi("https://api.novu.co", NOVU_KEY)
    add_sub(sub['id'],sub['phone'])
    try:
        event_api.trigger(
            name="sahaya", # sends emergency message to particulat subscriber 
            recipients=sub,
            payload={}
        )
        return "Message sent successfully", 200
    except Exception as e:
        return f"Error sending message: {e}", 500
    
@app.route('/api/v1/sos', methods=['POST'])
def sos():
    try:
        sos = request.form.get()
        event=[]
        for i in sos:
            add_sub(i['id'],i['phone']) #to ensure he's a sub 
            event_1 = InputEventDto(
                name="digest-workflow-example",  # The workflow ID is the slug of the workflow name. It can be found on the workflow page.
                recipients=i['id'],
                payload={},  # Your custom Novu payload goes here
            )
            event.append(event_1)
        
        
        novu = EventApi("https://api.novu.co", NOVU_KEY).trigger_bulk(events=event)
        return "SOS", 200
    except Exception as e:
        return f"Error sending message: {e}", 500


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080, debug=True)
