# Layerbounce

Layerbounce is a World of Warcraft (WoW) addon designed to simplify group management and improve layer coordination. With automation for invitations, AFK management, and a minimap button, Layerbounce makes helping others layer swap easier.

## Features

- **Layer Detection and Notifications**:
  - Automatically detects the current layer from the minimap.
  - Shares the current layer with party members or responds to whispers.

- **Minimap Button**:
  - Easy-to-use button for toggling the addon on or off.
  - Drag-and-drop repositioning for customization.
  - Visual feedback for active or inactive states.

- **Automated Group Management**:
  - Handles whisper and chat commands like "layer" for group invitations.
  - Manages declined invites and cooldowns for players who leave or decline.
  - Ensures only valid candidates are invited.

- **AFK Player Management**:
  - Automatically removes AFK players after a configurable timeout.
  - Prevents re-inviting players on a cooldown after leaving or declining.

- **Saved Settings**:
  - Retains addon states and user preferences between sessions.

## Installation

1. Download Layerbounce from CurseForge.
2. Extract or move the addon folder into your WoW AddOns directory:
   ```
   ...\World of Warcraft\_classic_era_\Interface\AddOns\
   ```
3. Restart WoW or reload your UI with `/reload`.

## Usage

- **Toggling Addon**: Use the minimap button to enable or disable Layerbounce.
- **Invite by Layer**: Players can whisper "layer" or "layer X,Y,Z" to request an invite.
- **AFK Management**: The addon automatically handles inactive players.
- **Layer Notifications**: The addon shares your layer automatically with the group when necessary.

### Features List

1. **Core Functionalities**:
   - Automatic layer detection from the minimap.

2. **User Interface**:
   - Minimap button for toggling the addon and repositioning.

3. **Invitation System**:
   - Responds to whispers like "layer" or "layer X,Y,Z" to invite players.
   - Prevents spam through invite cooldowns.
   - Automatically shares current layer with the group.

4. **AFK Management**:
   - Removes players after an inactivity timeout.
   - Tracks players who leave or decline and applies re-invite cooldowns.

5. **Performance Optimization**:
   - Event throttling to reduce unnecessary processing.
   - Lightweight and responsive design.