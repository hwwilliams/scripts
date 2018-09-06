import os, sys, subprocess, shlex, re
import simplejson as json
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


def check_size(files_types_dictionary, sorted_dca_files_dictionary):
    file_size = 0
    for file, type in files_types_dictionary.items():
        file_size = file_size + os.path.getsize(file)
    for file, type in sorted_dca_files_dictionary.items():
        file_size = file_size + os.path.getsize(file)
    return size(file_size)


def fetch_files(path_walked_dictionary):
    files_types = {}
    dca_files = {}
    for file, root in path_walked_dictionary.items():
        cmd = ['ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_format', '-show_streams', os.path.join(root, file)]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        for item in json.loads(out)['streams']:
            if item.get('codec_long_name'):
                if 'DCA (DTS Coherent Acoustics)' in item.get('codec_long_name'):
                    dca_files[os.path.join(root, file)] = item.get('codec_long_name')
                elif not 'binary data' in item.get('codec_long_name'):
                    if not 'SubRip subtitle' in item.get('codec_long_name'):
                        if not 'Motion JPEG' in item.get('codec_long_name'):
                            if not 'MOV text' in item.get('codec_long_name'):
                                if not 'AAC (Advanced Audio Coding)' in item.get('codec_long_name'):
                                    if not 'H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10' in item.get('codec_long_name'):
                                        if not 'ATSC A/52A (AC-3)' in item.get('codec_long_name'):
                                            if not 'HDMV Presentation Graphic Stream subtitles' in item.get('codec_long_name'):
                                                if not 'ATSC A/52B (AC-3, E-AC-3)' in item.get('codec_long_name'):
                                                    if not 'TrueType font' in item.get('codec_long_name'):
                                                        if not 'ASS (Advanced SSA) subtitle' in item.get('codec_long_name'):
                                                            if not 'MPEG-2 video' in item.get('codec_long_name'):
                                                                if not 'Vorbis' in item.get('codec_long_name'):
                                                                    if not 'Opus (Opus Interactive Audio Codec)' in item.get('codec_long_name'):
                                                                        if not 'EIA-608 closed captions' in item.get('codec_long_name'):
                                                                            if not 'DVD subtitles' in item.get('codec_long_name'):
                                                                                if not 'MPEG-4 part 2' in item.get('codec_long_name'):
                                                                                    if not 'PNG (Portable Network Graphics) image' in item.get('codec_long_name'):
                                                                                        if not 'FLAC (Free Lossless Audio Codec)' in item.get('codec_long_name'):
                                                                                            if not 'BMP (Windows and OS/2 bitmap)' in item.get('codec_long_name'):
                                                                                                files_types[os.path.join(root, file)] = item.get('codec_long_name')
        if err:
            print(err)
            terminate()
    return files_types, dca_files


def handle_dca(dca_files_dictionary):
    sorted_dca_files = {}
    for file, root in dca_files_dictionary.items():
        cmd = ['ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_format', '-show_streams', os.path.join(root, file)]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        for item in json.loads(out)['streams']:
            if item.get('profile'):
                if not '192' in item.get('profile'):
                    if not 'Main' in item.get('profile'):
                        if not 'High' in item.get('profile'):
                            if not 'PNG (Portable Network Graphics) image' in item.get('profile'):
                                if not 'BMP (Windows and OS/2 bitmap)' in item.get('profile'):
                                    if not 'DVD subtitles' in item.get('profile'):
                                        if not 'FLAC (Free Lossless Audio Codec)' in item.get('profile'):
                                            if not 'LC' in item.get('profile'):
                                                if not 'Opus (Opus Interactive Audio Codec)' in item.get('profile'):
                                                    if not 'MPEG-4 part 2' in item.get('profile'):
                                                        if not 'EIA-608 closed captions' in item.get('profile'):
                                                            if 'DTS-HD MA' in item.get('profile'):
                                                                sorted_dca_files[os.path.join(root, file)] = item.get('profile')
                                                            elif not 'DTS' in item.get('profile'):
                                                                sorted_dca_files[os.path.join(root, file)] = item.get('profile')
        if err:
            print(err)
            terminate()
    return sorted_dca_files


def main():
    search_directory_set = check_path('Which directory would you like to search (recursively)? ')
    path_walked = walk_the_path(search_directory_set)
    files_types, dca_files = fetch_files(path_walked)
    if len(dca_files) >= 1:
        sorted_dca_files = handle_dca(dca_files)
    list_files(files_types, sorted_dca_files)
    file_size = check_size(files_types, sorted_dca_files)
    print(file_size)
    terminate()


def list_files(files_types_dictionary, sorted_dca_files_dictionary):
    for file, type in files_types_dictionary.items():
        print(f'{{{file}}}: {{{type}}}')
    if len(sorted_dca_files_dictionary) >= 1:
        for file, type in sorted_dca_files_dictionary.items():
            print(f'{{{file}}}: {{{type}}}')
    total_files = len(files_types_dictionary)
    if len(sorted_dca_files_dictionary) >= 1:
        total_files = total_files + len(sorted_dca_files_dictionary)
    print(total_files)


os.path.join()

def terminate():
    print('Exiting script.')
    sys.exit()


def walk_the_path(valid_directory_set):
    path_walked = {}
    extension_list = ['mkv', 'mp4']
    for valid_dir in valid_directory_set:
        for root, subdirs, files in os.walk(valid_dir):
            for file in files:
                if file.endswith(tuple(extension_list)):
                    path_walked[file] = root
    if len(path_walked) == 0:
        print(f'{bcolors.YELLOW}No files found when searching for files ending with ".{extension_list}".{bcolors.RESET}')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked


if __name__ == '__main__':
    main()
