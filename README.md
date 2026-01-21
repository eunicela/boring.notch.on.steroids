<h1 align="center">
  <br>
  <a href="http://thebored.name"><img src="https://framerusercontent.com/images/RFK4vs0kn8pRMuOO58JeyoemXA.png?scale-down-to=256" alt="Boring Notch" width="150"></a>
  <br>
  boring.notch (Claude Code Fork)
  <br>
</h1>

<p align="center">
  <strong>A fork with Tamagotchi-style Claude Code integration</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/fork%20of-boring.notch-blue" alt="Fork of boring.notch" />
  <img src="https://img.shields.io/badge/macOS-14%2B-green" alt="macOS 14+" />
</p>

---

## About

This is a fork of [boring.notch](https://github.com/TheBoredTeam/boring.notch) that adds **Claude Code integration** with a Tamagotchi-style companion in your MacBook's notch.

Watch your pixel-art Claude companion react to your coding sessions:
- **Sleeping** when idle
- **Thinking** when generating responses
- **Working** when executing tools
- **Waiting** when permission is needed (with visual alert!)
- **Celebrating** when tasks complete

### Features Added in This Fork

- **Claude Code Integration** - Real-time monitoring of Claude Code sessions
- **Tamagotchi Character** - Pixel-art Claude with mood animations
- **Multi-Session Support** - Track multiple Claude Code sessions simultaneously
- **Permission Alerts** - Visual indicator when Claude needs approval
- **Activity Stats** - See token usage, active tools, and session info
- **Session Dots** - Quick status view of all active sessions

All original boring.notch features (music controls, calendar, shelf, HUD replacement, etc.) are preserved.

---

## Installation

**System Requirements:**
- macOS **14 Sonoma** or later
- Apple Silicon or Intel Mac

### Build from Source

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/eunicela/boring.notch.on.steroids.git
   cd boring.notch.on.steroids
   ```

2. **Open in Xcode**:
   ```bash
   open boringNotch.xcodeproj
   ```

3. **Build and Run**: Press `Cmd + R`

---

## Usage

1. Launch the app - your notch now includes the Claude Code tab
2. Start a Claude Code session in your terminal or IDE
3. Watch your pixel Claude react to your coding session!
4. Click the session dots to focus different Claude Code windows

---

## Upstream

This fork tracks [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch).

To merge upstream changes:
```bash
git remote add upstream https://github.com/TheBoredTeam/boring.notch.git
git fetch upstream
git merge upstream/main
```

---

## Attribution

### Original Project
- **[boring.notch](https://github.com/TheBoredTeam/boring.notch)** by [The Bored Team](https://github.com/TheBoredTeam)
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** - Now Playing integration
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** - Shelf feature inspiration
- Icon: [@maxtron95](https://github.com/maxtron95)
- Website: [@himanshhhhuv](https://github.com/himanshhhhuv)

### Fork Additions
Claude Code integration developed with assistance from Claude.

---

## License

This project maintains the same license as the original boring.notch project. See [LICENSE](./LICENSE) for details.

For third-party licenses, see [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md).
