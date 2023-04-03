#!/usr/bin/env bash

# Author: zxcvos
# Version: 0.1
# Date: 2023-04-01

readonly RED='\033[1;31;31m'
readonly GREEN='\033[1;31;32m'
readonly YELLOW='\033[1;31;33m'
readonly NC='\033[0m'

readonly op_regex='^(^--(help|update|purge|issue|(stop-)?renew|check-cron|info|domain|type|nginx|webroot|ssl)$)|(^-[upirscdtnws]$)$'
readonly website_type=('cloudreve' 'vaultwarden' 'reader')

declare is_update=0
declare is_purge=0
declare is_issue=0
declare is_renew=0
declare is_stop_renew=0
declare is_check_cron=0
declare is_show_info=0
declare domain=''
declare default_domain=''
declare cloudreve_domain=''
declare vaultwarden_domain=''
declare reader_domain=''
declare pick_type=0
declare nginx_path=''
declare webroot_path=''
declare ssl_path=''

function _info() {
  printf "${GREEN}[Info] ${NC}"
  printf -- "%s" "$1"
  printf "\n"
}

function _warn() {
  printf "${YELLOW}[Warning] ${NC}"
  printf -- "%s" "$1"
  printf "\n"
}

function _error() {
  printf "${RED}[Error] ${NC}"
  printf -- "%s" "$1"
  printf "\n"
  exit 1
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
    domain="$1"
    shift
    ;;
  -t | --type)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'type not provided'
    pick_type="$1"
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
  -s | --ssl)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && _error 'ssl directory path not provided'
    ssl_path="$1"
    shift
    ;;
  *)
    echo -ne "\nInvalid option: '$1'.\n"
    ;;
  esac
done

function install_acme_sh() {
  curl https://get.acme.sh | sh
  ${HOME}/.acme.sh/acme.sh --upgrade --auto-upgrade
  ${HOME}/.acme.sh/acme.sh --set-default-ca --server letsencrypt
}

function update_acme_sh() {
  ${HOME}/.acme.sh/acme.sh --upgrade
}

function purge_acme_sh() {
  ${HOME}/.acme.sh/acme.sh --upgrade --auto-upgrade 0
  ${HOME}/.acme.sh/acme.sh --uninstall
  rm -rf ${HOME}/.acme.sh
  rm -rf "${webroot_path}"
  rm -rf "${ssl_path}"
}

function issue_cert() {
  [ -d "${webroot_path}" ] || mkdir -p "${webroot_path}"
  [ -d "${ssl_path}/${domain}" ] || mkdir -p "${ssl_path}/${domain}"
  sed -i -r 's/(listen .*443)/\1; #/g; s/(ssl_(certificate|certificate_key) )/#;#\1/g; s/(server \{)/\1\n    ssl off;/g' ${nginx_path}/sites-available/${domain}.conf
  grep -Eqv '^#' ${nginx_path}/conf.d/restrict.conf && sed -i 's/^/#/' ${nginx_path}/conf.d/restrict.conf
  nginx -t && _systemctl "restart" "nginx"
  ${HOME}/.acme.sh/acme.sh --issue --server letsencrypt ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --webroot /var/www/_letsencrypt --keylength ec-256 --accountkeylength ec-256 --ocsp
  [ $? -ne 0 ] && ${HOME}/.acme.sh/acme.sh --issue --server letsencrypt ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --webroot /var/www/_letsencrypt --keylength ec-256 --accountkeylength ec-256 --ocsp --debug && _error 'Issue cert error'
  sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' ${nginx_path}/sites-available/${domain}.conf
  sed -i 's/^#//' ${nginx_path}/conf.d/restrict.conf
  ${HOME}/.acme.sh/acme.sh --install-cert --ecc ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --key-file ${nginx_path}/ssl/${domain}/privkey.pem --fullchain-file ${nginx_path}/ssl/${domain}/fullchain.pem --reloadcmd "nginx -t && systemctl reload nginx"
}

function renew_cert() {
  ${HOME}/.acme.sh/acme.sh --cron --force
}

function stop_renew_cert() {
  ${HOME}/.acme.sh/acme.sh --remove ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --ecc
}

function check_cron() {
  ${HOME}/.acme.sh/acme.sh --cron --home ${HOME}/.acme.sh
}

function info_cert() {
  ${HOME}/.acme.sh/acme.sh --info -d ${domain}
}

if [[ "${domain}" ]]; then
  default_domain="-d ${domain} -d www.${domain}"
else
  _error "domain not provided"
fi

if [[ -z "${nginx_path}" ]]; then
  if [[ -d /etc/nginx ]]; then
    nginx_path="/etc/nginx"
  elif [[ -d /usr/local/nginx/conf ]]; then
    nginx_path="/usr/local/nginx/conf"
  else
    _error 'nginx configuration path not found'
  fi
fi

if [[ -z "${webroot_path}" ]]; then
  webroot_path="/var/www/_letsencrypt"
fi

if [[ -z "${ssl_path}" ]]; then
  ssl_path="${nginx_path}/ssl"
fi

case "${pick_type}" in
1)
  cloudreve_domain="-d pan.${domain}"
  ;;
2)
  vaultwarden_domain="-d vw.${domain}"
  ;;
3)
  reader_domain="-d read.${domain}"
  ;;
*)
  cloudreve_domain=""
  vaultwarden_domain=""
  reader_domain=""
  ;;
esac

[ ! -d ${HOME}/.acme.sh ] && install_acme_sh

if [[ ${is_update} -eq 1 ]]; then
  update_acme_sh
fi

if [[ ${is_purge} -eq 1 ]]; then
  purge_acme_sh
fi

if [[ ${is_issue} -eq 1 ]]; then
  issue_cert
fi

if [[ ${is_check_cron} -eq 1 ]]; then
  check_cron
fi

if [[ ${is_renew} -eq 1 ]]; then
  renew_cert
fi

if [[ ${is_stop_renew} -eq 1 ]]; then
  stop_renew_cert
fi

if [[ ${is_show_info} -eq 1 ]]; then
  info_cert
fi
