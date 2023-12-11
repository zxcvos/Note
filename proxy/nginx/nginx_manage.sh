#!/usr/bin/env bash
#
# Copyright (C) 2023 zxcvos
#
# documentation: https://nginx.org/en/linux_packages.html
# update: https://zhuanlan.zhihu.com/p/193078620
# gcc: https://github.com/kirin10000/Xray-script

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/snap/bin
export PATH

trap egress EXIT

# color
readonly RED='\033[1;31;31m'
readonly GREEN='\033[1;31;32m'
readonly YELLOW='\033[1;31;33m'
readonly NC='\033[0m'

# directory
readonly CUR_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
readonly TMPFILE_DIR="$(mktemp -d -p "${CUR_DIR}" -t nginxtemp.XXXXXXXX)" || exit 1

# optional
declare is_install=1
declare is_compile=0
declare is_update=0
declare is_purge=0
declare is_with_log=0

# exit process
function egress() {
  [[ -e ${TMPFILE_DIR}/swap ]] && swapoff ${TMPFILE_DIR}/swap
  rm -rf ${TMPFILE_DIR}
}

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

function _error_detect() {
  local cmd="$1"
  _info "${cmd}"
  eval ${cmd}
  if [ $? -ne 0 ]; then
    _error "Execution command (${cmd}) failed, please check it and try again."
  fi
}

function _version_ge() {
  test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

function _install() {
  local package_name="$@"
  case "$(_os)" in
  centos)
    if _exists "yum"; then
      yum update -y
      _error_detect "yum install -y epel-release yum-utils"
      yum update -y
      _error_detect "yum install -y ${package_name}"
    elif _exists "dnf"; then
      dnf update -y
      _error_detect "dnf install -y dnf-plugins-core"
      dnf update -y
      _error_detect "dnf install -y ${package_name}"
    fi
    ;;
  ubuntu | debian)
    apt update -y
    _error_detect "apt install -y ${package_name}"
    ;;
  esac
}

function _update() {
  local package_name="$@"
  case "$(_os)" in
  centos)
    if _exists "yum"; then
      yum update -y
      _error_detect "yum update -y ${package_name}"
    elif _exists "dnf"; then
      dnf update -y
      _error_detect "dnf update -y ${package_name}"
    fi
    ;;
  ubuntu | debian)
    apt update -y
    _error_detect "apt upgrade -y ${package_name}"
    ;;
  esac
}

function _purge() {
  local package_name="$@"
  case "$(_os)" in
  centos)
    if _exists "yum"; then
      yum purge -y ${package_name}
      yum autoremove -y
    elif _exists "dnf"; then
      dnf purge -y ${package_name}
      dnf autoremove -y
    fi
    ;;
  ubuntu | debian)
    apt purge -y ${package_name}
    apt autoremove -y
    ;;
  esac
}

# check os
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

# swap
function swap_on() {
  local mem=${1}
  if [[ ${mem} -ne '0' ]]; then
    if dd if=/dev/zero of=${TMPFILE_DIR}/swap bs=1M count=${mem} 2>&1; then
      chmod 0600 ${TMPFILE_DIR}/swap
      mkswap ${TMPFILE_DIR}/swap
      swapon ${TMPFILE_DIR}/swap
    fi
  fi
}

# backup file
function backup_files() {
  local backup_dir="$1"
  local current_date=$(date +%F)

  for file in "${backup_dir}/"*; do
    if [ -f "$file" ]; then
      local file_name=$(basename "$file")
      local backup_file="${backup_dir}/${file_name}_${current_date}"
      mv "$file" "$backup_file"
      echo "Backup: ${file} -> ${backup_file}"
    fi
  done
}

