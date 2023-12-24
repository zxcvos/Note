# Xray

## Reinstall Linux

### 安装 InstallNET 脚本

```shell
wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
```

### 重装系统

#### Debian 官方推荐镜列表

```shell
https://www.debian.org/mirror/list.html
```

#### 使用美国镜像

```shell
bash InstallNET.sh -debian 12 -mirror "https://mirrors.ocf.berkeley.edu/debian/" -port '22' -password 'LeitboGi0ro' -swap '1024' --cloudkernel '1' --bbr
```

#### 配置信息

发行版: debian 12

账号: root

密码: LeitboGi0ro

SSH 端口: 22

虚拟内存: 1024 MB

内核: 云内核 (`-–cloudkernel '1'` 参数强制安装云内核，`-–cloudkernel '0'` 参数强制切换到安装传统 Linux 内核)

bbr: 启用

## Linux Init

```shell
bash <(wget -qO- https://raw.githubusercontent.com/zxcvos/Note/main/linux/LinuxInit.sh)
```

## 安全防护

### 安装 ufw

```shell
apt update -y && apt install -y ufw
```

### 配置并启动 ufw

```shell
ufw default deny
ufw allow 22 # ssh port
ufw allow 443 # xray port
ufw enable
```

## Xray 服务端

### 安装 Xray

#### 非 root 安装

```shell
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta
```

#### root 安装

```shell
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root --beta
```

### 设置配置 Xray 文件

#### 获取配置文件

```shell
wget --no-check-certificate -qO /usr/local/etc/xray/config.json 'https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/VLESS-XTLS-uTLS-REALITY/server.json'
```

#### 设置 uuid

##### 使用 linux 自带 uuid 设置

```shell
sed -i "s|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|$(cat /proc/sys/kernel/random/uuid)|" /usr/local/etc/xray/config.json
```

##### 使用 Xray 自带 api 设置

- 默认

  ```shell
  sed -i "s|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|$(xray uuid)|" /usr/local/etc/xray/config.json
  ```

- 自定义文本

  ```shell
  sed -i "s|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|$(xray uuid -i "zxcvos")|" /usr/local/etc/xray/config.json
  ```

#### 设置 x25519

##### 获取 x25519

```shell
mkdir -p ${HOME}/xray && xray x25519 > ${HOME}/xray/xray_x25519
```

##### 设置 privateKey

```shell
sed -i "s|xray x25519 Private key|$(awk '/^Private/ {print $3}' ${HOME}/xray/xray_x25519)|" /usr/local/etc/xray/config.json
```

#### 设置 shortIds

```shell
sed -i "s|\"2\"|\"$(openssl rand -hex 1)\"|; s|\"4\"|\"$(openssl rand -hex 2)\"|; s|\"8\"|\"$(openssl rand -hex 4)\"|; s|\"16\"|\"$(openssl rand -hex 8)\"|" /usr/local/etc/xray/config.json
```

#### 定时更新 geo 文件

##### 获取更新脚本

```shell
wget --no-check-certificate -qO ${HOME}/xray/update_dat.sh 'https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/update_dat.sh' && chmod a+x ${HOME}/xray/update_dat.sh
```

##### 添加定时任务

```shell
(crontab -l 2>/dev/null; echo "30 6 * * * ${HOME}/xray/update_dat.sh >/dev/null 2>&1") | awk '!x[$0]++' | crontab -
```

##### 删除定时任务

```shell
(crontab -l 2>/dev/null | grep -v "${HOME}/xray/update_dat.sh") | crontab -
```

#### 统计信息

##### 获取统计信息脚本

```shell
wget --no-check-certificate -qO ${HOME}/xray/traffic.sh 'https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/traffic.sh' && chmod a+x ${HOME}/xray/traffic.sh
```

##### 添加定时任务

###### 记录每日用量

