## Xray 管理
### 安装/更新 Xray-core
```sh
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
```
### 卸载 Xray-core
```sh
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
```
### Xray 文件安装位置
* system 配置文件
  ```sh
  /etc/systemd/system/xray.service
  /etc/systemd/system/xray@.service
  ```
* Xray 应用
  ```sh
  /usr/local/bin/xray
  ```
* Xray 配置文件
  ```sh
  /usr/local/etc/xray/*.json
  ```
* geo 文件
  ```sh
  /usr/local/share/xray/geoip.dat
  /usr/local/share/xray/geosite.dat
  ```
* 日志文件
  ```sh
  /var/log/xray/access.log
  /var/log/xray/error.log
  ```
### Xray 使用
* 启动
  ```sh
  systemctl is-active xray || systemctl start xray
  systemctl is-enabled xray || systemctl enable xray
  ```
* 暂停
  ```sh
  systemctl is-active xray && systemctl stop xray
  systemctl is-enabled xray && systemctl disable xray
  ```
* 重启
  ```sh
  systemctl is-active xray && systemctl restart xray || systemctl start xray
  ```
* 查看状态
  ```sh
  systemctl status xray
  ```
