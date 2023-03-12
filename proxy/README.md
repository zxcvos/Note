# 手动配置 xray 代理服务

## 安全防护

### 防火墙设置

* 安装 `ufw` 防火墙

  ```sh
  apt update -y && apt install -y ufw
  ```

* 启动 `ufw` 防火墙

  ```sh
  sudo ufw enable

  ```

* 配置 `ufw` 规则

  ```sh
  sudo ufw default deny
  sudo ufw allow 16921
  sudo ufw allow http
  sudo ufw allow https
  ```

* 其他命令

  ```sh
  # 查看防火墙状态
  sudo ufw status
  # 删除防火墙规则
  sudo ufw delete allow 80
  # 关闭 ufw
  sudo ufw disable
  #重置 ufw
  sudo ufw reset
  ```

### 修改 SSH 端口

* 使用 `sed` 命令直接修改 `sshd_config` 文件，将 `Port 16921` 中的 `16921` 改成想要使用的端口号即可。

  ```sh
  sed -i "s/^[#pP].*ort\s*[0-9]*$/Port 16921/" /etc/ssh/sshd_config
  ```

* 重启 ssh 服务，使变更生效。

  ```sh
  systemctl restart sshd
  ```

### 使用非 root 用户

* 创建一个自定义用户，如果创建用户时没提示设置密码，可以使用 `passwd zxcvos` 进行设置。

  ```sh
  adduser zxcvos
  ```

* 给予自定义用户 `sudo` 权限，无密码使用 `sudo` 的配置 `zxcvos ALL=(ALL) NOPASSWD: ALL`，要密码使用 `sudo` 的配置 `zxcvos ALL=(ALL:ALL) ALL`。

  ```sh
  apt update && apt install sudo
  visudo
  ```

* 禁止 root 用户登录

  ```sh
  sed -i "s/^PermitRootLogin\s*[Yy][Ee][Ss]$/PermitRootLogin no/" /etc/ssh/sshd_config
  systemctl restart sshd
  ```

* [使用密钥登录并禁用密码登录][ssh-key]【如果在固定场所外不登录 vps 建议如此设置】

### 用户组设置

* 创建 `ssl-cert` 用户组

  ```sh
  sudo addgroup --system ssl-cert
  ```

* 定时重置 `/etc/ssl/private` 目录用户组

  ```sh
  (crontab -l >/dev/null 2>&1 && (crontab -l | grep "\*/5 \* \* \* \* /usr/bin/chown root:ssl-cert -R /etc/ssl/private" || crontab -l | { cat; echo "*/5 * * * * /usr/bin/chown root:ssl-cert -R /etc/ssl/private"; }) || echo "*/5 * * * * /usr/bin/chown root:ssl-cert -R /etc/ssl/private") | crontab -
  ```

* 定时重置 `/etc/ssl/private` 权限

  ```sh
  (crontab -l >/dev/null 2>&1 && (crontab -l | grep "\*/5 \* \* \* \* /usr/bin/chmod 0640 -R /etc/ssl/private" || crontab -l | { cat; echo "*/5 * * * * /usr/bin/chmod 0640 -R /etc/ssl/private"; }) || echo "*/5 * * * * /usr/bin/chmod 0640 -R /etc/ssl/private") | crontab -
  ```

## Xray 服务端

* bbr

  * 内核升级值最新稳定版

    ```sh
    sudo bash <(wget -qO- https://raw.githubusercontent.com/zxcvos/system-automation-scripts/main/update-kernel.sh)
    ```

  * 删除其余内核

    ```sh
    sudo bash <(wget -qO- https://raw.githubusercontent.com/zxcvos/system-automation-scripts/main/remove-kernel.sh)
    ```

* 安装/更新 xray-core(beta)

  ```sh
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta
  ```

