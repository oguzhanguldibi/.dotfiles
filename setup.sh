#!/usr/bin/env bash

set -euo pipefail

readonly DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CODEX_SOURCE="${DOTFILES_DIR}/codex/config.toml"
readonly CODEX_DIR="${HOME}/.codex"
readonly CODEX_TARGET="${CODEX_DIR}/config.toml"
readonly DOTFILES_NVM_DIR="${NVM_DIR:-${HOME}/.nvm}"

install_codex_config() {
  mkdir -p "${CODEX_DIR}"

  if [[ -e "${CODEX_TARGET}" || -L "${CODEX_TARGET}" ]]; then
    if cmp -s "${CODEX_SOURCE}" "${CODEX_TARGET}"; then
      printf 'Codex config is already current.\n'
      return
    fi

    local backup
    backup="${CODEX_TARGET}.backup.$(date +%Y%m%d%H%M%S)"
    mv "${CODEX_TARGET}" "${backup}"
    printf 'Backed up the existing Codex config to %s\n' "${backup}"
  fi

  install -m 600 "${CODEX_SOURCE}" "${CODEX_TARGET}"
  printf 'Installed Codex config at %s\n' "${CODEX_TARGET}"
}

shell_profile() {
  case "${SHELL:-}" in
    */zsh) printf '%s\n' "${HOME}/.zshrc" ;;
    */bash) printf '%s\n' "${HOME}/.bashrc" ;;
    *) printf '%s\n' "${HOME}/.profile" ;;
  esac
}

install_nvm() {
  local profile
  profile="$(shell_profile)"
  touch "${profile}"

  local installer
  installer="$(mktemp)"

  curl -fsSL \
    "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" \
    -o "${installer}" || {
    rm -f "${installer}"
    return 1
  }
  PROFILE="${profile}" NVM_DIR="${DOTFILES_NVM_DIR}" bash "${installer}" || {
    rm -f "${installer}"
    return 1
  }
  rm -f "${installer}"

  export NVM_DIR="${DOTFILES_NVM_DIR}"
  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"

  printf 'NVM %s is ready.\n' "$(nvm --version)"
  printf 'To install Node 24 once, run: nvm install 24\n'
  printf 'After that, switch to it with: nvm use 24\n'
}

case "${1:-all}" in
  all)
    install_codex_config
    install_nvm
    ;;
  --codex-only)
    install_codex_config
    ;;
  --nvm-only)
    install_nvm
    ;;
  *)
    printf 'Usage: %s [--codex-only|--nvm-only]\n' "$0" >&2
    exit 2
    ;;
esac
