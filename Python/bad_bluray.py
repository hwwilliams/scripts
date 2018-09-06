import os, sys, subprocess, shlex, re, json
from subprocess import call
from pprint import pprint
from hurry.filesize import size


class bcolors:
    BOLD = '\033[1m'
    RED = '\033[91m'
    RESET = '\033[0m'
    YELLOW = '\033[93m'


def ask(confirmation_prompt, default_answer_no=False):
    while True:
        answer = (input(confirmation_prompt).strip()).lower()
        if default_answer_no and answer == '' or answer.startswith('n'):
            return False
        elif answer == '' or answer.startswith('y'):
            return True
        elif answer == 'exit':
            terminate()
        else:
            print(f'{bcolors.YELLOW}Invalid Input: Please enter yes or no.{bcolors.RESET}')


def check_path(directory_path_prompt):
    search_directory_set = set([])
    while True:
        input_directory = input(directory_path_prompt)
        if input_directory.lower() == 'exit':
            terminate()
        if (input_directory.strip()).startswith('.\\'):
            input_directory = (input_directory.strip()).replace('.\\', '', 1)
        input_directory = os.path.join((os.getcwd()), input_directory)
        if os.path.isdir(input_directory):
            search_directory_set.add(input_directory)
            if ask('Would you like to add another directory to search (y/N)? ', True):
                continue
            else:
                return search_directory_set
        else:
            print(f'{bcolors.YELLOW}Invalid Directory Path: Please enter a valid directory path.{bcolors.RESET}')
            continue


def fetch_files(path_walked_dictionary):
    bad_bluray_1080p = {}; bad_webdl_1080p = {}
    bad_bluray_720p = {}; bad_webdl_720p = {}
    size_limit = [11542724608, 8750995865.6]
    for file, root in path_walked_dictionary.items():
        if 'bluray-1080p' in file.lower():
            if os.path.getsize(os.path.join(root, file)) < size_limit[0]:
                bad_bluray_1080p[os.path.join(root, file)] = size(os.path.getsize(os.path.join(root, file)))
        elif 'webdl-1080p' in file.lower():
            if os.path.getsize(os.path.join(root, file)) < size_limit[0]:
                bad_webdl_1080p[os.path.join(root, file)] = size(os.path.getsize(os.path.join(root, file)))
        elif 'bluray-720p'in file.lower():
            if os.path.getsize(os.path.join(root, file)) < size_limit[1]:
                bad_bluray_720p[os.path.join(root, file)] = size(os.path.getsize(os.path.join(root, file)))
        elif 'webdl-720p'in file.lower():
            if os.path.getsize(os.path.join(root, file)) < size_limit[1]:
                bad_webdl_720p[os.path.join(root, file)] = size(os.path.getsize(os.path.join(root, file)))
    return bad_bluray_1080p, bad_webdl_1080p, bad_bluray_720p, bad_webdl_720p


def main():
    search_directory_set = check_path('Which directory would you like to search (recursively)? ')
    path_walked = walk_the_path(search_directory_set)
    bad_bluray_1080p, bad_webdl_1080p, bad_bluray_720p, bad_webdl_720p = fetch_files(path_walked)
    for key, value in bad_bluray_1080p.items():
        print(f'{key}: {value}')
    #list_files(files_types)
    terminate()


def terminate():
    print('Exiting script.')
    sys.exit()


def walk_the_path(valid_directory_set):
    path_walked = {}
    extension_list = ['mp4','mkv']
    for valid_dir in valid_directory_set:
        for root, subdirs, files in os.walk(valid_dir):
            for file in files:
                if file.endswith(tuple(extension_list)):
                    path_walked[file] = root
    if len(path_walked) == 0:
        print(f'{bcolors.YELLOW}No files found when searching for files ending with ".{extension_limit}".{bcolors.RESET}')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked


if __name__ == '__main__':
    main()
