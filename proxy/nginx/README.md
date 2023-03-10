## Nginx 管理
### 安装 Nginx
1. 使用 `apt install nginx` 直接安装
   ```sh
   apt update -y
   apt install -y nginx
   ```
2. 自定义编译安装
   ```sh
   bash -c "$(curl -L https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/nginx_compile.sh)"
   ```
### 更新 Nginx
1. 使用 `apt upgrade nginx` 直接更新
   ```sh
   apt update -y
   apt upgrade -y nginx
   ```
2. 自定义编译更新
   1. 确保 nginx 备份目录的存在
      ```sh
      [ -d $HOME/nginx ] || mkdir -p $HOME/nginx
      ```
   2. 创建当前 nginx 配置的备份
      ```sh
      tar -czvf $HOME/nginx/nginx_$(date +'%F_%H-%M-%S').tar.gz /usr/local/nginx/conf
      ```
   3. 更新
      1. 平滑更新
         1. 编译安装
            ```sh
            bash -c "$(curl -L https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/nginx_compile.sh)"
            /usr/local/nginx/sbin/nginx -s reload
            ```
      2. 非平滑更新(重装更新)
         1. 卸载当前 nginx
            ```sh
            systemctl -q is-active nginx && systemctl stop nginx
            systemctl -q is-enabled nginx && systemctl disable nginx
            rm -rf /etc/systemd/system/nginx.service
            systemctl daemon-reload
            rm -rf /usr/local/nginx
            ```
         2. 编译安装
            ```sh
            bash -c "$(curl -L https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/nginx_compile.sh)"
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
