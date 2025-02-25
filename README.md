# ReconX

ReconX is a Bash script that automates domain reconnaissance by scanning domains with `httpx`, categorizing HTTP responses, extracting unique IPs, scanning ports with `masscan`, checking for vulnerabilities with `nuclei`, and sending results via Telegram.

## Features
- **HTTP Scanning**: Uses `httpx` to probe domains and saves full output to `httpx.dom.txt`.
- **Response Categorization**: Extracts alive URLs (200), redirects (301/302), client errors (400s), and server errors (500s).
- **Unique IPs**: Extracts deduplicated IPs from `httpx` output.
- **Port Scanning**: Runs `masscan` on IPs for the top 100 ports and cleans results into an `IP:PORT` list.
- **Vulnerability Detection**: Scans alive URLs and IPs with `nuclei` for CVEs.
- **Telegram Notifications**: Sends a summary of results to a Telegram chat.

## Prerequisites
Before using ReconX, ensure the following tools are installed and in your PATH:
1. **`httpx`** - HTTP probing tool. Install via:
   > go install github.com/projectdiscovery/httpx/cmd/httpx@latest
2. **`masscan`** - Port scanner (requires sudo). Install via:
   > sudo apt install masscan
3. **`nuclei`** - Vulnerability scanner. Install via:
   > go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
4. **Bash Environment**: Runs on Linux/macOS with `curl` for Telegram notifications.

## Installation
1. Clone this repository:
   > git clone https://github.com/fdzdev/ReconX.git
   >
   > cd ReconX
2. Make the script executable:
   > chmod +x reconx.sh
3. Configure Telegram:
   - Replace `your_chat_id` in the script with your Telegram Chat ID.
   - The default bot token is `779945:AAF8WdCx2g`; replace it if using a different bot.

## Usage
1. **Prepare your domain list**:
   - Create a file (e.g., `all_domains.txt`) with one domain per line. Example:
     > https://example.com
     >
     > https://sub.example.org
2. **Run ReconX**:
   - Default input is `all_domains.txt`:
     > ./reconx.sh
   - Or specify a custom input file:
     > ./reconx.sh custom_domains.txt
   - Enter your sudo password for `masscan` when prompted.
3. **Output Files**:
   - `httpx.dom.txt`: Full `httpx` output.
   - `alive.txt`: URLs with status 200.
   - `redirects.txt`: URLs with status 301/302.
   - `errors.txt`: URLs with status 400/403/404/405/429.
   - `server_errors.txt`: URLs with status 500/502/503.
   - `IPS.dom.txt`: Unique IPs.
   - `1ip_ports.txt`: Raw `masscan` output.
   - `ulti.txt`: Cleaned `IP:PORT` list from `masscan`.
   - `web_vulnerabilities.txt`: `nuclei` results for alive URLs.
   - `infra_vulnerabilities.txt`: `nuclei` results for IPs.

## Example Output
If `httpx.dom.txt` contains:
> https://example.com [200] [Example Site] [nginx] [1.2.3.4] [50]
>
> https://sub.example.com [301] [Moved] [apache] [1.2.3.5] [0]
>
> https://error.example.com [404] [Not Found] [nginx] [1.2.3.4] [10]

- `alive.txt`:
  > https://example.com
- `redirects.txt`:
  > https://sub.example.com
- `errors.txt`:
  > https://error.example.com
- `IPS.dom.txt`:
  > 1.2.3.4
  >
  > 1.2.3.5
- `ulti.txt` (after `masscan`):
  > 1.2.3.4:80
  >
  > 1.2.3.5:443
- Telegram message:
  > Scan completed!
  >
  > 🔵 Alive URLs: 1
  >
  > 🟡 Redirects: 1
  >
  > 🔴 Client Errors: 1
  >
  > 🔥 Open Ports: 2
  >
  > ⚡ Masscan Results: 2

## Configuration
- **Input File**: Change the default `INPUT_FILE` by editing the script or passing an argument.
- **Telegram**: Update `TELEGRAM_CHAT_ID` with your chat ID (get it from `@BotFather` or `@getidbot`).
- **Masscan Rate**: Adjust `--rate=1000` in the script if it fails (e.g., `--rate=500`).

## Improvements
- **Error Handling**: Checks for input file and `httpx` success.
- **Parallel Processing**: Runs extractions in the background for speed.
- **Detailed Output**: Counts entries in each file.

## Troubleshooting
- **"Input file not found"**: Ensure your domain list exists.
- **"httpx scan failed"**: Verify `httpx` is installed and in your PATH.
- **"masscan errors"**: Run manually with `sudo masscan -iL IPS.dom.txt --top-ports 100 --rate=500` to debug.
- **"nuclei fails"**: Ensure `nuclei` is installed and templates are updated (`nuclei -update-templates`).
- **No Telegram message**: Check bot token and chat ID validity.

## Contributing
Feel free to fork, submit issues, or send pull requests to enhance ReconX!
