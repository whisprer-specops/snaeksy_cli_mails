import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
import socks
import socket
from stem.control import Controller

# Define variables at the top
file_path = r"D:\code\repos\github_desktop\snaeksy_cli_mails\turbomailer\scripts\example.txt"
upload_url = "http://138.197.11.134:5000/"
upload_url = "http://whispr.dev/"
proxies = {
    'http': 'http://138.197.11.134:3128',
    'https': 'http://138.197.11.134:3128'
}

# Set up a session with retries and headers
session = requests.Session()
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.8",
    "Accept-Encoding": "gzip, deflate",
    "Connection": "keep-alive"
}
session.headers.update(headers)

# Configure retries
retries = Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
session.mount("http://", HTTPAdapter(max_retries=retries))
session.mount("https://", HTTPAdapter(max_retries=retries))

# Function to request a new Tor circuit
# def new_tor_circuit():
#   try:
#       with Controller.from_port(port=9051) as controller:
#           controller.authenticate()
#           controller.signal("NEWNYM")
#           print("New Tor circuit requested.")
#   except Exception as e:
#       print(f"Failed to request new Tor circuit: {e}")

# Retry the upload with multiple circuits
# max_attempts = 3
# for attempt in range(max_attempts):
#   new_tor_circuit()
#   try:
#      with open(file_path, 'rb') as f:
#          files = {'file': f}
#           response = session.post(upload_url, files=files, proxies=proxies, timeout=120)
#       if response.status_code in (200, 201):
#           print("File uploaded successfully:", response.text)
#           break
#       else:
#           print(f"Upload failed with status code {response.status_code}: {response.text}")
#           exit(1)
#   except Exception as e:
#       print(f"Attempt {attempt + 1}/{max_attempts} failed: {e}")
#       if attempt == max_attempts - 1:
#           print("All attempts failed. Exiting.")
#           exit(1)

# Optional: Try without Tor
try:
    with open(file_path, 'rb') as f:
        files = {'file': f}
        response = session.post(upload_url, files=files, timeout=120)  # No proxies
    if response.status_code in (200, 201):
        print("File uploaded successfully (without Tor):", response.text)
    else:
        print(f"Upload failed with status code {response.status_code} (without Tor): {response.text}")
        exit(1)
except Exception as e:
    print(f"Failed to upload file (without Tor): {e}")
    exit(1)