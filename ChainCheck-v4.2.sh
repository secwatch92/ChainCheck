#!/bin/bash
# =========================================================
# Script Name: ChainCheck
# Description: This script performs various network connectivity 
#              and internet speed tests using SSH tunneling and
#              SOCKS5 proxy.
#
#              Available Modes:
#              1 -> Create SSH tunnels
#              2 -> Internet speed tests via proxy (through SSH tunnels)
#              3 -> Internet speed tests on servers (without proxy)
#              4 -> Connection test between servers (Ping & Traceroute)
#              5 -> Full internet speed tests (all tests combined)
#
# Author: [Your Name or Team]
# Version: 4.1
# =========================================================

# Log file
LOG_FILE="network_tests.log"
CSV_LOG_FILE="network_tests.csv"

# Check if log files exist and rename them with timestamps
if [ -f "$LOG_FILE" ]; then
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    mv "$LOG_FILE" "network_tests_$TIMESTAMP.log"
fi
if [ -f "$CSV_LOG_FILE" ]; then
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    mv "$CSV_LOG_FILE" "network_tests_$TIMESTAMP.csv"
fi

# Create new log and CSV log files
: > "$LOG_FILE"
: > "$CSV_LOG_FILE"

# Initialize CSV file with header
echo "Timestamp,Test_Type,Target,Ping (ms),Traceroute,Speed_Download (Mbps),Speed_Upload (Mbps)" > "$CSV_LOG_FILE"

# Kill all existing SSH tunnels
pkill -f "ssh -.* -N -D" || true

echo "✅ Existing SSH tunnels killed." | tee -a "$LOG_FILE"

# Test target for connectivity (Ping and Traceroute)
PING_TARGET="1.1.1.1"

# Server configurations
SERVER1='178.33.148.163'
PORT1='24901'
USER1='k4er0d41'

SERVER2='198.244.147.25'
PORT2='10289'
USER2='s3r4m0n1'

SERVER3='184.174.97.17'
PORT3='30490'
USER3='er4g5ty'

# Create SSH tunnels
create_ssh_tunnel() {
    ssh -p "$PORT1" "$USER1@$SERVER1" -4 -N -D 1081 -f
    ssh -J "$USER1@$SERVER1:$PORT1" -p "$PORT2" "$USER2@$SERVER2" -4 -N -D 1082 -f
    ssh -J "$USER1@$SERVER1:$PORT1,$USER2@$SERVER2:$PORT2" -p "$PORT3" "$USER3@$SERVER3" -4 -N -D 1083 -f
    echo "✅ SSH tunnels created." | tee -a "$LOG_FILE"
}

# Internet speed test via SOCKS5 Proxy
speedtest_via_proxy() {
    local proxy_port="$1"
    echo "\n=== 🌐 Running Speedtest via SOCKS5 Proxy on port $proxy_port ===" | tee -a "$LOG_FILE"
    export ALL_PROXY="socks5h://127.0.0.1:$proxy_port"
    result=$(speedtest-cli --simple 2>/dev/null)
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    
    # Log the result to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Speedtest,SOCKS5 Proxy on port $proxy_port,,,$download_speed,$upload_speed" >> "$CSV_LOG_FILE"
    
    if [ $? -ne 0 ]; then
        echo "❌ Speedtest failed via SOCKS5 Proxy on port $proxy_port." | tee -a "$LOG_FILE"
        result="Error"
    fi
    echo -e "Speedtest Result:\n$result" | tee -a "$LOG_FILE"
    unset ALL_PROXY
}

test_local() {
    echo -e "\n=== 🖥️ Connection Test: Local (Direct from System) ===" | tee -a "$LOG_FILE"
    ping_time=$(ping -c 5 $PING_TARGET | tail -1 | awk -F '/' '{print \$5}')
    traceroute_out=$(traceroute -n $PING_TARGET | tail -n 1)
    echo -e "Local -> $PING_TARGET:\nPing: $ping_time ms\nTraceroute: $traceroute_out\n" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Connection Test,Local,$ping_time,$traceroute_out,," >> "$CSV_LOG_FILE"
}

