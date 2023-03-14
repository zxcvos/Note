# VPS 常用脚本工具

* 测速(speedtest.sh)

  ```sh
  wget -qO- https://raw.githubusercontent.com/zxcvos/Note/main/proxy/tools/speedtest.sh | bash
  ```

* 秋水逸冰

  * 显示各种系统信息，网络和 IO 测试(bench.sh)

    ```sh
    wget -qO- bench.sh | bash
    ```

  * 性能测试(unixbench.sh)

    ```sh
    wget --no-check-certificate -qO- https://github.com/teddysun/across/raw/master/unixbench.sh | bash
    ```

* YABS - 使用 fio、iperf3 和 Geekbench 评估 Linux 服务器的性能

  * 网络测试
    ```sh
    wget -qO- yabs.sh | bash -s -- -bfg
    ```

  * 磁盘测试
    ```sh
    wget -qO- yabs.sh | bash -s -- -big
    ```

  * 系统性能测试
    ```sh
    wget -qO- yabs.sh | bash -s -- -bfi
    ```

  * 完整测试
    ```sh
    wget -qO- yabs.sh | bash
    ```

* sjlleo

  * NetFlix 解锁检测

    * amd64
      ```sh
      wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0-1/nf_linux_amd64 && chmod +x nf && ./nf
      ```

    * arm64
      ```sh
      wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0-1/nf_linux_arm64 && chmod +x nf && ./nf
      ```

    * mips
      ```sh
      wget -O nf https://github.com/sjlleo/netflix-verify/releases/download/v3.1.0-1/nf_linux_mips && chmod +x nf && ./nf
      ```