# dependencies
function install_dependencies() {
  case "$(_os)" in
  centos)
    echo "W25naW54LXN0YWJsZV0KbmFtZT1uZ2lueCBzdGFibGUgcmVwbwpiYXNldXJsPWh0dHBzOi8vbmdpbngub3JnL3BhY2thZ2VzL2NlbnRvcy8kcmVsZWFzZXZlci8kYmFzZWFyY2gvCmdwZ2NoZWNrPTEKZW5hYmxlZD0xCmdwZ2tleT1odHRwczovL25naW54Lm9yZy9rZXlzL25naW54X3NpZ25pbmcua2V5Cm1vZHVsZV9ob3RmaXhlcz10cnVlCgpbbmdpbngtbWFpbmxpbmVdCm5hbWU9bmdpbnggbWFpbmxpbmUgcmVwbwpiYXNldXJsPWh0dHBzOi8vbmdpbngub3JnL3BhY2thZ2VzL21haW5saW5lL2NlbnRvcy8kcmVsZWFzZXZlci8kYmFzZWFyY2gvCmdwZ2NoZWNrPTEKZW5hYmxlZD0wCmdwZ2tleT1odHRwczovL25naW54Lm9yZy9rZXlzL25naW54X3NpZ25pbmcua2V5Cm1vZHVsZV9ob3RmaXhlcz10cnVl" | base64 -d >/etc/yum.repos.d/nginx.repo
    ;;
  debian | ubuntu)
    [ "debian" -eq "$(_os)" ] && _install "debian-archive-keyring" || _install "ubuntu-keyring"
    rm -rf /etc/apt/sources.list.d/nginx.list
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor |
      sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
            http://nginx.org/packages/$(_os) $(lsb_release -cs) nginx" |
      sudo tee /etc/apt/sources.list.d/nginx.list
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" |
      sudo tee /etc/apt/preferences.d/99nginx
    ;;
  esac
}

function compile_dependencies() {
  case "$(_os)" in
  centos)
    # toolchains
    _install ca-certificates wget gcc gcc-c++ make perl-IPC-Cmd perl-Getopt-Long perl-Data-Dumper perl-FindBin
    # dependencies
    _install pcre2-devel zlib-devel libxml2-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed gperftools-devel perl-devel
    ;;
  debian | ubuntu)
    # toolchains
    _install ca-certificates wget gcc g++ make perl-base perl
    # dependencies
    _install libpcre2-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev
    ;;
  esac
}

function acme_dependencies() {
  case "$(_os)" in
  centos)
    _install curl openssl crontabs
    ;;
  debian | ubuntu)
    _install curl openssl cron
    ;;
  esac
}

# cflags
function gen_cflags() {
  cflags=('-g0' '-O3')
  if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-reuse"; then
    cflags+=('-fstack-reuse=all')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fdwarf2\\-cfi\\-asm"; then
    cflags+=('-fdwarf2-cfi-asm')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fplt"; then
    cflags+=('-fplt')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-ftrapv"; then
    cflags+=('-fno-trapv')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fexceptions"; then
    cflags+=('-fno-exceptions')
  elif gcc -v --help 2>&1 | grep -qw "\\-fhandle\\-exceptions"; then
    cflags+=('-fno-handle-exceptions')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-funwind\\-tables"; then
    cflags+=('-fno-unwind-tables')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fasynchronous\\-unwind\\-tables"; then
    cflags+=('-fno-asynchronous-unwind-tables')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-check"; then
    cflags+=('-fno-stack-check')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-clash\\-protection"; then
    cflags+=('-fno-stack-clash-protection')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fstack\\-protector"; then
    cflags+=('-fno-stack-protector')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fcf\\-protection="; then
    cflags+=('-fcf-protection=none')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fsplit\\-stack"; then
    cflags+=('-fno-split-stack')
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-fsanitize"; then
    >temp.c
    if gcc -E -fno-sanitize=all temp.c >/dev/null 2>&1; then
      cflags+=('-fno-sanitize=all')
    fi
    rm temp.c
  fi
  if gcc -v --help 2>&1 | grep -qw "\\-finstrument\\-functions"; then
    cflags+=('-fno-instrument-functions')
  fi
}

# install by pkg
function pkg_install() {
  _info "Installing dependencies"
  install_dependencies
  _info "Installing Nginx"
  _install "nginx"
}

