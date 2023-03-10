# 手动配置 xray 代理服务

## 安全防护

### 防火墙设置
1. 安装 `ufw` 防火墙
   ```sh
   apt update -y && apt install -y ufw
   ```
2. 启动 `ufw` 防火墙
   ```sh
   sudo ufw enable
   ```
3. 配置 `ufw` 规则
   ```sh
   sudo ufw default deny
   sudo ufw allow 16921
   sudo ufw allow http
   sudo ufw allow https
   ```
4. 其他命令
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
1. 使用 `sed` 命令直接修改 `sshd_config` 文件，将 `Port 16921` 中的 `16921` 改成想要使用的端口号即可。
   ```sh
   sed -i "s/^[#pP].*ort\s*[0-9]*$/Port 16921/" /etc/ssh/sshd_config
   ```
2. 重启 ssh 服务，使变更生效。
   ```sh
   systemctl restart sshd
   ```

### 使用非 root 用户
1. 创建一个自定义用户，如果创建用户时没提示设置密码，可以使用 `passwd zxcvos` 进行设置。
   ```sh
   adduser zxcvos
   ```
2. 给予自定义用户 `sudo` 权限，无密码使用 `sudo` 的配置 `zxcvos ALL=(ALL) NOPASSWD: ALL`，要密码使用 `sudo` 的配置 `zxcvos ALL=(ALL:ALL) ALL`。
   ```sh
   apt update && apt install sudo
   visudo
   ```
3. 禁止 root 用户登录
   ```sh
   sed -i "s/^PermitRootLogin\s*[Yy][Ee][Ss]$/PermitRootLogin no/" /etc/ssh/sshd_config
   systemctl restart sshd
   ```
4. [使用密钥登录并禁用密码登录][ssh-key]【如果在固定场所外不登录 vps 建议如此设置】

### 用户组设置
1. 创建 `ssl-cert` 用户组
   ```sh
   sudo addgroup --system ssl-cert
   ```
2. 定时重置 `/etc/ssl/private` 目录用户组
   ```sh
   (crontab -l >/dev/null 2>&1 && (crontab -l | grep "\*/5 \* \* \* \* /usr/bin/chown root:ssl-cert -R /etc/ssl/private" || crontab -l | { cat; echo "*/5 * * * * /usr/bin/chown root:ssl-cert -R /etc/ssl/private"; }) || echo "*/5 * * * * /usr/bin/chown root:ssl-cert -R /etc/ssl/private") | crontab -
   ```
3. 定时重置 `/etc/ssl/private` 权限
   ```sh
   (crontab -l >/dev/null 2>&1 && (crontab -l | grep "\*/5 \* \* \* \* /usr/bin/chmod 0640 -R /etc/ssl/private" || crontab -l | { cat; echo "*/5 * * * * /usr/bin/chmod 0640 -R /etc/ssl/private"; }) || echo "*/5 * * * * /usr/bin/chmod 0640 -R /etc/ssl/private") | crontab -
   ```

## 网站建设

## 证书管理

## Xray 服务端

## Xray 客户端

## 参考

[小小白白话文][xray-docs]
[证书权限][ssl-permission]

[xray-docs]: https://xtls.github.io/Xray-docs-next/document/level-0
[ssh-key]: https://xtls.github.io/Xray-docs-next/document/level-0/ch04-security.html#_4-7-%E4%BD%BF%E7%94%A8-rsa-%E5%AF%86%E9%92%A5%E7%99%BB%E5%BD%95%E5%B9%B6%E7%A6%81%E7%94%A8%E5%AF%86%E7%A0%81%E7%99%BB%E5%BD%95
[ssl-permission]: https://github.com/XTLS/Xray-core/issues/867
