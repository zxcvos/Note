#!/usr/bin/env bash
#
# Copyright (C) 2023 zxcvos
#
# documentation: https://nginx.org/en/linux_packages.html
# update: https://zhuanlan.zhihu.com/p/193078620
# gcc: https://github.com/kirin10000/Xray-script
# brotli: https://www.nodeseek.com/post-37224-1
# ngx_brotli: https://github.com/google/ngx_brotli

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
declare is_install=0
declare is_compile=0
declare is_update=0
declare is_purge=0
declare is_enable_brotli=0

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
  printf "${YELLOW}[Warn] ${NC}"
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
  [[ -f "/etc/debian_version" ]] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
  [[ -f "/etc/redhat-release" ]] && os="centos" && printf -- "%s" "${os}" && return
}

function _os_full() {
  [[ -f /etc/redhat-release ]] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
  [[ -f /etc/os-release ]] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
  [[ -f /etc/lsb-release ]] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

function _os_ver() {
  local main_ver="$(echo $(_os_full) | grep -oE "[0-9.]+")"
  printf -- "%s" "${main_ver%%.*}"
}

function _error_detect() {
  local cmd="$1"
  _info "${cmd}"
  eval ${cmd}
  if [[ $? -ne 0 ]]; then
    _error "Execution command (${cmd}) failed, please check it and try again."
  fi
}

function _version_ge() {
  test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"
}

function _install() {
  local packages_name="$@"
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      dnf update -y
      dnf install -y dnf-plugins-core
      if [[ -n "$(_os_ver)" && "$(_os_ver)" -eq 9 ]]; then
        # Enable EPEL and Remi repositories
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm
        dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
        # Import GPG key for Remi repository
        dnf install -y https://rpms.remirepo.net/RPM-GPG-KEY-remi
        # Enable Remi modular repository
        dnf config-manager --set-enabled remi-modular
        # Refresh package information
        dnf update --refresh
        # Install GeoIP-devel, specifying the use of the Remi repository
        dnf --enablerepo=remi install -y GeoIP-devel
      elif [[ -n "$(_os_ver)" && "$(_os_ver)" -eq 8 ]]; then
        dnf install -y epel-release epel-next-release
      fi
      dnf update -y
      for package_name in ${packages_name}; do
        dnf install -y ${package_name}
      done
    else
      yum update -y
      yum install -y epel-release yum-utils
      yum update -y
      for package_name in ${packages_name}; do
        yum install -y ${package_name}
      done
    fi
    ;;
  ubuntu | debian)
    apt update -y
    for package_name in ${packages_name}; do
      apt install -y ${package_name}
    done
    ;;
  esac
}

function _update() {
  local packages_name="$@"
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      dnf update -y
      for package_name in ${packages_name}; do
        dnf update -y ${package_name}
      done
    else
      yum update -y
      for package_name in ${packages_name}; do
        yum update -y ${package_name}
      done
    fi
    ;;
  ubuntu | debian)
    apt update -y
    for package_name in ${packages_name}; do
      apt upgrade -y ${package_name}
    done
    ;;
  esac
}