# source compile
function source_compile() {
  cd ${TMPFILE_DIR}
  _info "Installing toolchains and dependencies"
  compile_dependencies
  _info "Retrieve the latest versions of Nginx and OpenSSL"
  local nginx_version="$(wget -qO- --no-check-certificate https://api.github.com/repos/nginx/nginx/tags | grep 'name' | cut -d\" -f4 | grep 'release' | head -1 | sed 's/release/nginx/')"
  local openssl_version="openssl-$(wget -qO- --no-check-certificate https://api.github.com/repos/openssl/openssl/tags | grep 'name' | cut -d\" -f4 | grep -Eoi '^openssl-([0-9]\.?){3}$' | head -1)"
  gen_cflags
  _info "Download the latest versions of Nginx"
  _error_detect "wget -O ${nginx_version}.tar.gz https://nginx.org/download/${nginx_version}.tar.gz"
  tar -zxf ${nginx_version}.tar.gz
  _info "Download the latest versions of OpenSSL"
  _error_detect "wget -O ${openssl_version}.tar.gz https://github.com/openssl/openssl/archive/${openssl_version#*-}.tar.gz"
  tar -zxf ${openssl_version}.tar.gz
  cd ${nginx_version}
  sed -i "s/OPTIMIZE[ \\t]*=>[ \\t]*'-O'/OPTIMIZE          => '-O3'/g" src/http/modules/perl/Makefile.PL
  sed -i 's/NGX_PERL_CFLAGS="$CFLAGS `$NGX_PERL -MExtUtils::Embed -e ccopts`"/NGX_PERL_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  sed -i 's/NGX_PM_CFLAGS=`$NGX_PERL -MExtUtils::Embed -e ccopts`/NGX_PM_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  ./configure --prefix="/usr/local/nginx" --user=root --group=root --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-google_perftools_module --with-compat --with-cc-opt="${cflags[*]}" --with-openssl="../${openssl_version}" --with-openssl-opt="${cflags[*]}"
  swap_on 512
  _info "Compiling Nginx"
  _error_detect "make -j$(nproc)"
}

# install by source
function source_install() {
  source_compile
  _info "Installing Nginx"
  make install
  ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx
}

# update by pkg
function pkg_update() {
  _info "Updating Nginx"
  _update "nginx"
}

