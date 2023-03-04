#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# Author: zxcvos

import argparse
import os
import sys
import re

from collections import defaultdict

def remove_files_by_name(path, file_names, file_suffixes=None):
    if file_suffixes:
        file_names = [f'{name}{suffix}' if suffix.startswith('.') else f'{name}.{suffix}' for suffix in file_suffixes for name in file_names]
    file_names = list(filter(lambda name: os.path.abspath(name) != os.path.abspath(sys.argv[0]), file_names))
    remove_files, _ = find_files(path, file_names)
    not_found_files = list(filter(lambda name: not remove_files.get(name), file_names))
    for name in remove_files:
        print(f'{name} 文件所在的路径:')
        for file_path in remove_files[name]:
            os.remove(file_path)
            print(file_path)
    if not_found_files and remove_files:
        print('==========')
    for name in not_found_files:
        print(f'没有找到 {name} 文件')


def remove_files_by_suffix(path, file_suffixes):
    _, remove_suffixes = find_files(path, file_suffixes=file_suffixes)
    file_names = [value for values in remove_suffixes.values() for value in values]
    if file_names:
        print('正在使用删除指定后缀文件的方式删除文件，以下是相关文件名称：')
        for i in range(len(file_names)):
            print(f'{i + 1}.{file_names[i]}')
        idxs = input('为了防止误删，请输入要删除的文件编号进行确认，使用英文逗号分割：').strip().replace(' ', '')
        if re.match(r'^\d+(,\d+)*$', idxs):
            remove_files = []
            for i in list(map(lambda i: int(i), idxs.split(','))):
                if i > 0 and i <= len(file_names):
                    remove_files.append(file_names[i - 1])
            remove_files_by_name(path, remove_files)
        else:
            print('请按提示输入！')
    else:
        print(f'没有找到 {" ".join(file_suffixes)} 相关后缀的文件')


def find_files(path, file_names=[], file_suffixes=[]):
    file_paths = defaultdict(list)
    file_suffix_names = defaultdict(list)
    stack = [path]
    while stack:
        entry = stack.pop()
        with os.scandir(entry) as it:
            for item in it:
                remove_suffix = list(filter(lambda t: item.name.endswith(t), file_suffixes))
                if item.is_file():
                    if item.name in file_names:
                        file_paths[item.name].append(os.path.abspath(item.path))
                    elif remove_suffix and item.name not in file_suffix_names[remove_suffix[0]]:
                        file_suffix_names[remove_suffix[0]].append(item.name)
                elif item.is_dir():
                    stack.append(item.path)
    return file_paths, file_suffix_names


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog=sys.argv[0], description='删除指定目录下的所有指定名称的文件')
    parser.add_argument('-d', '--directory', type=str, help='要删除的文件所在目录，默认值为当前所在目录', default='.')
    parser.add_argument('-f', '--file', type=str, nargs='+', help='要删除的文件的名称')
    parser.add_argument('-s', '--suffix', type=str, nargs='+', help='要删除的文件的后缀')
    args = parser.parse_args()
    if args.file and args.suffix:
        remove_files_by_name(args.directory, args.file, args.suffix)
    elif args.file:
        remove_files_by_name(args.directory, args.file)
    elif args.suffix:
        remove_files_by_suffix(args.directory, args.suffix)
    else:
        parser.print_help()
