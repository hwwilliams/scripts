import eyed3
import os
import sys


def main():
    search_directory_set = check_path(
        'Which directory would you like to search? ')
    path_walked = walk_the_path(search_directory_set)
    series_title = get_series_title('What is the name of the book? ')
    proper_series_title = capitalize_title(series_title)
    set_tags(path_walked, proper_series_title)
    set_files(path_walked, proper_series_title)
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


def terminate():
    print('Exiting script.')
    sys.exit()


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
            if ask('Add another directory to search (y/N)? ', True):
                continue
            else:
                return search_directory_set
        else:
            print('Invalid Path: Please enter a valid directory path.')
            continue


def walk_the_path(valid_directory_set):
    path_walked = {}
    extension_list = ['mp3']
    for valid_dir in valid_directory_set:
        for root, subdirs, files in os.walk(valid_dir):
            for file in files:
                if file.endswith(tuple(extension_list)):
                    path_walked[file] = root
    if len(path_walked) == 0:
        print('No files found.')
        terminate()
    elif len(path_walked) >= 1:
        return path_walked


def get_series_title(series_title_prompt):
    series_title = input(series_title_prompt)
    series_title = series_title.strip().replace('  ', ' ')
    return series_title


def capitalize_title(series_title):
    ignore = {'a', 'an', 'and', 'as', 'at', 'but', 'by',
              'down', 'for', 'from', 'if', 'in', 'into',
              'like', 'near', 'nor', 'of', 'off', 'on',
              'once', 'onto', 'or', 'over', 'past', 'so',
              'than', 'that', 'the', 'till', 'to', 'upon',
              'v', 'v.', 'vs', 'vs.', 'when', 'with', 'yet'}
    proper_series_title = ''
    for word in series_title.split(' '):
        if word.lower() in ignore:
            if word == series_title.split(' ')[0] or word == series_title.split(' ')[-1]:
                if not word.isupper():
                    if not word.endswith('s') & (word.replace('s', '')).isupper():
                        word = word.capitalize()
            else:
                word = word.lower()
        elif not word.isupper():
            if not word.endswith('s') & (word.replace('s', '')).isupper():
                if not (word.lower()).startswith('ipv'):
                    word = word.capitalize()
        proper_series_title += str(f'{word} ')
    return proper_series_title


def set_tags(path_walked_dictionary, proper_series_title):
    for file, root in path_walked_dictionary.items():
        audioFile = eyed3.load(os.path.join(root, file))
        tag = audioFile.tag
        tag.album_artist = tag.artist
        tag.album = proper_series_title
        track_num = '{0:0=2d}'.format(tag.track_num[0])
        tag.title = (f'Chapter {track_num}')
        tag.save()


def set_files(path_walked_dictionary, proper_series_title):
    proper_series_title = proper_series_title.replace(': ', ' - ')
    for file, root in path_walked_dictionary.items():
        file_extension = file.split('.')[-1]
        audioFile = eyed3.load(os.path.join(root, file))
        tag = audioFile.tag
        track_num = '{0:0=2d}'.format(tag.track_num[0])
        if isinstance(tag.disc_num[0], int):
            disc_num = '{0:0=2d}'.format(tag.disc_num[0])
            final_title = (
                f'{proper_series_title} Disc {disc_num} Chapter {track_num}')
        else:
            final_title = (f'{proper_series_title} Chapter {track_num}')
        final_title = final_title.strip().replace('  ', ' ')
        original_file = os.path.join(root, file)
        final_file = os.path.join(root, (f'{final_title}.{file_extension}'))
        os.rename(original_file, final_file)


if __name__ == '__main__':
    main()
