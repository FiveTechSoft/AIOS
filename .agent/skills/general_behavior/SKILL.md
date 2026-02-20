---
name: General Behavior
description: Defines the general operational behavior and housekeeping rules for the AI Assistant.
---

# General Behavior & Housekeeping

This skill provides core guidelines on how the agent should manage its workspace and interact with temporary files.

## Instructions
1. **Clean up Temporary Files**: Whenever you create temporary scripts (like `.py` files to test, format, or process data) or temporary output files (like `.html` debug outputs), you MUST delete them immediately after you are done using them. Leaving the workspace clean is a top priority.
2. **Update Logs**: Continuously and systematically update `whatsnew.txt` whenever you make significant changes, add features, or update documentation/standards. Keep the project history well documented.
3. **Workspace Integrity**: Do not leave unnecessary artifacts outside of the system-designated directories or the `whatsnew.txt` changelog.
4. **Auto-commit**: Every time a change is made to the repository, you MUST automatically commit and push all changes to the origin repo. You MUST NOT commit any `.json` files.