test_server1() {
    echo -e "\n=== 🖥️ Connection Test: Server 1 (Direct) ===" | tee -a "$LOG_FILE"
    ping_time=$(ssh -p "$PORT1" "$USER1@$SERVER1" "ping -c 5 $PING_TARGET | tail -1 | awk -F '/' '{print \$5}'")
    traceroute_out=$(ssh -p "$PORT1" "$USER1@$SERVER1" "traceroute -n $PING_TARGET | tail -n 1")
    echo -e "Server 1 -> $PING_TARGET:\nPing: $ping_time ms\nTraceroute: $traceroute_out\n" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Connection Test,Server 1,$ping_time,$traceroute_out,," >> "$CSV_LOG_FILE"
}

test_server2() {
    echo -e "\n=== 🖥️ Connection Test: Server 2 (Through Server 1) ===" | tee -a "$LOG_FILE"
    ping_time=$(ssh -J "$USER1@$SERVER1:$PORT1" -p "$PORT2" "$USER2@$SERVER2" "ping -c 5 $PING_TARGET | tail -1 | awk -F '/' '{print \$5}'")
    traceroute_out=$(ssh -J "$USER1@$SERVER1:$PORT1" -p "$PORT2" "$USER2@$SERVER2" "traceroute -n $PING_TARGET | tail -n 1")
    echo -e "Server 2 (Through Server 1) -> $PING_TARGET:\nPing: $ping_time ms\nTraceroute: $traceroute_out\n" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Connection Test,Server 2 (Through Server 1),$ping_time,$traceroute_out,," >> "$CSV_LOG_FILE"
}

test_server3() {
    echo -e "\n=== 🖥️ Connection Test: Server 3 (Through Servers 1 and 2) ===" | tee -a "$LOG_FILE"
    ping_time=$(ssh -J "$USER1@$SERVER1:$PORT1,$USER2@$SERVER2:$PORT2" -p "$PORT3" "$USER3@$SERVER3" "ping -c 5 $PING_TARGET | tail -1 | awk -F '/' '{print \$5}'")
    traceroute_out=$(ssh -J "$USER1@$SERVER1:$PORT1,$USER2@$SERVER2:$PORT2" -p "$PORT3" "$USER3@$SERVER3" "traceroute -n $PING_TARGET | tail -n 1")
    echo -e "Server 3 (Through Servers 1 and 2) -> $PING_TARGET:\nPing: $ping_time ms\nTraceroute: $traceroute_out\n" | tee -a "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Connection Test,Server 3 (Through Servers 1 and 2),$ping_time,$traceroute_out,," >> "$CSV_LOG_FILE"
}

# -------------------------
# Test Functions for Mode 2: Internet Speed Test with speedtest-cli (without a fixed target)
# -------------------------

speedtest_local() {
    echo -e "\n=== 🌐 Internet Speed Test (Direct from System) ===" | tee -a "$LOG_FILE"
    result=$(speedtest-cli --simple 2>/dev/null)
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    
    # Log the result to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Speedtest,Local,,,$download_speed,$upload_speed" >> "$CSV_LOG_FILE"
    
    echo -e "Speed Test Result (Direct):\n$result" | tee -a "$LOG_FILE"
}

speedtest_server1() {
    echo -e "\n=== 🌐 Internet Speed Test (Through Server 1) ===" | tee -a "$LOG_FILE"
    result=$(ssh -p "$PORT1" "$USER1@$SERVER1" "speedtest-cli --simple 2>/dev/null")
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    
    # Log the result to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Speedtest,Server 1,,,$download_speed,$upload_speed" >> "$CSV_LOG_FILE"
    
    echo -e "Speed Test Result (Server 1):\n$result" | tee -a "$LOG_FILE"
}

