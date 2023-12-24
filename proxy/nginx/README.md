# Nginx 与 SSL

## Nginx

### 支持的操作系统

  - Ubuntu 20+
  - Debian 10+
  - CentOS 7+

### 安装 Nginx 管理脚本

```bash
curl -fsSL https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/nginx_manage.sh -o ${HOME}/nginx.sh && chmod a+x ${HOME}/nginx.sh
```

### Nginx 管理脚本选项

- `-i, --install`: 包管理器安装 Nginx（默认选项）。
- `-c, --compile`: 编译安装 Nginx。
- `-u, --update`: 更新 Nginx。
- `-p, --purge`: 删除 Nginx。
- `-h, --help`: 显示使用信息。

### Nginx 管理脚本示例

- 包管理器安装 Nginx:

  ```bash
  ${HOME}/nginx.sh
  ```

- 编译安装 Nginx:

  ```bash
  ${HOME}/nginx.sh -c
  ```

- 更新 Nginx:

  ```bash
  ${HOME}/nginx.sh -u
  ```

- 删除 Nginx:

  ```bash
  ${HOME}/nginx.sh -p
  ```

### 定时任务

- 添加 nginx 定时更新任务

  ```bash
  (crontab -l 2>/dev/null; echo "0 3 * * * ${HOME}/nginx.sh -u >/dev/null 2>&1") | awk '!x[$0]++' | crontab -
  ```

- 删除 nginx 定时更新任务

  ```bash
  (crontab -l 2>/dev/null | grep -v "${HOME}/nginx.sh -u >/dev/null 2>&1") | crontab -
  ```

### 注意事项

- 更新/删除选项 (`-u/-p`) 旨在用于更新/删除通过此脚本安装的 Nginx。如果 Nginx 不是通过此脚本安装的，则使用 `-u/-p` 可能导致意外行为。

## SSL

### 安装 SSL 管理脚本

```bash
curl -fsSL https://raw.githubusercontent.com/zxcvos/Note/main/proxy/nginx/ssl_manage.sh -o ${HOME}/ssl.sh && chmod a+x ${HOME}/ssl.sh
```

### SSL 管理脚本选项

- `-u, --update`: 更新 acme.sh。
- `-p, --purge`: 删除 acme.sh 并删除相关目录。
- `-i, --issue`: 发行/更新SSL证书，需要配合 `-d` 选项使用。
- `-r, --renew`: 强制更新所有SSL证书。
- `-s, --stop-renew`: 停止续订指定的SSL证书，需要配合 `-d` 选项使用。
- `-c, --check-cron`: 检查crontab设置自动续订。
- `--info`: 显示指定的SSL证书的信息，需要配合 `-d` 选项使用。
- `-d, --domain`: 指定域（该选项可重复多次）。
- `-n, --nginx`: 指定NGINX配置路径。
- `-w, --webroot`: 指定ACME-Challenge验证目录路径。
- `-t, --tls`: 指定SSL安装目录路径（默认安装在nginx配置路径下的ssl目录，例如：/etc/nginx/ssl/example.com）。
- `-h, --help`: 显示使用信息。

### SSL 管理脚本示例

- 生成并安装证书:

  ```bash
  ${HOME}/ssl.sh -i -d example.com
  ```

- 查看已安装证书信息:

  ```bash
  ${HOME}/ssl.sh --info -d example.com
  ```

- 强制更新证书:

  ```bash
  ${HOME}/ssl.sh -r
  ```

- 停止续订指定的证书:

  ```bash
  ${HOME}/ssl.sh -s -d example.com
  ```

- 更新 acme.sh:

  ```bash
  ${HOME}/ssl.sh -u
  ```

- 删除 acme.sh:

  ```bash
  ${HOME}/ssl.sh -p
  ```

## 感谢

[nginx: Linux packages](https://nginx.org/en/linux_packages.html)

[nginx 的平滑升级 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/193078620)

[kirin10000 · GitHub](https://github.com/kirin10000/Xray-script)

[[小白参阅系列] 第〇篇 手搓 Nginx 安装 (nodeseek.com)](https://www.nodeseek.com/post-37224-1)

[google/ngx_brotli (github.com)](https://github.com/google/ngx_brotli)

[acmesh-official/acme.sh (github.com)](https://github.com/acmesh-official/acme.sh)