function _purge() {
  local package_name="$@"
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      dnf purge -y ${package_name}
      dnf autoremove -y
    else
      yum purge -y ${package_name}
      yum autoremove -y
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
  [[ -z "$(_os)" ]] && _error "Not supported OS"
  case "$(_os)" in
  ubuntu)
    [[ -n "$(_os_ver)" && "$(_os_ver)" -lt 20 ]] && _error "Not supported OS, please change to Ubuntu 20+ and try again."
    ;;
  debian)
    [[ -n "$(_os_ver)" && "$(_os_ver)" -lt 10 ]] && _error "Not supported OS, please change to Debian 10+ and try again."
    ;;
  centos)
    [[ -n "$(_os_ver)" && "$(_os_ver)" -lt 7 ]] && _error "Not supported OS, please change to CentOS 7+ and try again."
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
    if [[ -f "$file" ]]; then
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
    [[ "debian" -eq "$(_os)" ]] && _install "debian-archive-keyring" || _install "ubuntu-keyring"
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
    _install ca-certificates wget gcc gcc-c++ make cmake git perl-IPC-Cmd perl-Getopt-Long perl-Data-Dumper perl-FindBin
    # dependencies
    _install pcre2-devel zlib-devel libxml2-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed gperftools-devel perl-devel brotli-devel
    ;;
  debian | ubuntu)
    # toolchains
    _install ca-certificates wget gcc g++ make cmake git perl-base perl
    # dependencies
    _install libpcre2-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev libbrotli-dev
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
  # gcc
  gen_cflags
  # nginx
  _info "Download the latest versions of Nginx"
  _error_detect "curl -fsSL -o ${nginx_version}.tar.gz https://nginx.org/download/${nginx_version}.tar.gz"
  tar -zxf ${nginx_version}.tar.gz
  # openssl
  _info "Download the latest versions of OpenSSL"
  _error_detect "curl -fsSL -o ${openssl_version}.tar.gz https://github.com/openssl/openssl/archive/${openssl_version#*-}.tar.gz"
  tar -zxf ${openssl_version}.tar.gz
  if [[ ${is_enable_brotli} -eq 1 ]]; then
    # brotli
    _info "Checkout the latest ngx_brotli and build the dependencies"
    _error_detect "git clone https://github.com/google/ngx_brotli && cd ngx_brotli && git submodule update --init"
    cd ${TMPFILE_DIR}
  fi
  # configure
  cd ${nginx_version}
  sed -i "s/OPTIMIZE[ \\t]*=>[ \\t]*'-O'/OPTIMIZE          => '-O3'/g" src/http/modules/perl/Makefile.PL
  sed -i 's/NGX_PERL_CFLAGS="$CFLAGS `$NGX_PERL -MExtUtils::Embed -e ccopts`"/NGX_PERL_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  sed -i 's/NGX_PM_CFLAGS=`$NGX_PERL -MExtUtils::Embed -e ccopts`/NGX_PM_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  if [[ ${is_enable_brotli} -eq 1 ]]; then
    ./configure --prefix="${NGINX_PATH}" --user=root --group=root --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-google_perftools_module --add-module="../ngx_brotli" --with-compat --with-cc-opt="${cflags[*]}" --with-openssl="../${openssl_version}" --with-openssl-opt="${cflags[*]}"
  else
    ./configure --prefix="${NGINX_PATH}" --user=root --group=root --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-google_perftools_module --with-compat --with-cc-opt="${cflags[*]}" --with-openssl="../${openssl_version}" --with-openssl-opt="${cflags[*]}"
  fi
  swap_on 512
  # compile
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
      if [[ -e "/run/nginx.pid.oldbin" ]]; then
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
  mkdir -p /var/log/nginx
  mkdir -p ${nginx_path}/conf.d
  cd ${nginx_path}
  echo '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' | base64 --decode | tee ${nginx_path}/nginxconfig.io-example.com.tar.gz >/dev/null
  tar -xzvf nginxconfig.io-example.com.tar.gz | xargs chmod 0644
  _error_detect "curl -fsSL -o ${nginx_path}/nginxconfig.io/limit.conf "https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/conf/limit.conf""
  sed -i "s|/usr/local/nginx/conf|${nginx_path}|g" nginx.conf
  [[ ${is_compile} -eq 1 ]] && sed -i "/modules-enabled/a google_perftools_profiles /dev/shm/nginx/tcmalloc/tcmalloc;" nginx.conf
  sed -i "/worker_connections/a \    use                epoll;" nginx.conf
  sed -i "/ssl_protocols/i \    ssl_prefer_server_ciphers on;" nginx.conf
  sed -i "/# Mozilla Intermediate configuration/i # Bottom Diffie-Hellman" nginx.conf
  sed -i "/# Diffie-Hellman parameter for DHE ciphersuites/,/# Bottom Diffie-Hellman/d" nginx.conf
  sed -i "s|max-age=31536000|max-age=63072000|" nginxconfig.io/security.conf
  if [[ ${is_compile} -ne 1 || ${is_enable_brotli} -ne 1 ]]; then
    # disable brotli
    sed -i "/brotli/,/brotli_types/s/^/# /" nginxconfig.io/general.conf
  fi
  rm -rf sites-enabled/example.com.conf
}

function show_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  -i, --install      Install Nginx
  -c, --compile      Compile and install Nginx from source
  -u, --update       Update Nginx (detects if installed from package or source)
  -b, --brotli       Enable brotli compression
  -p, --purge        Uninstall and purge Nginx
  -h, --help         Show this help message

Note:
  - The '-u' option is designed for updating Nginx installed through this script.
    If Nginx was not installed by this script, using '-u' may lead to unexpected behavior.
EOF
  exit 0
}

check_os

if [[ $# -eq 0 ]]; then
  show_help
fi

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
  -b | --brotli)
    shift
    is_enable_brotli=1
    ;;
  -p | --purge)
    shift
    is_purge=1
    ;;
  -h | --help)
    show_help
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
