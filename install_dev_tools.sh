#!/usr/bin/env bash
# install_dev_tools.sh — Amazon Linux 2023 only
# Устанавливает: Docker, Docker Compose (как плагин и как бинарник), Python3, Django (в venv)
set -euo pipefail

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
log(){ echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR]${NC} $*"; }

command_exists(){ command -v "$1" >/dev/null 2>&1; }
version_ge() ( printf '%s\n%s\n' "$1" "$2" | sort -V -C )

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
VENV_DIR="$TARGET_HOME/devtools_venv"

log "Running as $USER (target user: $TARGET_USER, home: $TARGET_HOME)"

# Чистим старый битый репозиторий Docker CE, если он когда-то добавлялся
cleanup_docker_ce_repo(){
  if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
    sudo rm -f /etc/yum.repos.d/docker-ce.repo
    sudo dnf clean all
    sudo dnf makecache
    log "Removed legacy docker-ce.repo and refreshed dnf cache"
  fi
}

install_docker(){
  if command_exists docker; then
    log "Docker already installed: $(docker --version)"
    return
  fi
  log "Installing Docker (Amazon repo)…"
  sudo dnf update -y
  sudo dnf install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$TARGET_USER" || true
  log "Docker installed: $(docker --version)"
  warn "Relogin may be required for $TARGET_USER to use docker without sudo."
}

install_compose(){
  # 1) Пытаемся как подкоманду: docker compose
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose available as plugin: $(docker compose version)"
    return
  fi
  # 2) Пытаемся как отдельный бинарник: docker-compose
  if command_exists docker-compose; then
    log "Docker Compose standalone present: $(docker-compose version)"
  fi

  log "Installing Docker Compose v2 as CLI plugin + standalone…"
  # Папки плагинов (для docker compose)
  # docker ищет плагин в этих путях — используем оба на всякий случай.
  sudo install -d -m 0755 /usr/libexec/docker/cli-plugins
  sudo install -d -m 0755 /usr/local/lib/docker/cli-plugins

  # Качаем последнюю стабильную сборку x86_64
  TMP=$(mktemp)
  curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o "$TMP"

  # Устанавливаем как плагин (чтобы работало `docker compose …`)
  sudo install -m 0755 "$TMP" /usr/libexec/docker/cli-plugins/docker-compose
  sudo install -m 0755 "$TMP" /usr/local/lib/docker/cli-plugins/docker-compose

  # Устанавливаем также как отдельный бинарник (чтобы работало `docker-compose …`)
  sudo install -m 0755 "$TMP" /usr/local/bin/docker-compose
  rm -f "$TMP"

  # Проверка
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose plugin ready: $(docker compose version)"
  else
    warn "docker compose not found after install (check PATH/permissions)"
  fi
  if command_exists docker-compose; then
    log "Docker Compose standalone ready: $(docker-compose version)"
  else
    warn "docker-compose not found after install (check /usr/local/bin)"
  fi
}

install_python(){
  if command_exists python3; then
    PYV=$(python3 -V | awk '{print $2}')
    if version_ge "$PYV" "3.9"; then
      log "Python already installed: python3 $PYV"
      return
    fi
  fi
  log "Installing Python3 + pip…"
  sudo dnf install -y python3 python3-pip
  log "Python installed: $(python3 -V)"
}

install_django(){
  if [[ ! -d "$VENV_DIR" ]]; then
    log "Creating venv: $VENV_DIR"
    sudo -u "$TARGET_USER" bash -lc "python3 -m venv '$VENV_DIR'"
  fi
  sudo -u "$TARGET_USER" bash -lc "
    source '$VENV_DIR/bin/activate'
    if python -m django --version >/dev/null 2>&1; then
      echo '[OK] Django already in venv: ' \$(python -m django --version)
    else
      pip install --upgrade pip
      pip install 'django>=4'
      echo '[OK] Installed Django: ' \$(python -m django --version)
    fi
  "
  echo
  echo -e "${YELLOW}To use Django:${NC}"
  echo "source \"$VENV_DIR/bin/activate\""
  echo "django-admin --version"
}

summary(){
  echo -e "\n${GREEN}=== Installation Summary ===${NC}"
  command_exists docker && echo "Docker: $(docker --version)" || echo "Docker: not installed"
  (docker compose version >/dev/null 2>&1 && echo "Compose (plugin): $(docker compose version)") || echo "Compose (plugin): not available"
  (command_exists docker-compose && echo "Compose (standalone): $(docker-compose version)") || echo "Compose (standalone): not installed"
  command_exists python3 && echo "Python: $(python3 -V)" || echo "Python: not installed"
  [[ -f "$VENV_DIR/bin/activate" ]] && echo "Django venv: $VENV_DIR" || echo "Django: not installed"
  echo "============================="
}

main(){
  cleanup_docker_ce_repo
  install_docker
  install_compose
  install_python
  install_django
  summary
  log "All done! 🚀"
}

main "$@"
