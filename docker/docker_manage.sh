#!/usr/bin/env bash
#
# Copyright (C) 2023 zxcvos
#
# documentation: https://docs.docker.com/engine/install/

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/snap/bin
export PATH

# color
readonly RED='\033[1;31;31m'
readonly GREEN='\033[1;31;32m'
readonly YELLOW='\033[1;31;33m'
readonly NC='\033[0m'

# optional
declare is_install=0
declare is_update=0
declare is_remove=0

# status print
function _info() {
  printf "${GREEN}[Info] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
}

function _warn() {
  printf "${YELLOW}[Warning] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
}

function _error() {
  printf "${RED}[Error] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
  exit 1
}

# tools
function _exists() {
  local cmd="$1"
  if eval type type >/dev/null 2>&1; then
    eval type "$cmd" >/dev/null 2>&1
  elif command >/dev/null 2>&1; then
    command -v "$cmd" >/dev/null 2>&1
  else
    which "$cmd" >/dev/null 2>&1
  fi
  local rt=$?
  return ${rt}
}

function _os() {
  local os=""
  [ -f "/etc/debian_version" ] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
  [ -f "/etc/redhat-release" ] && os="centos" && printf -- "%s" "${os}" && return
}

function _os_full() {
  [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

function _os_ver() {
  local main_ver="$(echo $(_os_full) | grep -oE "[0-9.]+")"
  printf -- "%s" "${main_ver%%.*}"
}

function check_os() {
  [ -z "$(_os)" ] && _error "Not supported OS"
  case "$(_os)" in
  ubuntu)
    [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 18 ] && _error "Not supported OS, please change to Ubuntu 18+ and try again."
    ;;
  debian)
    [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 10 ] && _error "Not supported OS, please change to Debian 10+ and try again."
    ;;
  centos)
    [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 7 ] && _error "Not supported OS, please change to CentOS 7+ and try again."
    ;;
  *)
    _error "Not supported OS"
    ;;
  esac
}

# install or update
function install_docker() {
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      sudo dnf update -y
      sudo dnf install -y dnf-plugins-core
      sudo dnf update -y
      sudo dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --allowerasing
    else
      sudo yum update -y
      sudo yum install -y epel-release yum-utils
      sudo yum update -y
      sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
      sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    ;;
  debian | ubuntu)
    sudo apt-get update -y
    sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(_os)/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(_os) \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ;;
  esac
}

# remove
function remove_docker() {
  case "$(_os)" in
  centos)
    local PKG="sudo yum"
    if _exists "dnf"; then
      PKG="sudo dnf"
    fi
    ${PKG} remove docker \
      docker-client \
      docker-client-latest \
      docker-common \
      docker-latest \
      docker-latest-logrotate \
      docker-logrotate \
      docker-engine
    ;;
  debian | ubuntu)
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    ;;
  esac
}

check_os

while [[ $# -ge 1 ]]; do
  case "${1}" in
  -i | --install)
    shift
    is_install=1
    ;;
  -u | --update)
    shift
    is_update=1
    ;;
  -r | --remove)
    shift
    is_remove=1
    ;;
  -h | --help)
    cat <<EOF
Usage: $0 [options]

Options:
  -i, --install      Install Docker
  -u, --update       Update Docker
  -r, --remove       Remove Docker

Examples:
  $0 -i    # Install Docker
  $0 -u    # Update Docker
  $0 -r    # Remove Docker
EOF
    ;;
  *)
    _error "Invalid option: '$1'. Use '$0 -h/--help' for usage information."
    ;;
  esac
done

if [[ ${is_install} -eq 1 ]]; then
  remove_docker
  install_docker
elif [[ ${is_update} -eq 1 ]]; then
  install_docker
elif [[ ${is_remove} -eq 1 ]]; then
  remove_docker
fi
