# Installing Superpowers for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed
- Git installed

## Quick Install

```bash
git clone https://github.com/obra/superpowers.git ~/.config/opencode/superpowers
~/.config/opencode/superpowers/install-opencode.sh
```

Restart OpenCode. Skills are now discoverable via the native `skill` tool.

## What the Installer Does

- Symlinks skills from `skills/` to `~/.config/opencode/skill/`
- Symlinks agents from `agents/` to `~/.config/opencode/agent/`
- Symlinks commands from `commands/` to `~/.config/opencode/command/`

## Usage

Skills are available via OpenCode's native `skill` tool. The agent sees available
skills in the tool description and can load them by name:

```
skill({ name: "brainstorming" })
```

### Personal Skills

Create your own skills in `~/.config/opencode/skill/`:

```bash
mkdir -p ~/.config/opencode/skill/my-skill
```

Create `~/.config/opencode/skill/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition]
---

# My Skill

[Your skill content here]
```

### Project Skills

Create project-specific skills in your project:

```bash
mkdir -p .opencode/skill/my-project-skill
```

OpenCode discovers skills from both project and global locations.

## Updating

```bash
cd ~/.config/opencode/superpowers
git pull
./install-opencode.sh
```

## Uninstalling

```bash
~/.config/opencode/superpowers/install-opencode.sh --uninstall
```

## Troubleshooting

### Collision detected

The installer aborts if a skill, agent, or command name already exists and points
to a different location. This prevents overwriting another plugin's files.

To resolve:
1. Remove the conflicting symlink manually, or
2. Rename the superpowers file to avoid the conflict

### Skills not found

1. Verify symlinks exist: `ls -la ~/.config/opencode/skill/`
2. Check that skill directories contain `SKILL.md` files
3. Restart OpenCode after installation

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Documentation: https://github.com/obra/superpowers
