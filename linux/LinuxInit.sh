#!/usr/bin/env bash
#
# Copyright (C) 2023 zxcvos
#
# Ref: https://github.com/MoeClub/Note
# Ref: https://github.com/leitbogioro/Tools
# Ref: https://www.nodeseek.com/post-37225-1

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

function _error_detect() {
  local cmd="$1"
  _info "${cmd}"
  eval ${cmd}
  if [[ $? -ne 0 ]]; then
    _error "Execution command (${cmd}) failed, please check it and try again."
  fi
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

case "$(_os)" in
centos)
  _install curl openssl crontabs util-linux iproute net-tools bind-utils procps-ng tzdata wget curl lsof
  ;;
debian | ubuntu)
  _install curl openssl cron bsdmainutils iproute2 net-tools dnsutils procps tzdata wget curl lsof
  ;;
esac

# limits
if [ -f /etc/security/limits.conf ]; then
  LIMIT='1048576'
  sed -i '/^\(\*\|root\)[[:space:]]*\(hard\|soft\)[[:space:]]*\(nofile\|memlock\)/d' /etc/security/limits.conf
  echo -ne "*\thard\tmemlock\t${LIMIT}\n*\tsoft\tmemlock\t${LIMIT}\nroot\thard\tmemlock\t${LIMIT}\nroot\tsoft\tmemlock\t${LIMIT}\n*\thard\tnofile\t${LIMIT}\n*\tsoft\tnofile\t${LIMIT}\nroot\thard\tnofile\t${LIMIT}\nroot\tsoft\tnofile\t${LIMIT}\n\n" >>/etc/security/limits.conf
fi
if [ -f /etc/systemd/system.conf ]; then
  sed -i 's/#\?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
fi

# timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" >/etc/timezone

# systemd-journald
sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
systemctl restart systemd-journald


# sysctl
cat >/etc/sysctl.d/99-sysctl.conf<<EOF
#
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
#

#kernel.domainname = example.com

# Uncomment the following to stop low-level messages on console
#kernel.printk = 3 4 1 3

###################################################################
# Functions previously found in netbase
#

# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
#net.ipv4.conf.default.rp_filter=1
#net.ipv4.conf.all.rp_filter=1

# Uncomment the next line to enable TCP/IP SYN cookies
# See http://lwn.net/Articles/277146/
# Note: This may impact IPv6 TCP sessions too
#net.ipv4.tcp_syncookies=1

# Uncomment the next line to enable packet forwarding for IPv4
#net.ipv4.ip_forward=1

# Uncomment the next line to enable packet forwarding for IPv6
#  Enabling this option disables Stateless Address Autoconfiguration
#  based on Router Advertisements for this host
#net.ipv6.conf.all.forwarding=1


###################################################################
# Additional settings - these settings can improve the network
# security of the host and prevent against some network attacks
# including spoofing attacks and man in the middle attacks through
# redirection. Some network environments, however, require that these
# settings are disabled so review and enable them as needed.
#
# Do not accept ICMP redirects (prevent MITM attacks)
#net.ipv4.conf.all.accept_redirects = 0
#net.ipv6.conf.all.accept_redirects = 0
# _or_
# Accept ICMP redirects only for gateways listed in our default
# gateway list (enabled by default)
# net.ipv4.conf.all.secure_redirects = 1
#
# Do not send ICMP redirects (we are not a router)
#net.ipv4.conf.all.send_redirects = 0
#
# Do not accept IP source route packets (we are not a router)
#net.ipv4.conf.all.accept_source_route = 0
#net.ipv6.conf.all.accept_source_route = 0
#
# Log Martian Packets
#net.ipv4.conf.all.log_martians = 1
#

###################################################################
# Magic system request Key
# 0=disable, 1=enable all, >1 bitmask of sysrq functions
# See https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html
# for what other values do
#kernel.sysrq=438

# Ref: https://github.com/MoeClub/Note
# Ref: https://github.com/leitbogioro/Tools
# Ref: https://www.nodeseek.com/post-37225-1

# ------ 网络调优: 基本 ------
# TTL 配置, Linux 默认 64
# net.ipv4.ip_default_ttl = 64

# 参阅 RFC 1323. 应当启用.
net.ipv4.tcp_timestamps = 1
# ------ END 网络调优: 基本 ------

# ------ 网络调优: 内核 Backlog 队列和缓存相关 ------
# 有条件建议依据实测结果调整相关数值
# 缓冲区相关配置均和内存相关
net.core.wmem_default = 524288
net.core.rmem_default = 524288
net.core.rmem_max = 536870912
net.core.wmem_max = 536870912
net.ipv4.tcp_mem = 2097152 8388608 536870912
net.ipv4.tcp_rmem = 16384 524288 536870912
net.ipv4.tcp_wmem = 16384 524288 536870912
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_collapse_max_bytes = 6291456
net.ipv4.tcp_notsent_lowat = 131072
net.ipv4.ip_local_port_range = 1024 65535
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_max_syn_backlog = 65535
net.core.somaxconn = 65535
net.core.optmem_max = 33554432
net.ipv4.tcp_abort_on_overflow = 1
# 流控和拥塞控制相关调优
# Egress traffic control 相关. 可选 fq, cake
# 实测二者区别不大, 保持默认 fq 即可
net.core.default_qdisc = fq
# Xanmod 内核 6.X 版本目前默认使用 bbr3, 无需设置
# 实测比 bbr, bbr2 均有提升
# 不过网络条件不同会影响. 有需求请实测.
# net.ipv4.tcp_congestion_control = bbr3
net.ipv4.tcp_congestion_control = bbr
# 显式拥塞通知
# 已被发现在高度拥塞的网络上是有害的.
# net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1
# TCP 自动窗口
# 要支持超过 64KB 的 TCP 窗口必须启用
net.ipv4.tcp_window_scaling = 1
# 开启后, TCP 拥塞窗口会在一个 RTO 时间
# 空闲之后重置为初始拥塞窗口 (CWND) 大小.
# 大部分情况下, 尤其是大流量长连接, 设置为 0.
# 对于网络情况时刻在相对剧烈变化的场景, 设置为 1.
net.ipv4.tcp_slow_start_after_idle = 0
# nf_conntrack 调优
net.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15
net.netfilter.nf_conntrack_tcp_timeout_established = 300
net.ipv4.netfilter.ip_conntrack_tcp_timeout_established = 7200
# TIME-WAIT 状态调优
# 4.12 内核中此参数已经永久废弃, 不用纠结是否需要开启
# net.ipv4.tcp_tw_recycle = 0
## 只对客户端生效, 服务器连接上游时也认为是客户端
net.ipv4.tcp_tw_reuse = 1
# 系统同时保持TIME_WAIT套接字的最大数量
# 如果超过这个数字 TIME_WAIT 套接字将立刻被清除
net.ipv4.tcp_max_tw_buckets = 65536
# ------ END 网络调优: 内核 Backlog 队列和缓存相关 ------

