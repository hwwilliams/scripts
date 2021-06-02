import os
import sys
import shutil


def main():
    search_directory_set = check_path(
        'Which directory would you like to search (recursively)? ')
    files_found = walk_the_path(search_directory_set)
    gif_files, picture_files, video_files = sort_files(files_found)
    list_files(gif_files, picture_files, video_files)
    create_directories(gif_files, picture_files,
                       video_files, search_directory_set)
    move_files(gif_files, picture_files, video_files, search_directory_set)
    remove_empty_folders(search_directory_set)
    terminate()


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
            print('Invalid Input: Please enter yes or no.')


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
            print('Invalid Directory Path: Please enter a valid directory path.')
            continue


def walk_the_path(valid_directory_set):
    path_walked = {}
    for valid_directory in valid_directory_set:
        for root, subdirectories, files in os.walk(valid_directory):
            for file in files:
                path_walked[file] = root
    if len(path_walked) == 0:
        print('No files were found in the specified location(s).')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked


def sort_files(path_walked_dictionary):
    gif_extension = ['gif']
    gif_files = {}
    picture_extension = ['png', 'jpeg', 'jpg']
    picture_files = {}
    video_extension = ['mp4', 'mkv', 'webm']
    video_files = {}
    for file, root in path_walked_dictionary.items():
        for extension in gif_extension:
            if file.endswith(extension):
                gif_files[file] = root
        for extension in picture_extension:
            if file.endswith(extension):
                picture_files[file] = root
        for extension in video_extension:
            if file.endswith(extension):
                video_files[file] = root
    return gif_files, picture_files, video_files


def list_files(gif_dictionary, picture_dictionary, video_dictionary):
    if len(gif_dictionary) >= 1:
        print(f'Found {len(gif_dictionary)} gif(s).')
    if len(picture_dictionary) >= 1:
        print(f'Found {len(picture_dictionary)} pictures(s).')
    if len(video_dictionary) >= 1:
        print(f'Found {len(video_dictionary)} video(s).')


def create_directories(gif_dictionary, picture_dictionary, video_dictionary, valid_directory_set):
    for valid_directory in valid_directory_set:
        if len(gif_dictionary) >= 1:
            if not os.path.exists(os.path.join(valid_directory, 'gifs')):
                os.makedirs(os.path.join(valid_directory, 'gifs'))
                if os.path.exists(os.path.join(valid_directory, 'gifs')):
                    print(
                        f'Successfully created folder: {os.path.join(valid_directory, "gifs")}')
                else:
                    print(
                        f'Failed to create folder: {os.path.join(valid_directory, "gifs")}')
        if len(picture_dictionary) >= 1:
            if not os.path.exists(os.path.join(valid_directory, 'pictures')):
                os.makedirs(os.path.join(valid_directory, 'pictures'))
                if os.path.exists(os.path.join(valid_directory, 'pictures')):
                    print(
                        f'Successfully created folder: {os.path.join(valid_directory, "pictures")}')
                else:
                    print(
                        f'Failed to create folder: {os.path.join(valid_directory, "pictures")}')
        if len(video_dictionary) >= 1:
            if not os.path.exists(os.path.join(valid_directory, 'videos')):
                os.makedirs(os.path.join(valid_directory, 'videos'))
                if os.path.exists(os.path.join(valid_directory, 'videos')):
                    print(
                        f'Successfully created folder: {os.path.join(valid_directory, "videos")}')
                else:
                    print(
                        f'Failed to create folder: {os.path.join(valid_directory, "videos")}')


def move_files(gif_dictionary, picture_dictionary, video_dictionary, valid_directory_set):
    for valid_directory in valid_directory_set:
        if len(gif_dictionary) >= 1:
            for file, root in gif_dictionary.items():
                if shutil.move((os.path.join(root, file)), (os.path.join(valid_directory, "gifs", file))):
                    if os.path.exists(os.path.join(valid_directory, "gifs", file)):
                        print(
                            f'Successfully moved file: {os.path.join(valid_directory, "gifs", file)}')
                    else:
                        print(
                            f'Failed to move file: {os.path.join(root, "gifs", file)}')
        if len(picture_dictionary) >= 1:
            for file, root in picture_dictionary.items():
                if shutil.move((os.path.join(root, file)), (os.path.join(valid_directory, "pictures", file))):
                    if os.path.exists(os.path.join(valid_directory, "pictures", file)):
                        print(
                            f'Successfully moved file: {os.path.join(valid_directory, "pictures", file)}')
                    else:
                        print(
                            f'Failed to move file: {os.path.join(root, "pictures", file)}')
        if len(video_dictionary) >= 1:
            for file, root in video_dictionary.items():
                if shutil.move((os.path.join(root, file)), (os.path.join(valid_directory, "videos", file))):
                    if os.path.exists(os.path.join(valid_directory, "videos", file)):
                        print(
                            f'Successfully moved file: {os.path.join(valid_directory, "videos", file)}')
                    else:
                        print(
                            f'Failed to move file: {os.path.join(root, "videos", file)}')


def remove_empty_folders(valid_directory_set):
    for valid_directory in valid_directory_set:
        for root, subdirectories, files in os.walk(valid_directory, topdown=False):
            for subdirectory in subdirectories:
                try:
                    os.rmdir(os.path.realpath(
                        os.path.join(root, subdirectory)))
                except OSError:
                    pass


def terminate():
    print('Exiting script.')
    sys.exit()


if __name__ == '__main__':
    main()
