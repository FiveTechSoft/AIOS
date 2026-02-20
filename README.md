# AIOS - AI Operating System
# The future belongs to Agents and not to apps!

AIOS is an experimental and highly robust AI Assistant platform natively built in **Harbour** and designed to securely interface with the **Google Gemini API**. Utilizing Gemini's Function Calling (FC) capabilities, AIOS transcends a simple chat interface by dynamically executing local system "Skills" based on user intent.

## 🚀 Key Features

*   **Native Harbour Architecture**: Ultra-stable system integration using `hbcurl` and `hbhttpd` for fast, lightweight background processes and web interfacing.
*   **Gemini Function Calling (FC)**: Instead of just returning text, the AI understands when to trigger specialized scripts (e.g., FileSystem operations, sending Telegram messages, or Web Searches).
*   **Persistent Core Memory**: The AI maintains situational awareness via `MEMORY.md`, ensuring long-term context retention across different sessions.
*   **Identity & Soul Concept**: The persona, tone, and identity parameters are modularized in `IDENTITY.md` and `SOUL.md`.
*   **Real-time Cost & Token Counter**: The frontend UI (`chat.prg`) actively tracks and calculates API token usage and estimates costs per response in real-time.
*   **Robust Error Recovery**: Built-in sequence failure recovery (`BEGIN SEQUENCE ... RECOVER`) ensuring the API Loop never crashes the host server.

## 📂 Project Structure

*   **`aios.prg`**: The core backend engine. Manages the execution reasoning loop (`ExecuteReasoningLoop`), HTTP payload construction, and API error parsing (`ParseAiosFCResponse`).
*   **`chat.prg`**: The frontend Web UI. Features a sleek, responsive design with "Thinking" indicators, HTML formatting conversions, and precise token/price tracking.
*   **`whatsnew.txt`**: Detailed changelog of project evolution.
*   **`.agent/skills/`**: The directory containing explicit guidelines for the development constraints and tools associated with the system (e.g., Harbour 3-space indentation rules).
*   **`persona/`**: Contains the `MEMORY.md`, `IDENTITY.md`, and `SOUL.md` that feed the dynamic system prompt.

## 🛠️ Available Skills

The assistant can currently manipulate the following toolsets autonomously:
*   **FileSystem**: Search directories, open/edit configurations.
*   **Telegram**: Fetch updates and send real-time notification messages.
*   **Web Search**: Dual fallback methods utilizing Wikipedia JSON API and Google Serper API/DuckDuckGo for browsing.
*   **Cron/Reminders**: Schedule tasks and time-sensitive reminders system-wide.

## ⚙️ Setup & Installation

### Requirements
*   **Harbour Compiler**: Requires `hbmk2.exe` (specifically tested with Borland C++ integration `bcc32c` mapped in your `PATH`).
*   **Environment**: Built for Windows environments (or cross-compiled targets) running standard `hbcurl.hbc`, `xhb.hbc`, and `hbhttpd.hbc` modules.
*   **HIX Server**: Must be hosted over an HTTP Daemon configured to render `.prg` web files dynamically.

### Configuration
1.  **API Key**: You must provide a valid Gemini API Key. The core looks for the `GEMINI_API_KEY` system environment variable, or alternatively, a fallback `api_key` string inside `gemini_config.json`.
2.  **Compilation**: To manually compile the backend or frontend:
    ```cmd
    set PATH=c:\bcc77\bin;%PATH% 
    c:\harbour\bin\win\bcc\hbmk2.exe aios.prg hbcurl.hbc xhb.hbc hbhttpd.hbc
    ```

## 🖥️ Usage Guide

1.  **Launch the System**: Ensure your localhost HIX server is actively running.
2.  **Access the Interface**: Navigate your browser to:
    ```
    http://localhost/chat.prg
    ```
3.  **Interact**: Type your request or instructions naturally. The AIOS will intercept the query, analyze if an internal Skill needs to be invoked, and subsequently return the rendered HTML/Text answer along with the cost calculation displayed securely in the top right window frame.
