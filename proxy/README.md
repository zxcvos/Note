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
## Nginx 管理
## 定时任务管理
* 自动更新 geo 文件
  * 获取 geo 更新脚本
    ```sh
echo "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKc2V0IC1lCgpYUkFZX0RJUj0iL3Vzci9sb2NhbC9zaGFyZS94cmF5IgoKR0VPSVBfVVJMPSJodHRwczovL2dpdGh1Yi5jb20vTG95YWxzb2xkaWVyL3YycmF5LXJ1bGVzLWRhdC9yYXcvcmVsZWFzZS9nZW9pcC5kYXQiCkdFT1NJVEVfVVJMPSJodHRwczovL2dpdGh1Yi5jb20vTG95YWxzb2xkaWVyL3YycmF5LXJ1bGVzLWRhdC9yYXcvcmVsZWFzZS9nZW9zaXRlLmRhdCIKClsgLWQgJFhSQVlfRElSIF0gfHwgbWtkaXIgLXAgJFhSQVlfRElSCmNkICRYUkFZX0RJUgoKY3VybCAtTCAtbyBnZW9pcC5kYXQubmV3ICRHRU9JUF9VUkwKY3VybCAtTCAtbyBnZW9zaXRlLmRhdC5uZXcgJEdFT1NJVEVfVVJMCgpybSAtZiBnZW9pcC5kYXQgZ2Vvc2l0ZS5kYXQKCm12IGdlb2lwLmRhdC5uZXcgZ2VvaXAuZGF0Cm12IGdlb3NpdGUuZGF0Lm5ldyBnZW9zaXRlLmRhdAoKc3lzdGVtY3RsIC1xIGlzLWFjdGl2ZSB4cmF5ICYmIHN5c3RlbWN0bCByZXN0YXJ0IHhyYXkKc3lzdGVtY3RsIC1xIGlzLWFjdGl2ZSBuZ2lueCAmJiBzeXN0ZW1jdGwgcmVzdGFydCBuZ2lueAo=" | base64 -d > update_dat.sh
    ```
  * 将 geo 更新脚本设置为可执行文件
    ```sh
chmod a+x update_dat.sh
    ```
  * 添加定时任务
    1. 使用 `crontab -e` 编辑定时任务
       ```sh
30 6 * * * $HOME/update_dat.sh >/dev/null 2>&1
       ```
    2. 使用命令行形式快速添加
       ```sh
(crontab -l >/dev/null 2>&1 && (crontab -l | grep "30 6 \* \* \* $HOME/update_dat.sh >/dev/null 2>&1" || crontab -l | { cat; echo "30 6 * * * $HOME/update_dat.sh >/dev/null 2>&1"; }) || echo "30 6 * * * $HOME/update_dat.sh >/dev/null 2>&1") | crontab -
       ```
