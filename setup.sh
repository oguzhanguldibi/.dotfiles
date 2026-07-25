#!/usr/bin/env bash

set -euo pipefail

readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_HOME="${DOTFILES_HOME:-${HOME}}"
readonly CODEX_SOURCE="${DOTFILES_DIR}/codex/config.toml"
readonly GHOSTTY_SOURCE="${DOTFILES_DIR}/ghostty/config"
readonly TMUX_SOURCE="${DOTFILES_DIR}/tmux/tmux.conf"
readonly VSCODE_SOURCE="${DOTFILES_DIR}/vscode/settings.json"
readonly NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh"
readonly DOTFILES_NVM_DIR="${NVM_DIR:-${DOTFILES_HOME}/.nvm}"

backup_target() {
  local target="$1"
  local timestamp
  timestamp="$(date +%Y%m%d%H%M%S)"
  local backup="${target}.backup.${timestamp}"
  local suffix=0

  while [[ -e "${backup}" || -L "${backup}" ]]; do
    suffix=$((suffix + 1))
    backup="${target}.backup.${timestamp}.${suffix}"
  done

  mv "${target}" "${backup}"
  printf 'Backed up %s to %s\n' "${target}" "${backup}"
}

install_file() {
  local name="$1"
  local source="$2"
  local target="$3"
  local mode="$4"

  mkdir -p "$(dirname "${target}")"

  if [[ -f "${target}" && ! -L "${target}" ]] &&
    cmp -s "${source}" "${target}"; then
    chmod "${mode}" "${target}"
    printf '%s is already current.\n' "${name}"
    return
  fi

  if [[ -e "${target}" || -L "${target}" ]]; then
    backup_target "${target}"
  fi

  cp "${source}" "${target}"
  chmod "${mode}" "${target}"
  printf 'Installed %s at %s\n' "${name}" "${target}"
}

vscode_target() {
  case "${DOTFILES_PLATFORM:-$(uname -s)}" in
    Darwin)
      printf '%s\n' "${DOTFILES_HOME}/Library/Application Support/Code/User/settings.json"
      ;;
    Linux)
      printf '%s\n' "${XDG_CONFIG_HOME:-${DOTFILES_HOME}/.config}/Code/User/settings.json"
      ;;
    *)
      printf 'Unsupported platform. Use macOS or Linux/WSL.\n' >&2
      return 1
      ;;
  esac
}

ghostty_target() {
  case "${DOTFILES_PLATFORM:-$(uname -s)}" in
    Darwin)
      printf '%s\n' "${DOTFILES_HOME}/Library/Application Support/com.mitchellh.ghostty/config"
      ;;
    Linux)
      printf '%s\n' "${XDG_CONFIG_HOME:-${DOTFILES_HOME}/.config}/ghostty/config"
      ;;
    *)
      printf 'Unsupported platform. Use macOS or Linux/WSL.\n' >&2
      return 1
      ;;
  esac
}

install_codex() {
  install_file \
    "Codex config" \
    "${CODEX_SOURCE}" \
    "${CODEX_HOME:-${DOTFILES_HOME}/.codex}/config.toml" \
    600
}

install_tmux() {
  install_file "tmux config" "${TMUX_SOURCE}" "${DOTFILES_HOME}/.tmux.conf" 644
}

install_vscode() {
  local target
  target="$(vscode_target)" || return
  install_file "VS Code settings" "${VSCODE_SOURCE}" "${target}" 644
}

install_ghostty() {
  local target
  target="$(ghostty_target)" || return
  install_file "Ghostty config" "${GHOSTTY_SOURCE}" "${target}" 644
}

shell_profile() {
  case "${SHELL:-}" in
    */zsh)
      printf '%s\n' "${ZDOTDIR:-${DOTFILES_HOME}}/.zshrc"
      ;;
    */bash)
      printf '%s\n' "${DOTFILES_HOME}/.bashrc"
      ;;
    *)
      printf '%s\n' "${DOTFILES_HOME}/.profile"
      ;;
  esac
}

download_file() {
  local url="$1"
  local target="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${url}" -o "${target}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${target}" "${url}"
  else
    printf 'Install curl or wget, then run setup again.\n' >&2
    return 1
  fi
}

install_nvm() {
  local profile
  profile="$(shell_profile)"
  mkdir -p "$(dirname "${profile}")"
  mkdir -p "${DOTFILES_NVM_DIR}"
  touch "${profile}"

  local installer
  installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-nvm.XXXXXX")"

  if ! download_file "${NVM_INSTALL_URL}" "${installer}"; then
    rm -f "${installer}"
    return 1
  fi

  if ! PROFILE="${profile}" NVM_DIR="${DOTFILES_NVM_DIR}" bash "${installer}"; then
    rm -f "${installer}"
    return 1
  fi
  rm -f "${installer}"

  export NVM_DIR="${DOTFILES_NVM_DIR}"
  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"
  printf 'NVM %s is ready.\n' "$(nvm --version)"
}

install_configs() {
  install_codex
  install_ghostty
  install_tmux
  install_vscode
}

case "${1:-all}" in
  all)
    install_configs
    install_nvm
    ;;
  --configs-only)
    install_configs
    ;;
  --codex-only)
    install_codex
    ;;
  --tmux-only)
    install_tmux
    ;;
  --vscode-only)
    install_vscode
    ;;
  --ghostty-only)
    install_ghostty
    ;;
  --nvm-only)
    install_nvm
    ;;
  *)
    printf 'Usage: %s [--configs-only|--codex-only|--ghostty-only|--tmux-only|--vscode-only|--nvm-only]\n' "$0" >&2
    exit 2
    ;;
esac
