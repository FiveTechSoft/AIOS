---
description: How to set a simple reminder for Anto
---

To set a reminder for Anto without using PowerShell:

1. Identify the time in seconds (e.g., 60 for 1 minute).
2. Use the `run_command` tool to execute `remind.bat` in the background.

Example:
// turbo
`run_command(CommandLine="remind.bat 60 \"Es hora de descansar, Anto\"", Cwd="c:\\openclaw", SafeToAutoRun=true, WaitMsBeforeAsync=0)`

Note: This will open a text file with the message after the specified time.