# update by source
function source_update() {
  local latest_nginx_version="$(wget -qO- --no-check-certificate https://api.github.com/repos/nginx/nginx/tags | grep 'name' | cut -d\" -f4 | grep 'release' | head -1 | sed 's/release/nginx/')"
  local latest_openssl_version="$(wget -qO- --no-check-certificate https://api.github.com/repos/openssl/openssl/tags | grep 'name' | cut -d\" -f4 | grep -Eoi '^openssl-([0-9]\.?){3}$' | head -1)"
  local current_version_nginx="$(nginx -V 2>&1 | grep "^nginx version:.*" | cut -d / -f 2)"
  local current_version_openssl="$(nginx -V 2>&1 | grep "^built with OpenSSL" | awk '{print $4}')"
  if _version_ge ${latest_nginx_version#*-} ${current_version_nginx} || _version_ge ${latest_openssl_version#*-} ${current_version_openssl}; then
    source_compile
    mv /usr/local/nginx/sbin/nginx /usr/local/nginx/sbin/nginx_$(date +%F)
    backup_files /usr/local/nginx/modules
    cp objs/nginx /usr/local/nginx/sbin/
    cp objs/*.so /usr/local/nginx/modules/
    ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx
    if systemctl is-active --quiet nginx; then
      kill -USR2 $(cat /run/nginx.pid)
      if [ -e "/run/nginx.pid.oldbin" ]; then
        kill -WINCH $(cat /run/nginx.pid.oldbin)
        kill -HUP $(cat /run/nginx.pid.oldbin)
        kill -QUIT $(cat /run/nginx.pid.oldbin)
      else
        echo "Old Nginx process not found. Skipping further steps."
      fi
    fi
  fi
}

# purge
function purge_nginx() {
  systemctl stop nginx
  systemctl disable nginx
  if [[ -d /usr/local/nginx ]]; then
    rm -rf /usr/local/nginx
    rm -rf /usr/sbin/nginx
  else
    _purge "nginx"
    rm -rf /etc/nginx
  fi
  rm -rf /etc/systemd/system/nginx.service
  rm -rf /var/log/nginx
  systemctl daemon-reload
}

function systemctl_config() {
  cat >/etc/systemd/system/nginx.service <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/bin/rm -rf /dev/shm/nginx
ExecStartPre=/bin/mkdir /dev/shm/nginx
ExecStartPre=/bin/chmod 660 /dev/shm/nginx
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
ExecStopPost=/bin/rm -rf /dev/shm/nginx
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  if [[ ${is_compile} -eq 1 ]]; then
    sed -i '/chmod 660/a ExecStartPre=/bin/mkdir /dev/shm/nginx/tcmalloc' /etc/systemd/system/nginx.service
    sed -i '/tcmalloc/a ExecStartPre=/bin/chmod 0777 /dev/shm/nginx/tcmalloc' /etc/systemd/system/nginx.service
  fi
  systemctl daemon-reload
}

function nginx_config() {
  local nginx_path=/usr/local/nginx/conf
  if [[ ${is_compile} -ne 1 ]]; then
    nginx_path=/etc/nginx
  fi
  cd ${nginx_path}
  echo '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' | base64 --decode | tee ${nginx_path}/nginxconfig.io-example.com.tar.gz >/dev/null
  tar -xzvf nginxconfig.io-example.com.tar.gz | xargs chmod 0644
  sed -i "s|/usr/local/nginx/conf|${nginx_path}|g" nginx.conf
  [[ ${is_compile} -eq 1 ]] && sed -i "/modules-enabled/a google_perftools_profiles /dev/shm/nginx/tcmalloc/tcmalloc;" nginx.conf
  sed -i "/worker_connections/a \    use                epoll;" nginx.conf
  sed -i "/ssl_protocols/i \    ssl_prefer_server_ciphers on;" nginx.conf
  sed -i "/# Diffie-Hellman parameter for DHE ciphersuites/,/ssl_dhparam/d" nginx.conf
  sed -i "/ssl_trusted_certificate/d" sites-available/example.com.conf
  sed -i "s|max-age=31536000|max-age=63072000|" nginxconfig.io/security.conf
}

check_os

while [[ $# -ge 1 ]]; do
  case "${1}" in
  -i | --install)
    shift
    is_install=1
    ;;
  -c | --compile)
    shift
    is_compile=1
    ;;
  -u | --update)
    shift
    is_update=1
    ;;
  -p | --purge)
    shift
    is_purge=1
    ;;
  --with-log)
    shift
    is_with_log=1
    ;;
  -h | --help)
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --install      Install Nginx (default if no option provided)"
    echo "  -c, --compile      Compile and install Nginx from source"
    echo "  -u, --update       Update Nginx (detects if installed from package or source)"
    echo "  -p, --purge        Uninstall and purge Nginx"
    echo "  --with-log         Include log configurations"
    echo ""
    echo "Note:"
    echo "  - The '-u' option is designed for updating Nginx installed through this script."
    echo "    If Nginx was not installed by this script, using '-u' may lead to unexpected behavior."
    exit 0
    ;;
  *)
    _error "Invalid option: '$1'. Use '$0 -h/--help' for usage information."
    ;;
  esac
done

if [[ ${is_compile} -eq 1 ]]; then
  source_install
  systemctl_config
  nginx_config
elif [[ ${is_update} -eq 1 ]]; then
  if [[ -d /etc/nginx ]]; then
    pkg_update
  elif [[ -d /usr/local/nginx/conf ]]; then
    source_update
  fi
elif [[ ${is_purge} -eq 1 ]]; then
  purge_nginx
elif [[ ${is_install} -eq 1 ]]; then
  pkg_install
  systemctl_config
  nginx_config
fi
