import os
import sys
from modules.filesystems import check, walk


validPath = check('What path to check? ')

files = walk(validPath)

for file in files:
    print(f'this is "{file}"')
