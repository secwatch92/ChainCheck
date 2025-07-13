# 🔗 ChainCheck

**ChainCheck** is a powerful and automated Bash-based tool designed for advanced network diagnostics, SSH tunnel chaining, and internet speed testing. It enables running speed and connectivity tests through multi-hop SSH tunnels and generates structured logs for professional analysis.

![GitHub](https://img.shields.io/badge/bash-compatible-blue?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

---

## 📋 Table of Contents

- [Features](#-features)
- [How It Works](#-how-it-works)
- [Modes of Operation](#-modes-of-operation)
- [Requirements](#-requirements)
- [Sample Output](#-sample-output)
- [Suggested Improvements](#-suggested-improvements)
- [License](#-license)

---

## ⚙️ Features

- 🔐 **Multi-hop SSH Tunneling**: Automatically creates chained SOCKS5 proxies using SSH through multiple servers.
- 🌐 **Speed Tests**:
  - Through SOCKS5 proxies with `speedtest-cli`
  - Directly on remote servers
- 📶 **Connectivity Tests**:
  - `ping` for latency
  - `traceroute` to trace network paths
- 🧾 **Automatic Logging**:
  - Logs in `.txt` and `.csv` formats
  - Easily parsable and graphable
- 🔄 **Tunnel Management**:
  - Auto-kills old tunnels
  - Cleans up resources
- ⚙️ **Fully Scripted CLI**:
  - Menu-driven script with multiple modes

---

## 🚀 How It Works

1. **Prepare the environment**: Verify required binaries (`ssh`, `speedtest-cli`, etc.)
2. **Create tunnels**: SSH-based SOCKS5 proxies from multi-hop servers.
3. **Run tests**:
   - Speedtest through proxy or direct
   - Ping & traceroute
4. **Log results**: Save outputs to structured text and `.csv`
5. **Cleanup**: Automatically kills all opened SSH tunnels

> 📁 Logs and reports are stored with timestamped filenames to avoid overwrite.

---

## 🧪 Modes of Operation

| Mode | Description                                          |
|------|------------------------------------------------------|
| `1`  | Create SSH tunnels (multi-hop, SOCKS5 ready)         |
| `2`  | Speedtest via SOCKS5 proxies                         |
| `3`  | Speedtest directly on servers (no proxy)             |
| `4`  | Ping and traceroute between servers                  |
| `5`  | Full benchmark (all tests combined)                  |

---

## 📦 Requirements

Make sure the following tools are installed:

- `bash`
- `ssh`
- `speedtest-cli`
- `ping`
- `traceroute`

Optional for enhancements:

- `mailx` or `sendmail` (for email reports)
- `cron` (for scheduled runs)
- `parallel` (for performance)

---

## 📂 Sample Output

### 📜 Log Output

```log
✅ SSH tunnels created.
🌐 Running Speedtest on port 1081...
Download: 12.45 Mbps
Upload: 5.67 Mbps