speedtest_server2() {
    echo -e "\n=== 🌐 Internet Speed Test (Through Servers 1 and 2) ===" | tee -a "$LOG_FILE"
    result=$(ssh -J "$USER1@$SERVER1:$PORT1" -p "$PORT2" "$USER2@$SERVER2" "speedtest-cli --simple 2>/dev/null")
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    
    # Log the result to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Speedtest,Server 2 (Through Server 1),,$download_speed,$upload_speed" >> "$CSV_LOG_FILE"
    
    echo -e "Speed Test Result (Server 2 through Server 1):\n$result" | tee -a "$LOG_FILE"
}

speedtest_server3() {
    echo -e "\n=== 🌐 Internet Speed Test (Through Servers 1, 2, and 3) ===" | tee -a "$LOG_FILE"
    result=$(ssh -J "$USER1@$SERVER1:$PORT1,$USER2@$SERVER2:$PORT2" -p "$PORT3" "$USER3@$SERVER3" "speedtest-cli --simple 2>/dev/null")
    download_speed=$(echo "$result" | grep "Download" | awk '{print $2}')
    upload_speed=$(echo "$result" | grep "Upload" | awk '{print $2}')
    
    # Log the result to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),Speedtest,Server 3 (Through Servers 1 and 2),,$download_speed,$upload_speed" >> "$CSV_LOG_FILE"
    
    echo -e "Speed Test Result (Server 3 through Servers 1 and 2):\n$result" | tee -a "$LOG_FILE"
}

# Displaying introductory message about the script
echo "=========================================================="
echo "🔹 ChainCheck Network Testing Script"
echo "This script helps in testing network connectivity and internet speeds."
echo "It offers multiple modes of operation for your specific needs."
echo "=========================================================="

# Ensure the user provides a valid mode argument (1-5)
# Script execution based on mode

usage() {
    echo "Usage: $0 [mode]"
    echo "mode: 1 -> Create SSH tunnels"
    echo "      2 -> Internet speed tests via proxy (through SSH tunnels)"
    echo "      3 -> Internet speed tests on servers (without proxy)"
    echo "      4 -> Connection test between servers (Ping & Traceroute)"
    echo "      5 -> Full internet speed tests (all tests combined)"
}

# Ensure the user provides a valid mode argument (1-5)
if [ "$#" -ne 1 ]; then
    echo "❌ Invalid input. Please specify a mode."
    usage
    exit 1
fi

MODE="$1"

case "$MODE" in
    1)
        echo "🔹 Creating SSH tunnels..." | tee -a "$LOG_FILE"
        create_ssh_tunnel
        ;;
    2)
        echo "🔹 Running internet speed tests via proxy..." | tee -a "$LOG_FILE"
        echo "🔹 Creating SSH tunnels..." | tee -a "$LOG_FILE"
        create_ssh_tunnel
        speedtest_via_proxy 1081
        speedtest_via_proxy 1082  
        speedtest_via_proxy 1083 
        ;;
     3)
        echo "🔹 Running internet speed tests in servers..." | tee -a "$LOG_FILE"
        speedtest_local
        speedtest_server1
        speedtest_server2
        speedtest_server3
        ;;   
    4)
        echo "🔹 Connection Test..." | tee -a "$LOG_FILE"
        test_server1
        test_server2
        test_server3
        ;;
     5)
        echo "🔹 Running Full internet speed tests..." | tee -a "$LOG_FILE"
        echo "🔹 Creating SSH tunnels..." | tee -a "$LOG_FILE"
        create_ssh_tunnel
        speedtest_local
        speedtest_server1
        speedtest_via_proxy 1081
        speedtest_server2
        speedtest_via_proxy 1082
        speedtest_server3
        speedtest_via_proxy 1083
        test_server1
        test_server2
        test_server3
        ;;
    *)
        usage
        exit 1
        ;;
esac

# Kill all existing SSH tunnels
pkill -f "ssh -.* -N -D 108.* -f" || true 
echo "\n✅ Tests completed! Results are saved in $LOG_FILE and $CSV_LOG_FILE."
