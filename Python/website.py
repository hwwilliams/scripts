import urllib.request
import json

contents = urllib.request.urlopen(
    "https://www.vuemastery.com/courses/intro-to-vue-js/vue-instance/").read()

with open(contents) as f:
    json.load(read_file)
