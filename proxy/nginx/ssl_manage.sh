#!/usr/bin/env bash
#
# Copyright (C) 2023 zxcvos
#
# acme.sh: https://github.com/acmesh-official/acme.sh

# color
readonly RED='\033[1;31;31m'
readonly GREEN='\033[1;31;32m'
readonly YELLOW='\033[1;31;33m'
readonly NC='\033[0m'

# optional regex
readonly op_regex='(^--(help|update|purge|issue|(stop-)?renew|check-cron|info|www|domain|nginx|webroot|ssl)$)|(^-[upirscdnws]$)'

# optional
declare is_update=0
declare is_purge=0
declare is_issue=0
declare is_renew=0
declare is_stop_renew=0
declare is_check_cron=0
declare is_show_info=0

# optional value
declare domain=()
declare nginx_path=''
declare webroot_path=''
declare ssl_path=''

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

# install
function install_acme_sh() {
  curl https://get.acme.sh | sh
  ${HOME}/.acme.sh/acme.sh --upgrade --auto-upgrade
  ${HOME}/.acme.sh/acme.sh --set-default-ca --server letsencrypt
}

# update
function update_acme_sh() {
  ${HOME}/.acme.sh/acme.sh --upgrade
}

# purge
function purge_acme_sh() {
  ${HOME}/.acme.sh/acme.sh --upgrade --auto-upgrade 0
  ${HOME}/.acme.sh/acme.sh --uninstall
  rm -rf ${HOME}/.acme.sh
  rm -rf "${webroot_path}"
  rm -rf "${ssl_path}"
}

# issue
function issue_cert() {
  [ -d "${webroot_path}" ] || mkdir -p "${webroot_path}"
  [ -d "${ssl_path}" ] || mkdir -p "${ssl_path}"

  mv ${nginx_path}/nginx.conf ${nginx_path}/nginx.conf.bak
  cat >"${nginx_path}/nginx.conf" <<EOF
user                 root;
pid                  /run/nginx.pid;
worker_processes     1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        location ^~ /.well-known/acme-challenge/ {
            root /var/www/_letsencrypt;
        }
    }
}
EOF
  if systemctl is-active --quiet nginx; then
    nginx -t && systemctl reload nginx
  else
    nginx -t && systemctl start nginx
  fi

  ${HOME}/.acme.sh/acme.sh --issue $(printf -- " -d %s" "${domain[@]}") \
    --webroot ${webroot_path} \
    --keylength ec-256 \
    --accountkeylength ec-256 \
    --server letsencrypt \
    --ocsp

  mv -f ${nginx_path}/nginx.conf.bak ${nginx_path}/nginx.conf
  nginx -t && systemctl reload nginx

  ${HOME}/.acme.sh/acme.sh --install-cert --ecc $(printf -- " -d %s" "${domain[@]}") \
    --key-file "${ssl_path}/privkey.pem" \
    --fullchain-file "${ssl_path}/fullchain.pem" \
    --reloadcmd "nginx -t && systemctl reload nginx"
}

# renew
function renew_cert() {
  ${HOME}/.acme.sh/acme.sh --cron --force
}

# stop renew
function stop_renew_cert() {
  ${HOME}/.acme.sh/acme.sh --remove $(printf -- " -d %s" "${domain[@]}") --ecc
}

# check crontab
function check_cron() {
  ${HOME}/.acme.sh/acme.sh --cron --home ${HOME}/.acme.sh
}

# info
function info_cert() {
  ${HOME}/.acme.sh/acme.sh --info $(printf -- " -d %s" "${domain[@]}")
}

# help
function show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -u, --update        Update acme.sh"
  echo "  -p, --purge         Uninstall acme.sh and remove related directories"
  echo "  -i, --issue         Issue/renew SSL certificate"
  echo "  -r, --renew         Force renew all SSL certificates"
  echo "  -s, --stop-renew    Stop renewing the specified SSL certificate"
  echo "  -c, --check-cron    Check crontab settings for automatic renewal"
  echo "      --info          Show information about the SSL certificate"
  echo "  -d, --domain        Specify a domain (use multiple times for multiple domains)"
  echo "  -n, --nginx         Specify the Nginx configuration path"
  echo "  -w, --webroot       Specify the ACME-challenge directory path"
  echo "  -t, --tls           Specify the SSL directory path (default: based on the first domain)"
  echo "  -h, --help          Show this help message"
  echo ""
  exit 0
}

while [[ $# -ge 1 ]]; do
  case "${1}" in
  -u | --update)
    shift
    is_update=1
    ;;
  -p | --purge)
    shift
    is_purge=1
    ;;
  -i | --issue)
    shift
    is_issue=1
    ;;
  -r | --renew)
    shift
    is_renew=1
    ;;
  -s | --stop-renew)
    shift
    is_stop_renew=1
    ;;
  -c | --check-cron)
    shift
    is_check_cron=1
    ;;
  --info)
    shift
    is_show_info=1
    ;;
  -d | --domain)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'domain not provided'
    domain+=("$1")
    shift
    ;;
  -n | --nginx)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'nginx configuration path not provided'
    nginx_path="${1}"
    shift
    ;;
  -w | --webroot)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'ACME-challenge directory path not provided'
    webroot_path="$1"
    shift
    ;;
  -t | --tls)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'ssl directory path not provided'
    ssl_path="$1"
    shift
    ;;
  -h | --help)
    show_help
    ;;
  *)
    _error "Invalid option: '$1'. Use '$0 -h/--help' for usage information."
    ;;
  esac
done

if [[ ! -e ${HOME}/.acme.sh/acme.sh ]]; then
  install_acme_sh
fi

if [[ -z "${nginx_path}" ]]; then
  if [[ -d /etc/nginx ]]; then
    nginx_path="/etc/nginx"
  elif [[ -d /usr/local/nginx/conf ]]; then
    nginx_path="/usr/local/nginx/conf"
  else
    _error 'Nginx configuration path not found'
  fi
fi

if [[ -z "${webroot_path}" ]]; then
  webroot_path="/var/www/_letsencrypt"
fi

if [[ -z "${ssl_path}" ]]; then
  ssl_path="${nginx_path}/ssl/${domain[0]}"
fi

if [[ ${is_update} -eq 1 ]]; then
  update_acme_sh
elif [[ ${is_purge} -eq 1 ]]; then
  purge_acme_sh
elif [[ ${is_renew} -eq 1 ]]; then
  renew_cert
elif [[ ${is_check_cron} -eq 1 ]]; then
  check_cron
elif [[ ${#domain[@]} -gt 0 ]]; then
  if [[ ${is_issue} -eq 1 ]]; then
    issue_cert
  elif [[ ${is_stop_renew} -eq 1 ]]; then
    stop_renew_cert
  elif [[ ${is_show_info} -eq 1 ]]; then
    info_cert
  fi
fi
