# Docker 安装

## 官方 Docker 安装脚本

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

## 自定义 Docker 安装脚本

### 安装

```bash
curl -fsSL https://raw.githubusercontent.com/zxcvos/Note/main/docker/docker_manage.sh -o docker_manage.sh
chmod a+x docker_manage.sh
```

### 选项

- `-i, --install`: 安装 Docker。
- `-u, --update`: 更新 Docker。
- `-r, --remove`: 删除 Docker。
- `-h, --help`: 显示使用信息。

### 示例

- 安装 Docker:
  ```bash
  docker_manage.sh -i
  ```

- 更新 Docker:
  ```bash
  docker_manage.sh -u
  ```

- 删除 Docker:
  ```bash
  docker_manage.sh -r
  ```

### 支持的操作系统

- Ubuntu 18+
- Debian 10+
- CentOS 7+

### 注意事项

- 更新选项 (`-u`) 旨在用于更新通过此脚本安装的 Docker。如果 Docker 不是通过此脚本安装的，则使用 `-u` 可能导致意外行为。
