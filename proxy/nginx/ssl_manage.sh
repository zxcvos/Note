#!/usr/bin/env bash

# Author: zxcvos
# Version: 0.1
# Date: 2023-04-01

readonly op_regex='^(^--(help|domain)$)|(^-[htpeundxl]$)$'
readonly website_type=('cloudreve' 'vaultwarden' 'reader')

declare domain=""
declare default_domain="-d ${domain} -d www.${domain}"
declare cloudreve_domain="-d pan.${domain}"
declare vaultwarden_domain="-d vw.${domain}"
declare reader_domain="-d read.${domain}"
declare nginx_path="/etc/nginx"
declare webroot_path="/var/www/_letsencrypt"
declare ssl_path="${nginx_path}/ssl"

while [[ $# -ge 1 ]]; do
  case "${1}" in
  -d | --domain)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && echo 'Error: domain not provided' && exit 1
    domain="$1"
    shift
    ;;
  -t | --type)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && echo 'Error: domain not provided' && exit 1
    domain="$1"
    shift
    ;;
  -n | --nginx)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && echo 'Error: domain not provided' && exit 1
    domain="$1"
    shift
    ;;
  -w | --webroot)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && echo 'Error: domain not provided' && exit 1
    domain="$1"
    shift
    ;;
  -s | --ssl)
    shift
    (printf "%s" "${1}" | grep -Eq "${op_regex}" || [ -z "$1" ]) && echo 'Error: domain not provided' && exit 1
    domain="$1"
    shift
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
    sed -i -r -z 's/#?; ?#//g; s/(server \{)\n    ssl off;/\1/g' ${nginx_path}/sites-available/${domain}.conf
    sed -i 's/^#//' ${nginx_path}/conf.d/restrict.conf
    ${HOME}/.acme.sh/acme.sh --install-cert --ecc ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --key-file ${nginx_path}/ssl/${domain}/privkey.pem --fullchain-file ${nginx_path}/ssl/${domain}/fullchain.pem --reloadcmd "nginx -t && systemctl reload nginx"
}

function renew_cert() {
    ${HOME}/.acme.sh/acme.sh --renew ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --force --ecc
}

function stop_renew_cert() {
    ${HOME}/.acme.sh/acme.sh --remove ${default_domain} ${cloudreve_domain} ${vaultwarden_domain} ${reader_domain} --ecc
}

function info_cert() {
    ${HOME}/.acme.sh/acme.sh --info ${default_domain}
}
