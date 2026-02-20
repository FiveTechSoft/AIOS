---
name: "skill_name"
version: "1.0.0"
description: "Brief description of what this skill does"
category: "communication|filesystem|database|web|utility"
author: "Your Name"
requires_permission: true
dangerous: false
---

# Skill Name

## Overview
A comprehensive description of what this skill does and when it should be used.

## Capabilities
What can this skill do? List all the main functions:
- Capability 1
- Capability 2
- Capability 3

## Parameters

### Required
- `param1` (string): Description of parameter 1
- `param2` (number): Description of parameter 2

### Optional
- `param3` (boolean): Description of parameter 3, default: `false`

## Usage Examples

### Example 1: Basic Usage
**User Intent**: "Send an email to John"

**HIX Understanding**:
```json
{
  "skill": "skill_name",
  "action": "send",
  "parameters": {
    "recipient": "john@example.com",
    "subject": "Hello",
    "body": "Message content"
  }
}
```

**Expected Output**: Email sent successfully

### Example 2: Advanced Usage
**User Intent**: "Schedule a meeting for tomorrow at 3pm"

**HIX Understanding**:
```json
{
  "skill": "skill_name",
  "action": "schedule",
  "parameters": {
    "date": "2026-02-16",
    "time": "15:00",
    "title": "Meeting"
  }
}
```

## Actions

### action_name_1
**Description**: What this action does

**Parameters**:
- `param1`: Description
- `param2`: Description

**Returns**: What this action returns

**Example**:
```
User: "Do something"
HIX: Executes action_name_1 with params
Result: Success message
```

### action_name_2
**Description**: What this action does

**Parameters**:
- `param1`: Description

**Returns**: What this action returns

## Safety & Permissions

### When to Ask Permission
- Action 1: Explain why permission is needed
- Action 2: Explain why permission is needed

### Safety Checks
- Check 1: Description
- Check 2: Description

## Error Handling

### Common Errors
1. **Error Name**: How to handle it
2. **Error Name**: How to handle it

## Implementation Notes

### Dependencies
- Dependency 1: Version or description
- Dependency 2: Version or description

### Configuration
Required configuration in `hix.json` or environment variables:
```json
{
  "skill_name": {
    "api_key": "your_api_key",
    "endpoint": "https://api.example.com"
  }
}
```

### File Structure
```
skills/skill_name/
├── SKILL.md           # This file
├── skill_impl.py      # Main implementation
├── config.json        # Skill configuration
└── tests/             # Tests
    └── test_skill.py
```

## Testing

### Manual Test
How to manually test this skill:
1. Step 1
2. Step 2
3. Expected result

### Automated Test
Location of automated tests and how to run them.

## Changelog

### v1.0.0 (2026-02-15)
- Initial release
- Feature 1
- Feature 2

## Related Skills
- Related Skill 1: Why it's related
- Related Skill 2: Why it's related

## Resources
- [Documentation](https://example.com/docs)
- [API Reference](https://example.com/api)
