# Dotfiles

Personal development settings for Linux and macOS.

## New computer

```sh
git clone https://github.com/oguzhanguldibi/.dotfiles.git ~/.dotfiles
bash ~/.dotfiles/setup.sh
```

The setup script:

1. Copies the sanitized Codex config to `~/.codex/config.toml`.
2. Backs up a different existing Codex config instead of deleting it.
3. Installs NVM `v0.40.4` without downloading a Node.js version.

Install Node 24 once, then select it:

```sh
nvm install 24
nvm use 24
```

Authentication, history, logs, caches, databases, project trust, and
machine-specific Codex state are intentionally excluded.
