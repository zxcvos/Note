#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author: zxcvos

import argparse
import os

def remove_files_by_name(path, file_names):
    file_names = set(file_names)
    removed_files = set()
    removed_file_paths = {}
    stack = [path]
    for root, dirs, files in os.walk(stack.pop()):
        for name in files:
            if name in file_names:
                removed_files.add(name)
                if removed_file_paths.get(name):
                    removed_file_paths[name].append(os.path.abspath(root))
                else:
                    removed_file_paths[name] = [os.path.abspath(root)]
                os.remove(os.path.join(root, name))
        for name in dirs:
            stack.append(os.path.join(root, name))
    if len(removed_files) == 0:
        for name in file_names:
            print(f'没有找到 {name} 文件')
    else:
        not_found_files = file_names - removed_files
        for name in removed_files:
            for dirname in removed_file_paths[name]:
                print(f'{name} 文件所在的路径: {dirname}')
            print(f'已删除所有 {name} 文件')
        print("==========")
        for name in not_found_files:
            print(f'没有找到 {name} 文件')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='删除指定目录下的所有指定名称的文件')
    parser.add_argument('-d', '--directory', type=str, help='要删除的文件所在目录', default='.')
    parser.add_argument('-f', '--file', type=str, nargs='+', help='要删除的文件名称', required=True)
    args = parser.parse_args()
    remove_files_by_name(args.directory, args.file)
