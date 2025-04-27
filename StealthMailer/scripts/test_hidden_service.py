import requests

# Define the SOCKS5 proxy for Tor (to resolve .onion addresses)
proxies = {
    "http": "socks5h://127.0.0.1:9050",
    "https": "socks5h://127.0.0.1:9050"
}

# Define the hidden service proxy (Squid)
hidden_service_proxy = "http://d67fbuf67fku3d5e7iymu6b3r33phek3hwj6lxcej7mpjk33gajijjyd.onion:3128"

# Update the proxies dictionary to include the hidden service proxy
proxies["http"] = hidden_service_proxy
proxies["https"] = hidden_service_proxy

# Proxy authentication
proxy_auth = ("proxyuser", "GoodWitch10")

try:
    response = requests.get(
        "https://ifconfig.me",
        proxies=proxies,
        auth=proxy_auth,
        timeout=30
    )
    print("Success! IP:", response.text)
except Exception as e:
    print("Error:", e)
