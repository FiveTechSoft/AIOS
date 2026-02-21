# AIOS - AI Operating System
# The future belongs to Agents. Apps are the past!

AIOS is an experimental and highly robust AI Assistant platform natively built in **Harbour** and designed to securely interface with the **Google Gemini API**. Utilizing Gemini's Function Calling (FC) capabilities, AIOS transcends a simple chat interface by dynamically executing local system "Skills" based on user intent.

## 🚀 Key Features

*   **Native Harbour Architecture**: Ultra-stable system integration using `hbcurl` and `hbhttpd` for fast, lightweight background processes and web interfacing.
*   **Gemini Function Calling (FC)**: Instead of just returning text, the AI understands when to trigger specialized scripts (e.g., FileSystem operations, sending Telegram messages, or Web Searches).
*   **Web Speech Integration**: Full support for native browser `SpeechRecognition` to talk to the AI, and `SpeechSynthesis` (TTS) to hear its responses aloud natively.
*   **Multi-Modal AI Image Generation**: Integrated with Gemini Imagen API to generate rich, high-quality images directly into the chat stream via `image_gen.prg`.
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
*   **FileSystem**: Search directories, open/edit configurations and scripts.
*   **Command Shell & Git**: Execute native OS terminal commands and manage version control via `shell` and `git` skills.
*   **Telegram & WhatsApp**: Fetch updates and send real-time notification messages across popular messaging platforms.
*   **Gmail**: Read and send emails programmatically via the `gmail` skill.
*   **Web Search**: Dual fallback methods utilizing Wikipedia JSON API and Google Serper API/DuckDuckGo for live browsing.
*   **Cron/Reminders & DateTime**: Schedule tasks, time-sensitive reminders, and access system clock synchronization.
*   **Config & Identity**: Dynamically update internal configurations and its own personality core.
*   **Image Generation**: Prompt natively processed text-to-image AI tools to visualize concepts dynamically into the browser (`image_gen.prg`).

## ⚙️ Setup & Installation

### Requirements
*   **Harbour Compiler**: Requires `hbmk2` mapped in your `PATH`.
*   **Environment**: Built for Windows environments (or cross-compiled targets) running standard `hbcurl.hbc`, `xhb.hbc`, and `hbhttpd.hbc` modules.

### Configuration
1.  **Gemini API Key**: You must provide a valid Gemini API Key. The core looks for the `GEMINI_API_KEY` system environment variable, or alternatively, a fallback `api_key` string inside `gemini_config.json`.
2.  **Web Search API**: For live Web Search capabilities, you must provide your Serper.dev API key inside the `serper_config.json` file.
3.  **Telegram Bot API**: For messaging capabilities, configure your bot token and chat identifiers inside the `telegram_config.json` file.
4.  **Compilation**: To manually compile the backend or frontend:
    ```cmd
    hbmk2 aios.prg hbcurl.hbc xhb.hbc hbhttpd.hbc
    ```

## 🖥️ Usage Guide

1.  **Launch the System**: Ensure your localhost HIX server is actively running.
2.  **Access the Interface**: Navigate your browser to:
    ```
    http://localhost/chat.prg
    ```
3.  **Interact**: Type your request or instructions naturally. The AIOS will intercept the query, analyze if an internal Skill needs to be invoked, and subsequently return the rendered HTML/Text answer along with the cost calculation displayed securely in the top right window frame.
