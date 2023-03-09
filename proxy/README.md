# 手动配置 xray 代理服务
## 目录
* [Xray 管理](Xray 管理)
* [Nginx 管理](Nginx 管理)
* [定时任务管理](定时任务管理)
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
  ```
/etc/systemd/system/xray.service
/etc/systemd/system/xray@.service
  ```
* Xray 应用
  ```
/usr/local/bin/xray
  ```
* Xray 配置文件
  ```
/usr/local/etc/xray/*.json
  ```
* geo 文件
  ```
/usr/local/share/xray/geoip.dat
/usr/local/share/xray/geosite.dat
  ```
* 日志文件
  ```
/var/log/xray/access.log
/var/log/xray/error.log
  ```
### Xray 使用
* 启动
  ```
systemctl is-active xray || systemctl start xray
systemctl is-enabled xray || systemctl enable xray
  ```
* 暂停
  ```
systemctl is-active xray && systemctl stop xray
systemctl is-enabled xray && systemctl disable xray
  ```
* 重启
  ```
systemctl is-active xray && systemctl restart xray || systemctl start xray
  ```
* 查看状态
  ```
systemctl status xray
  ```
## Nginx 管理
## 定时任务管理