# ------ 网络调优: 其他 ------
# 启用选择应答
# 对于广域网通信应当启用
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_sack = 1
# 启用转发应答
# 对于广域网通信应当启用
net.ipv4.tcp_fack = 1
# TCP SYN 连接超时重传次数
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
# TCP SYN 连接超时时间, 设置为 5 约为 30s
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
# 开启 SYN 洪水攻击保护
# 注意: tcp_syncookies 启用时, 此时实际上没有逻辑上的队列长度, 
# Backlog 设置将被忽略. syncookie 是一个出于对现实的妥协, 
# 严重违反 TCP 协议的设计, 会造成 TCP option 不可用, 且实现上
# 通过计算 hash 避免维护半开连接也是一种 tradeoff 而非万金油, 
# 勿听信所谓“安全优化教程”而无脑开启
net.ipv4.tcp_syncookies = 0
# 禁止 ping
net.ipv4.icmp_echo_ignore_all = 1
# 禁止 tcp 快速打开
net.ipv4.tcp_fastopen = 0
# ip 转发配置
net.ipv4.ip_forward = 1

# 开启反向路径过滤
# Aliyun 负载均衡实例后端的 ECS 需要设置为 0
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2

# 减少处于 FIN-WAIT-2 连接状态的时间使系统可以处理更多的连接
net.ipv4.tcp_fin_timeout = 10

# 默认情况下一个 TCP 连接关闭后, 把这个连接曾经有的参数保存到dst_entry中
# 只要 dst_entry 没有失效,下次新建立相同连接的时候就可以使用保存的参数来初始化这个连接.通常情况下是关闭的
net.ipv4.tcp_no_metrics_save = 1
# unix socket 最大队列
net.unix.max_dgram_qlen = 1024
# 路由缓存刷新频率
net.ipv4.route.gc_timeout = 100

# 启用 MTU 探测，在链路上存在 ICMP 黑洞时候有用（大多数情况是这样）
net.ipv4.tcp_mtu_probing = 1

# 开启并记录欺骗, 源路由和重定向包
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
# 处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
# TCP KeepAlive 调优
# 最大闲置时间
net.ipv4.tcp_keepalive_time = 600
# 最大失败次数, 超过此值后将通知应用层连接失效
net.ipv4.tcp_keepalive_probes = 5
# 发送探测包的时间间隔
net.ipv4.tcp_keepalive_intvl = 3
# 系统所能处理不属于任何进程的TCP sockets最大数量
net.ipv4.tcp_max_orphans = 262144
# arp_table的缓存限制优化
net.ipv4.neigh.default.gc_thresh1 = 128
net.ipv4.neigh.default.gc_thresh2 = 512
net.ipv4.neigh.default.gc_thresh3 = 4096
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
# ------ END 网络调优: 其他 ------

# ------ 内核调优 ------

# 内核 Panic 后 1 秒自动重启
kernel.panic = 1
# 允许更多的PIDs, 减少滚动翻转问题
kernel.pid_max = 32768
# 内核所允许的最大共享内存段的大小（bytes）
kernel.shmmax = 4294967296
# 在任何给定时刻, 系统上可以使用的共享内存的总量（pages）
kernel.shmall = 1073741824
# 设定程序core时生成的文件名格式
kernel.core_pattern = core_%e
# 当发生oom时, 自动转换为panic
vm.panic_on_oom = 1
# 表示强制Linux VM最低保留多少空闲内存（Kbytes）
# vm.min_free_kbytes = 1048576
# 该值高于100, 则将导致内核倾向于回收directory和inode cache
vm.vfs_cache_pressure = 250
# 表示系统进行交换行为的程度, 数值（0-100）越高, 越可能发生磁盘交换
vm.swappiness = 10
# 仅用10%做为系统cache
vm.dirty_ratio = 10
vm.overcommit_memory = 1
# 增加系统文件描述符限制
# Fix error: too many open files
fs.file-max = 104857600
fs.inotify.max_user_instances = 8192
fs.nr_open = 1048576
# 内核响应魔术键
kernel.sysrq = 1
# 弃用
# net.ipv4.tcp_low_latency = 1

# 当某个节点可用内存不足时, 系统会倾向于从其他节点分配内存. 对 Mongo/Redis 类 cache 服务器友好
vm.zone_reclaim_mode = 0
EOF

sysctl -p
