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
    [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 16 ] && _error "Not supported OS, please change to Ubuntu 16+ and try again."
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

function install_dependencies() {
  case "$(_os)" in
  centos)
    wget -O /etc/yum.repos.d/nginx.repo https://raw.githubusercontent.com/zxcvos/Xray-script/main/repo/nginx.repo
    ;;
  debian | ubuntu)
    [[ ${is_mainline} =~ ^[Yy]$ ]] && mainline="/mainline"
    [ "debian" -eq "$(_os)" ] && _install_update "debian-archive-keyring" || _install_update "ubuntu-keyring"
    rm -rf /etc/apt/sources.list.d/nginx.list
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor |
      sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
            http://nginx.org/packages${mainline}/$(_os) $(lsb_release -cs) nginx" |
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
    _install_update ca-certificates wget gcc gcc-c++ make perl-IPC-Cmd perl-Getopt-Long perl-Data-Dumper perl-FindBin
    # dependencies
    _install_update pcre2-devel zlib-devel libxml2-devel libxslt-devel gd-devel geoip-devel perl-ExtUtils-Embed gperftools-devel perl-devel
    ;;
  debian | ubuntu)
    # toolchains
    _install_update ca-certificates wget gcc g++ make perl-base perl
    # dependencies
    _install_update libpcre2-dev zlib1g-dev libxml2-dev libxslt1-dev libgd-dev libgeoip-dev libgoogle-perftools-dev libperl-dev
    ;;
  esac
}

function acme_dependencies() {
  case "$(_os)" in
  centos)
    _install_update curl openssl crontabs
    ;;
  debian | ubuntu)
    _install_update curl openssl cron
    ;;
  esac
}

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

function pkg_install() {
  _info "配置安装链接"
  install_dependencies
  _info "开始安装 nginx"
  _install_update "nginx"
}

function source_compile() {
  cd ${TMPFILE_DIR}
  _info "安装编译所需工具链与依赖"
  compile_dependencies
  _info "获取 nginx 与 openssl 最新版本号"
  nginx_version="$(wget -qO- --no-check-certificate https://api.github.com/repos/nginx/nginx/tags | grep 'name' | cut -d\" -f4 | grep 'release' | head -1 | sed 's/release/nginx/')"
  openssl_version="openssl-$(wget -qO- --no-check-certificate https://api.github.com/repos/openssl/openssl/tags | grep 'name' | cut -d\" -f4 | grep -Eoi '^openssl-([0-9]\.?){3}$' | head -1)"
  gen_cflags
  _info "开始获取 nginx"
  if ! wget -O ${nginx_version}.tar.gz https://nginx.org/download/${nginx_version}.tar.gz; then
    _error "获取 nginx 失败"
  fi
  tar -zxf ${nginx_version}.tar.gz
  _info "开始获取 openssl"
  if ! wget -O ${openssl_version}.tar.gz https://github.com/openssl/openssl/archive/${openssl_version#*-}.tar.gz; then
    _error "获取 openssl 失败"
  fi
  tar -zxf ${openssl_version}.tar.gz
  cd ${nginx_version}
  sed -i "s/OPTIMIZE[ \\t]*=>[ \\t]*'-O'/OPTIMIZE          => '-O3'/g" src/http/modules/perl/Makefile.PL
  sed -i 's/NGX_PERL_CFLAGS="$CFLAGS `$NGX_PERL -MExtUtils::Embed -e ccopts`"/NGX_PERL_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  sed -i 's/NGX_PM_CFLAGS=`$NGX_PERL -MExtUtils::Embed -e ccopts`/NGX_PM_CFLAGS="`$NGX_PERL -MExtUtils::Embed -e ccopts` $CFLAGS"/g' auto/lib/perl/conf
  ./configure --prefix="/usr/local/nginx" --user=root --group=root --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-google_perftools_module --with-compat --with-cc-opt="${cflags[*]}" --with-openssl="../${openssl_version}" --with-openssl-opt="${cflags[*]}"
  swap_on 512
  _info " 开始编译 nginx"
  if ! make -j$(nproc); then
    _error "nginx 编译失败"
  fi
  _info "开始安装 nginx"
  make install
  ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx
}

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
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
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
  if [[ -d /etc/nginx ]]; then
    if [[ ${is_log} -ne 1 ]]; then
      # install 安装的 nginx 没有日志配置
      echo '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' | base64 --decode | tee /etc/nginx/nginxconfig.io-example.com.tar.gz >/dev/null
    else
      # install 安装的 nginx 有日志配置
      echo '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' | base64 --decode | tee /etc/nginx/nginxconfig.io-example.com.tar.gz >/dev/null
    fi
    cd /etc/nginx
  elif [[ -d /usr/local/nginx/conf ]]; then
    if [[ ${is_log} -ne 1 ]]; then
      # compile 安装的 nginx 没有日志配置
      echo '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' | base64 --decode | tee /usr/local/nginx/conf/nginxconfig.io-example.com.tar.gz >/dev/null
    else
      # compile 安装的 nginx 有日志配置
      echo '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' | base64 --decode | tee /usr/local/nginx/conf/nginxconfig.io-example.com.tar.gz >/dev/null
    fi
    cd /usr/local/nginx/conf
  else
    _error "没有找到 nginx 配置文件目录"
  fi
  tar -xzvf nginxconfig.io-example.com.tar.gz | xargs chmod 0644
  [[ ${is_compile} -eq 1 ]] && sed -i "/modules-enabled/a google_perftools_profiles /dev/shm/nginx/tcmalloc/tcmalloc;" nginx.conf
  sed -i "/worker_connections/a \    use                epoll;" nginx.conf
  sed -i "/ssl_protocols/i \    ssl_prefer_server_ciphers on;" nginx.conf
  sed -i "/# Diffie-Hellman parameter for DHE ciphersuites/,/ssl_dhparam/d" nginx.conf
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
  *)
    echo -ne "\nInvalid option: '$1'.\n"
    ;;
  esac
done

if [[ ${is_install} -eq 1 ]]; then
  acme_dependencies
  pkg_install
elif [[ ${is_compile} -eq 1 ]]; then
  acme_dependencies
  source_compile
elif [[ ${is_update} -eq 1 ]]; then
  if [[ -d /etc/nginx ]]; then
    pkg_install
  elif [[ -d /usr/local/nginx/conf ]]; then
    cp -af /usr/local/nginx/conf ${TMPFILE_DIR}
    source_compile
    cp -af ${TMPFILE_DIR}/conf /usr/local/nginx
  fi
elif [[ ${is_purge} -eq 1 ]]; then
  purge_nginx
fi

if [[ ${is_update} -ne 1 && ${is_purge} -ne 1 ]]; then
  [[ ${is_install} -eq 1 || ${is_compile} -eq 1 ]] && systemctl_config
  nginx_config
fi