```shell
mkdir -p ${HOME}/xray/traffic/$(date +'%Y-%m') && (crontab -l 2>/dev/null; echo "0 0 1 * * /usr/bin/mkdir -p ${HOME}/xray/traffic/\$(date +'\%Y-\%m') >/dev/null 2>&1"; echo "29 6 * * * ${HOME}/xray/traffic.sh > ${HOME}/xray/traffic/\$(date +'\%Y-\%m')/\$(date +\%F) 2>&1") | awk '!x[$0]++' | crontab -
```

###### 每个季度清除一次记录

```shell
(crontab -l 2>/dev/null; echo "0 12 1 */3 * /usr/bin/rm -rf ${HOME}/xray/traffic/* >/dev/null 2>&1") | awk '!x[$0]++' | crontab -
```

###### 删除定时任务

```shell
(crontab -l 2>/dev/null | grep -v "${HOME}/xray/traffic") | crontab -
```

#### 查看配置

##### 查看 uuid

```shell
sed -n '/"id"/p' /usr/local/etc/xray/config.json | awk '{print $2}' | cut -d\, -f1
```

##### 查看 serverNames

```shell
sed -n '/"serverNames"/,/]/p' /usr/local/etc/xray/config.json | awk 'NR>1 && !/\]/{print $1}' | cut -d\, -f1
```

##### 查看 shortIds

```shell
sed -n '/"shortIds"/,/]/p' /usr/local/etc/xray/config.json | awk 'NR>1 && !/\]/{print $1}' | cut -d\, -f1
```

##### 查看 Public Key

```shell
awk '/^Public/ {print $3}' ${HOME}/xray/xray_x25519
```

### 管理 Xray 服务

#### 启动

```shell
systemctl is-active xray || systemctl start xray
systemctl is-enabled xray || systemctl enable xray
```

#### 暂停

```shell
systemctl is-active xray && systemctl stop xray
systemctl is-enabled xray && systemctl disable xray
```

#### 重启

```shell
systemctl is-active xray && systemctl restart xray || systemctl start xray
```

#### 查看状态

```shell
systemctl status xray
```

### 注意

#### 定时任务

- 更新 geo 文件时会自动重启 xray，重启后统计信息将重置。

- 如果设置了统计信息的定时任务，请不要修改统计信息定时任务的触发时间。

- 统计信息定时任务是记录前一天的用量信息。

#### Xray 目录

```shell
# 守护进程配置
installed: /etc/systemd/system/xray.service
installed: /etc/systemd/system/xray@.service
# 命令与配置
installed: /usr/local/bin/xray
installed: /usr/local/etc/xray/*.json
# geo
installed: /usr/local/share/xray/geoip.dat
installed: /usr/local/share/xray/geosite.dat
# 日志
installed: /var/log/xray/access.log
installed: /var/log/xray/error.log
# x25519 公私钥
customize: ${HOME}/xray/xray_x25519
# geo 更新脚本
customize: ${HOME}/xray/update_dat.sh
# 信息统计脚本与定时任务目录
customize: ${HOME}/xray/traffic.sh
customize: ${HOME}/xray/traffic/
```

## Xray 客户端

| 名称 | 值 |
| :--- | :--- |
| 地址 | 服务端的 IP |
| 端口 | 443 |
| 用户ID | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| 流控 | xtls-rprx-vision |
| 加密方式 | none |
| 传输协议 | tcp |
| 伪装类型 | none |
| 伪装域名 | 留空 |
| 路径 | 留空 |
| 传输层安全 | reality |
| SNI | `onepiece.fandom.com` |
| Fingerprint | chrome |
| PublicKey | wC-8O2vI-7OmVq4TVNBA57V_g4tMDM7jRXkcBYGMYFw |
| ShortId | 6ba85179e30d4fc2 |
| SpiderX | 留空 |

## 感谢

[leitbogioro/Tools](https://github.com/leitbogioro/Tools)

[Project X](https://xtls.github.io/Xray-docs-next/)

[REALITY](https://github.com/XTLS/REALITY)

[Xray-examples](https://github.com/XTLS/Xray-examples)

[chika0801 Xray 配置文件模板](https://github.com/chika0801/Xray-examples)
