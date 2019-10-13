import os
from general import ask, terminate

class bcolors:
    BOLD = '\033[1m'
    RED = '\033[91m'
    RESET = '\033[0m'
    YELLOW = '\033[93m'

def check(directory_path_prompt):
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

def walk(valid_directory_set):
    path_walked = {}
    for valid_dir in valid_directory_set:
        for root, subdirs, files in os.walk(valid_dir):
            for file in files:
                path_walked[file] = root
    if len(path_walked) == 0:
        print(f'{bcolors.YELLOW}No files were found.{bcolors.RESET}')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked
