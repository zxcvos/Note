#!/usr/bin/env bash
# 
# 使用 curl 命令模拟不同的 User-Agent 来测试 Nginx 配置是否生效。
#

# color
readonly RED='\033[1;31;31m'
readonly GREEN='\033[1;31;32m'
readonly YELLOW='\033[1;31;33m'
readonly NC='\033[0m'

declare domain=''

# status print
function _info() {
  printf "${GREEN}[信息] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
}

function _warn() {
  printf "${YELLOW}[警告] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
}

function _error() {
  printf "${RED}[错误] ${NC}"
  printf -- "%s" "$@"
  printf "\n"
  exit 1
}

# 使用不同的用户代理标头模拟测试
test_curl() {
  local user_agent=$1
  local protocol=$2

  curl -A "${user_agent}" "${protocol}://${domain}" -s -o /dev/null || return 1
}

test_user_agents() {
  local user_agent=$1

  _info "模拟测试 ${user_agent} 的抓取/访问"
  test_curl "${user_agent}" "http" && _info "http 正常访问" || _warn "http 禁止访问"
  test_curl "${user_agent}" "https" && _info "https 正常访问" || _warn "https 禁止访问"
  echo
}

function show_help() {
  echo "用法: $0 -d example.com"
  echo "选项:"
  echo "  -d, --domain        需要测试 limit.conf 配置的域名"
  echo "  -h, --help          查看使用信息"
  exit 0
}

while [[ $# -ge 1 ]]; do
  case "${1}" in
  -d | --domain)
    shift
    [[ -z "$1" ]] && _error '域名未提供'
    domain="$1"
    shift
    ;;
  -h | --help)
    show_help
    ;;
  *)
    _error "无效的选项: '$1'。使用 '$0 -h/--help' 查看使用信息。"
    ;;
  esac
done

[[ -z "${domain}" ]] && show_help

# 运行测试
test_user_agents "Curl"
test_user_agents "Baiduspider"
test_user_agents "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)"
test_user_agents "SomeOtherUserAgent"
