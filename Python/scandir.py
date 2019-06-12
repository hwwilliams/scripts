import os
import sys
import collections


def main():
    valid_directory = checkPath('Which path? ')
    audioBooks = countBook(valid_directory)
    getBookName(audioBooks)
    terminate()


def terminate():
    print('Exiting script.')
    sys.exit()


def checkPath(directory_path_prompt):
    while True:
        input_directory = input(directory_path_prompt)
        if input_directory.lower() == 'exit':
            terminate()
        if (input_directory.strip()).startswith('.\\'):
            input_directory = (input_directory.strip()).replace('.\\', '', 1)
        input_directory = os.path.join((os.getcwd()), input_directory)
        if os.path.isdir(input_directory):
            valid_directory = input_directory
            return valid_directory
        else:
            print('Invalid Path: Please enter a valid directory path.')
            continue


def countBook(valid_directory):
    audioBooks = collections.OrderedDict()
    for book in os.scandir(valid_directory):
        if not book.name.startswith('.') and book.is_dir():
            audioBooks[book.name] = valid_directory
    if len(audioBooks) == 1:
        print(f'{len(audioBooks)} book found.')
    elif len(audioBooks) > 1:
        print(f'{len(audioBooks)} books found.')
    elif len(audioBooks) == 0:
        print('No books were found.')
    # print(list(books))
    return audioBooks


def getBookName(audioBooks):
    print('The following books were found:')
    for bookName, valid_directory in audioBooks.items():
        audioBookIndex = list(audioBooks.keys()).index(bookName)
        print(f'{audioBookIndex}. {bookName}')
    wrongBookName = input(
        'If any of the book names are wrong, enter their number. ')
    print(list(audioBooks)[int(wrongBookName)])


if __name__ == '__main__':
    main()