* 设置配置文件

  * 获取配置文件

    * VLESS-XTLS-uTLS-REALITY

      ```sh
      wget -O ${HOME}/config.json https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/VLESS-XTLS-uTLS-REALITY/server.json
      ```

    * VLESS-H2-uTLS-REALITY

      ```sh
      wget -O ${HOME}/config.json https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/VLESS-H2-uTLS-REALITY/server.json
      ```

  * 设置 UUID

    ```sh
    sed -i "s|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|$(cat /proc/sys/kernel/random/uuid)|" ${HOME}/config.json
    ```

  * 获取 x25519 公私钥，并设置服务端 privateKey
    * 使用 `xray x25519` 获取 `Private key` 和 `Public key`

      ```sh
      xray x25519 > ${HOME}/xray_x25519
      ```

      ```sh
      Private key: yIB7ENDuBk65JK9jgeOFRc8MbLFqBmqTlW_iuLsFbXs
      Public key: wC-8O2vI-7OmVq4TVNBA57V_g4tMDM7jRXkcBYGMYFw
      ```

    * 设置 privateKey

      ```sh
      sed -i "s|xray x25519 Private key|$(awk '/^Private/ {print $3}' ${HOME}/xray_x25519)|" ${HOME}/config.json
      ```

  * 设置 shortIds

    ```sh
    sed -i "s|\"22\"|\"$(head -c 20 /dev/urandom | md5sum | head -c 2)\"|; s|\"4444\"|\"$(head -c 20 /dev/urandom | md5sum | head -c 4)\"|; s|\"88888888\"|\"$(head -c 20 /dev/urandom | md5sum | head -c 8)\"|; s|\"1616161616161616\"|\"$(head -c 20 /dev/urandom | md5sum | head -c 16)\"|" ${HOME}/config.json
    ```

  * 覆盖 config.json 文件

    ```sh
    mv -f ${HOME}/config.json /usr/local/etc/xray/config.json
    ```

  * 查看配置

    * 安装 jq, yum 和 dnf 自己改一下

      ```sh
      apt install -y jq
      ```

    * 使用 jq 查看 uuid, dest, serverNames, shortIds

      ```sh
      jq '.inbounds[] | select(.settings != null) | select(.protocol == "vless") | {id: .settings.clients[].id, dest: .streamSettings.realitySettings.dest, serverNames: .streamSettings.realitySettings.serverNames, shortIds :.streamSettings.realitySettings.shortIds}' /usr/local/etc/xray/config.json
      ```

    * 查看 Public key

      ```sh
      awk '/^Public/ {print $3}' ${HOME}/xray_x25519
      ```

* 定时更新 geo 文件

  * 获取 geo 更新脚本

    ```sh
    wget -O ${HOME}/update_dat.sh https://raw.githubusercontent.com/zxcvos/Note/main/proxy/rules/update-dat.sh
    ```

  * 将 geo 更新脚本设置为可执行文件

    ```sh
    chmod a+x ${HOME}/update_dat.sh
    ```

  * 添加定时任务

    ```sh
    (crontab -l >/dev/null 2>&1 && (crontab -l | grep "30 22 \* \* \* ${HOME}/update_dat.sh >/dev/null 2>&1" || crontab -l | { cat; echo "30 22 * * * ${HOME}/update_dat.sh >/dev/null 2>&1"; }) || echo "30 22 * * * ${HOME}/update_dat.sh >/dev/null 2>&1") | crontab -
    ```

* 完成

  ```sh
  systemctl restart xray
  ${HOME}/update_dat.sh
  ```

* 统计信息

  * 获取 traffic.sh

    ```sh
    wget -O $HOME/traffic.sh https://raw.githubusercontent.com/zxcvos/Note/main/proxy/xray/traffic.sh
    ```

  * 获取统计信息

    ```sh
    bash $HOME/traffic.sh
    ```

## Xray 客户端

* XTLS

  | 名称 | 值 |
  | :--- | :--- |
  | 地址 | IP 或服务端的域名 |
  | 端口 | 443 |
  | 用户ID | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
  | 流控 | xtls-rprx-vision |
  | 传输协议 | tcp |
  | 传输层安全 | reality |
  | SNI | onepiece.fandom.com |
  | Fingerprint | chrome |
  | PublicKey | wC-8O2vI-7OmVq4TVNBA57V_g4tMDM7jRXkcBYGMYFw |
  | shortId | 6ba85179e30d4fc2 |
  | spiderX | / |

* H2

  | 名称 | 值 |
  | :--- | :--- |
  | 地址 | IP 或服务端的域名 |
  | 端口 | 443 |
  | 用户ID | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
  | 流控 | 留空 |
  | 传输协议 | h2 |
  | 传输层安全 | reality |
  | SNI | onepiece.fandom.com |
  | Fingerprint | chrome |
  | PublicKey | wC-8O2vI-7OmVq4TVNBA57V_g4tMDM7jRXkcBYGMYFw |
  | shortId | 6ba85179e30d4fc2 |
  | spiderX | / |

## 参考

[使用指南][xray-docs]

[证书权限][ssl-permission]

[REALITY][REALITY]

[chika0801 Xray 配置文件模板][chika0801-Xray-examples]

[xray-docs]: https://xtls.github.io/Xray-docs-next/document (使用指南)
[ssh-key]: https://xtls.github.io/Xray-docs-next/document/level-0/ch04-security.html#_4-7-%E4%BD%BF%E7%94%A8-rsa-%E5%AF%86%E9%92%A5%E7%99%BB%E5%BD%95%E5%B9%B6%E7%A6%81%E7%94%A8%E5%AF%86%E7%A0%81%E7%99%BB%E5%BD%95
[ssl-permission]: https://github.com/XTLS/Xray-core/issues/867 (证书权限)
[REALITY]: https://github.com/XTLS/REALITY (THE NEXT FUTURE)
[chika0801-Xray-examples]: https://github.com/chika0801/Xray-examples (chika0801 Xray 配置文件模板)
