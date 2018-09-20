import distutils.dir_util
import os
import shutil

# drive_path = (input('Path to drive: ')).strip()
# file_path = (input('Path to movie list: ')).strip()
# movie_path = (input('Path to movies: ')).strip()

drive_path = ('E:\\').strip()
file_path = ("E:\\Movies.txt").strip()
movie_path = ('E:\\').strip()

for path in (drive_path, file_path, movie_path):
    if path.endswith("'"):
        file_path = file_path.replace("'", '')
    elif path.endswith('"'):
        file_path = file_path.replace('"', '')

movie_destination = os.path.join(drive_path, 'Movies')

movies_list = []
with open(file_path) as file:
    for line in enumerate(file):
        clean_line = ((line[-1]).strip('\n')).lower()
        if clean_line.endswith('collection'):
            clean_line = (clean_line.rsplit(' ', 1)[0]).strip()
        movies_list.append(clean_line)
file.close()

if not os.path.exists(movie_destination):
    os.makedirs(movie_destination)

for root, subdirs, files in os.walk(movie_path):
    for item in movies_list:
        if item in root.lower():
            distutils.dir_util.copy_tree(root, movie_destination)
            print(f'Found match for {item} as {root}')
