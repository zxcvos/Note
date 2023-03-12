# 工具集

## remove_files.py

作用：

* 批量删除指定名称、后缀的文件

选项：

* -d: 要删除的文件所在目录，默认值为当前所在目录

* -f: 删除的文件的名称
* -s: 要删除的文件的后缀

```sh
# 写法一
python3 remove_files.py -f test -s py
# 写法二
python3 remove_files.py -f test -s .py
# 写法三
python3 remove_files.py -f test.py
```



