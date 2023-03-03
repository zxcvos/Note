#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author: zxcvos

import argparse
from collections import defaultdict
import os

def remove_files_by_name(path, file_names):
    removed_files = defaultdict(list)
    stack = [path]
    while stack:
        entry = stack.pop()
        with os.scandir(entry) as it:
            for item in it:
                if item.is_file() and item.name in file_names:
                    removed_files[item.name].append(os.path.abspath(item.path))
                    os.remove(item.path)
                elif item.is_dir():
                    stack.append(item.path)
    if len(removed_files) == 0:
        for name in file_names:
            print(f'没有找到 {name} 文件')
    else:
        not_found_files = list(filter(lambda name: not removed_files.get(name), file_names))
        for name in removed_files:
            print(f'{name} 文件所在的路径:')
            for file_path in removed_files[name]:
                print(file_path)
        if not_found_files and removed_files:
            print('==========')
        for name in not_found_files:
            print(f'没有找到 {name} 文件')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='删除指定目录下的所有指定名称的文件')
    parser.add_argument('-d', '--directory', type=str, help='要删除的文件所在目录', default='.')
    parser.add_argument('-f', '--file', type=str, nargs='+', help='要删除的文件名称', required=True)
    args = parser.parse_args()
    remove_files_by_name(args.directory, args.file)
