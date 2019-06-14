import os
import sys
import collections


def main():
    validDirectory = checkPath('Which path? ')
    audioBooks = countBook(validDirectory)
    indexBookName(audioBooks)
    bookIndexList = bookIndexPrompt('Enter the number for the book, separated by commas, else press enter to continue. ')
    if len(bookIndexList) > 0:
        bookNameIndex = checkBookName(audioBooks, bookIndexList)
    terminate()


def terminate():
    print('Exiting script.')
    sys.exit()


def checkPath(directoryPathPrompt):
    while True:
        inputDirectory = input(directoryPathPrompt)
        if inputDirectory.lower() == 'exit':
            terminate()
        if (inputDirectory.strip()).startswith('.\\'):
            inputDirectory = (inputDirectory.strip()).replace('.\\', '', 1)
        inputDirectory = os.path.join((os.getcwd()), inputDirectory)
        if os.path.isdir(inputDirectory):
            validDirectory = inputDirectory
            return validDirectory
        else:
            print('Invalid Path: Please enter a valid directory path.')
            continue


def countBook(validDirectory):
    audioBooks = collections.OrderedDict()
    for book in os.scandir(validDirectory):
        if not book.name.startswith('.') and book.is_dir():
            audioBooks[book.name] = validDirectory
    if len(audioBooks) == 1:
        print(f'{len(audioBooks)} book found.')
    elif len(audioBooks) > 1:
        print(f'{len(audioBooks)} books found.')
    elif len(audioBooks) == 0:
        print('No books were found.')
    return audioBooks


def indexBookName(audioBooks):
    print('List of found books:')
    for bookName, validDirectory in audioBooks.items():
        audioBookIndex = list(audioBooks.keys()).index(bookName)
        print(f'{audioBookIndex}. {bookName}')
    # print(list(audioBooks)[int(wrongBookIndex)])


def bookIndexPrompt(prompt):
    print('Check if any of the book names are wrong.')
    while True:
        bookIndexList = []
        wrongBookIndex = (input(prompt).strip())
        try:
            for bookIndex in wrongBookIndex.split(','):
                bookIndexList.append(int(bookIndex.replace(' ', '')))
        except ValueError:
            bookIndexList = []
            print('Skipping book name correction...')
        return bookIndexList


def checkBookName(audioBooks, bookIndexList):
    print(bookIndexList)
    bookNameIndex = {}
    for bookName, validDirectory in audioBooks.items():
        for bookIndex in bookIndexList:
            correctBookName = (input(f'What is the correct name for "{bookName}"? '))
            bookNameIndex[bookIndex] = correctBookName
            print(bookNameIndex)
    return bookNameIndex


if __name__ == '__main__':
    main()
