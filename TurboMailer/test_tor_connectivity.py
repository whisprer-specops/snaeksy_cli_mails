import requests

proxies = {
    'http': 'socks5h://127.0.0.1:9050',
    'https': 'socks5h://127.0.0.1:9050'
}

try:
    response = requests.get("https://check.torproject.org/api/ip", proxies=proxies, timeout=30)
    print(response.json())
except Exception as e:
    print(f"Tor connection failed: {e}")