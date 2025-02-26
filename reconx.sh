#!/bin/bash

# === Input Files ===
INPUT_FILE="${1:-all_domains.txt}"
MASSCAN_RESULTS="1ip_ports.txt"
CLEANED_PORTS="ulti.txt"
TELEGRAM_BOT_TOKEN="" # Replace with your actual Telegram Bot ID
TELEGRAM_CHAT_ID=""  # Replace with your actual Telegram Chat ID

# === 1️⃣ Validate Input File ===
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

echo "✅ Running httpx scan on $INPUT_FILE..."
httpx -sc -ip -server -title -wc -l "$INPUT_FILE" -o httpx.dom.txt

if [ ! -s httpx.dom.txt ]; then
    echo "❌ Error: httpx scan failed."
    exit 1
fi

# === 2️⃣ Categorize HTTP Responses ===
echo "✅ Extracting HTTP status categories..."

touch alive.txt redirects.txt errors.txt server_errors.txt IPS.dom.txt

(
  grep "200" httpx.dom.txt | awk '{print $1}' | sort -u > alive.txt &
  grep -E "301|302" httpx.dom.txt | awk '{print $1}' | sort -u > redirects.txt &
  grep -E "400|403|404|405|429" httpx.dom.txt | awk '{print $1}' | sort -u > errors.txt &
  grep -E "500|502|503" httpx.dom.txt | awk '{print $1}' | sort -u > server_errors.txt &
  grep -oE '\[[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\]' httpx.dom.txt | tr -d '[]' | sort -u > IPS.dom.txt &
  wait
)

echo "✅ Extracted $(wc -l < alive.txt) alive URLs"
echo "✅ Extracted $(wc -l < redirects.txt) redirects"
echo "✅ Extracted $(wc -l < errors.txt) client errors"
echo "✅ Extracted $(wc -l < server_errors.txt) server errors"
echo "✅ Extracted $(wc -l < IPS.dom.txt) unique IPs"

# === 3️⃣ Run Masscan on Unique IPs ===
if [ -s IPS.dom.txt ]; then
    echo "🚀 Running masscan..."
    sudo masscan -iL IPS.dom.txt --top-ports 100 --rate=1000 -oG "$MASSCAN_RESULTS"
fi

# === 4️⃣ Clean Masscan Results (Extract IP:PORT) ===
if [ -s "$MASSCAN_RESULTS" ]; then
    awk '/Host:/ && /Ports:/ {
        match($0, /Host: ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/, ip);
        match($0, /Ports: ([0-9]+)/, port);
        if (ip[1] && port[1]) print ip[1] ":" port[1];
    }' "$MASSCAN_RESULTS" > "$CLEANED_PORTS"
    echo "✅ Cleaned IP:PORT list saved to $CLEANED_PORTS"
fi

# === 5️⃣ Run Nuclei for Vulnerability Detection ===
if [ -s alive.txt ]; then
    echo "🚀 Running nuclei on alive URLs (Web CVEs)..."
    nuclei -l alive.txt -t cves/ -o web_vulnerabilities.txt &
fi

if [ -s IPS.dom.txt ]; then
    echo "🚀 Running nuclei on unique IPs (Network CVEs)..."
    nuclei -l IPS.dom.txt -t cves/ -o infra_vulnerabilities.txt &
fi

wait  # Ensure all background processes complete

# === 6️⃣ Send Telegram Notification ===
MESSAGE="Scan completed!
🔵 Alive URLs: $(wc -l < alive.txt)
🟡 Redirects: $(wc -l < redirects.txt)
🔴 Client Errors: $(wc -l < errors.txt)
🔥 Open Ports: $(wc -l < $CLEANED_PORTS)
⚡ Masscan Results: $(grep -c '^Host:' $MASSCAN_RESULTS)"
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
     -d chat_id="$TELEGRAM_CHAT_ID" -d text="$MESSAGE"

echo "✅ Script Execution Complete!"