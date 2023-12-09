## Nginx 管理
### 安装 Nginx
1. 获取 nginx 管理脚本
   ```sh
   curl -fsSL -o ${HOME}/nginx.sh https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/nginx_manage.sh
   ```
2. 安装 nginx
   1. 默认安装，使用 apt、yum、dnf 进行安装
      ```sh
      bash ${HOME}/nginx.sh
      ```
   2. 编译安装
      ```sh
      bash ${HOME}/nginx.sh -c
      ```
3. 更新 nginx
   ```sh
   bash ${HOME}/nginx.sh -u
   ```
4. 卸载 nginx
   ```sh
   bash ${HOME}/nginx.sh -p
   ```
5. 添加 nginx 定时更新任务
   ```sh
   chmod a+x ${HOME}/nginx.sh
   (crontab -l 2>/dev/null; echo "0 6 15 * * ${HOME}/nginx.sh -u >/dev/null 2>&1") | awk '!x[$0]++' | crontab -
   ```
6. 删除 nginx 定时更新任务
   ```sh
   (crontab -l 2>/dev/null | grep -v "${HOME}/nginx.sh -u >/dev/null 2>&1") | crontab -
   ```
## 证书管理
### 管理 acme.sh
* 安装
  ```sh
  curl https://get.acme.sh | sh -s email=my@example.com
  ```
* 更新
  ```sh
  acme.sh --upgrade
  ```
* 自动更新
  ```sh
  acme.sh --upgrade --auto-upgrade
  ```
* 禁用自动更新
  ```sh
  acme.sh --upgrade --auto-upgrade 0
  ```
* 卸载
  ```sh
  acme.sh --uninstall
  rm -rf ~/.acme.sh
  ```
* 修改默认证书颁发机构(当前版本默认CA: ZeroSSL)
  ```sh
  acme.sh --set-default-ca --server letsencrypt
  ```
### 申请证书
```sh
acme.sh --issue --webroot /home/wwwroot/example.com -d example.com -d www.example.com --keylength ec-256
```
### 安装证书
```sh
acme.sh --install-cert -d example.com \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "nginx -t && systemctl reload nginx"
```
### 手动更新证书
```sh
acme.sh --renew -d example.com -d www.example.com --force --ecc
```
### 停止更新证书
```sh
acme.sh --remove -d example.com -d www.example.com --ecc
```
### 查看已安装证书信息
```sh
acme.sh --info -d example.com
```
* 会输出如下内容：
  ```
  DOMAIN_CONF=/root/.acme.sh/example.com/example.com.conf
  Le_Domain=example.com
  Le_Alt=no
  Le_Webroot=dns_ali
  Le_PreHook=
  Le_PostHook=
  Le_RenewHook=
  Le_API=https://acme-v02.api.letsencrypt.org/directory
  Le_Keylength=
  Le_OrderFinalize=https://acme-v02.api.letsencrypt.org/acme/finalize/23xxxx150/781xxxx4310
  Le_LinkOrder=https://acme-v02.api.letsencrypt.org/acme/order/233xxx150/781xxxx4310
  Le_LinkCert=https://acme-v02.api.letsencrypt.org/acme/cert/04cbd28xxxxxx349ecaea8d07
  Le_CertCreateTime=1649358725
  Le_CertCreateTimeStr=Thu Apr  7 19:12:05 UTC 2022
  Le_NextRenewTimeStr=Mon Jun  6 19:12:05 UTC 2022
  Le_NextRenewTime=1654456325
  Le_RealCertPath=
  Le_RealCACertPath=
  Le_RealKeyPath=/etc/acme/example.com/privkey.pem
  Le_ReloadCmd=service nginx force-reload
  Le_RealFullChainPath=/etc/acme/example.com/chain.pem
  ```
