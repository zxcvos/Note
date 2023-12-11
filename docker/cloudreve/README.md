## Cloudreve

### 获取 Docker Compose 文件

```shell
mkdir -vp /usr/local/cloudreve \
&& curl -fsSL -o /usr/local/cloudreve/docker-compose.yaml https://raw.githubusercontent.com/zxcvos/Note/main/docker/cloudreve/docker-compose.yaml \
&& sed -i "s/your_aria_rpc_token/$(openssl rand -hex 32)/" /usr/local/cloudreve/docker-compose.yaml
```

### 创建目录结构

```shell
mkdir -vp /usr/local/cloudreve/cloudreve/{uploads,avatar} \
&& touch /usr/local/cloudreve/cloudreve/conf.ini \
&& touch /usr/local/cloudreve/cloudreve/cloudreve.db \
&& mkdir -vp /usr/local/cloudreve/aria2/config \
&& mkdir -vp /usr/local/cloudreve/data/aria2 \
&& chmod -R 777 /usr/local/cloudreve/data/aria2
```

### 运行

```shell
cd /usr/local/cloudreve && docker compose up -d
```

### 获取默认管理员账户用户名和密码

```shell
docker logs cloudreve
```

### 手动更新(默认每天 22:30 定时执行更新)

```shell
cd /usr/local/cloudreve \
&& docker compose stop \
&& docker compose pull \
&& docker compose up -d
```

## 感谢

[Cloudreve](https://docs.cloudreve.org/)
