## Reader

### 获取 Docker Compose 文件

```shell
mkdir -vp /usr/local/reader \
&& curl -fsSL -o /usr/local/reader/docker-compose.yaml https://raw.githubusercontent.com/zxcvos/Note/main/docker/reader/docker-compose.yaml
```

### 创建目录结构

```shell
mkdir -vp /usr/local/reader/{logs,storage}
```

### 运行

```shell
cd /usr/local/reader && docker compose up -d
```

### 手动更新(默认每天 22:30 定时执行更新)

```shell
cd /usr/local/reader \
&& docker compose stop \
&& docker compose pull \
&& docker compose up -d
```

## 感谢

[reader: 阅读3服务器版](https://github.com/hectorqin/reader)
