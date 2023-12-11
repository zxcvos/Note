## Cloudflare Warp

### 获取 Dockerfile 文件

```shell
mkdir -vp /usr/local/cloudflare_warp \
&& curl -fsSL -o /usr/local/cloudflare_warp/Dockerfile https://raw.githubusercontent.com/zxcvos/Note/main/docker/cloudflare-warp/Dockerfile \
&& curl -fsSL -o /usr/local/cloudflare_warp/startup.sh https://raw.githubusercontent.com/zxcvos/Note/main/docker/cloudflare-warp/startup.sh
```

### 创建 Docker 镜像

```shell
cd /usr/local/cloudflare_warp  && docker build -t cloudflare-warp .
```

### 运行

```shell
docker run -v ${HOME}/.warp:/var/lib/cloudflare-warp:rw --restart=always --name=cloudflare-warp cloudflare-warp
```

### 查看这个容器的 ip

```shell
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cloudflare-warp
```

### 测试连通性，如果容器的 ip 是 `172.170.0.2`

```shell
docker run --rm curlimages/curl --connect-timeout 2 -x "socks5://172.17.0.2:40001" ipinfo.io
```

## 感谢

[haoel/haoel.github.io](https://github.com/haoel/haoel.github.io?tab=readme-ov-file#1043-docker-代理)

[e7h4n/cloudflare-warp](https://github.com/e7h4n/cloudflare-warp)
