import os
import sys
import ffmpy
import platform


class bcolors:
    YELLOW = '\033[93m'
    RED = '\033[91m'
    RESET = '\033[0m'


'''
http://ffmpy.readthedocs.io/en/latest/
https://stackoverflow.com/questions/42438380/ffmpeg-in-python-script
https://superuser.com/questions/323119/how-can-i-normalize-audio-using-ffmpeg
'''

# import tempfile
# import shutil
#
# dirpath = tempfile.mkdtemp()
# # ... do stuff with dirpath
# shutil.rmtree(dirpath)

def check_path(directory_path):
    while True:
        input_directory = str(input(directory_path)).strip()
        if input_directory.startswith('.\\'):
            input_directory = input_directory.replace('.\\', '', 1)
        search_directory = os.path.join((os.getcwd()), input_directory)
        if os.path.isdir(search_directory):
            break
        else:
            print(f'{bcolors.YELLOW}Invalid Directory Path: Please enter a valid directory path.{bcolors.RESET}')
            continue
    return search_directory


def correct_volume(needs_volume_dictionary):
    for volume, file_path in needs_volume_dictionary.items():
        os.system(f"ffmpeg -i "{file_path}" -af "volume={volume}dB" -c:v copy -c:a aac -b:a 192k output.mp4")


def main():
    search_directory = check_path('Which directory would you like to search (recursively)? ')
    path_walked = walk_the_path(search_directory)
    video_volume = probe_volume(path_walked)
    needs_volume = sort_volume_info(path_walked, video_volume)
    correct_volume(needs_volume)


def probe_volume(path_walked_dictionary):
    video_volume = {}
    for file, root in path_walked_dictionary.items():
        if platform.system().lower == 'linux':
            video_volume[os.path.join(root, file)] = os.system(f"ffmpeg -i {os.path.join(root, file)} -af "volumedetect" -vn -sn -dn -f null /dev/null")
        elif platform.system().lower == 'windows':
            video_volume[os.path.join(root, file)] = os.system(f"ffmpeg -i {os.path.join(root, file)} -af "volumedetect" -vn -sn -dn -f null NUL")
    return video_volume


def sort_volume_info(path_walked_dictionary, video_volume_dictionary):
    mean_lines = {}
    max_lines = {}
    mean_volume = {}
    max_volume = {}
    needs_volume = {}
    for file_path, volume_info in video_volume_dictionary.items()
        for volume_line in volume_info.splitlines():
            if 'mean' in volume_line:
                mean_lines[volume_line] = file_path
            elif 'max' in volume_line:
                max_lines[volume_line] = file_path
    for volume_line, file_path in max_lines.items():
        max_volume[(((volume_line.split(':'))[-1])[0:-((len(((volume_line.split(' '))[-1]).strip())+1))].strip())] = file_path
    for volume_line, file_path in mean_lines.items():
        mean_volume[(((volume_line.split(':'))[-1])[0:-((len(((volume_line.split(' '))[-1]).strip())+1))].strip())] = file_path
    for volume, file_path in max_volume.items():
        if 0 not in volume or 0.0 not in volume:
            if volume.startswith('-'):
                volume = volume.replace('-', '', 1)
            needs_volume[volume] = file_path
    return needs_volume


def valid_extension(extension):
    valid_extension_list = ['mp4', 'mkv', 'avi']
    while True:
        extension_limit = (str(input(extension)).strip()).lower()
        if extension_limit.startswith('.'):
            extension_limit = extension_limit.replace('.', '', 1)
        if extension_limit in valid_extension_list:
            break
        else:
            print(f'{bcolors.YELLOW}Invalid Input: Please enter one of the following supported extensions {valid_extension_list}.{bcolors.RESET}')
            continue
    return extension_limit


def walk_the_path(valid_directory_path):
    path_walked = {}
    extension_limit = valid_extension('What file extension would you like to use to narrow the search? ')
    for root, subdirs, files in os.walk(valid_directory_path):
        for file in files:
            if file.endswith(extension_limit):
                path_walked[file] = root
    if len(path_walked) == 0:
        print(f'{bcolors.YELLOW}No files found when searching for files ending with ".{extension_limit}".{bcolors.RESET}')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked


if __name__ == '__main__':
    main()
