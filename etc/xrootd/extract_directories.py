from __future__ import print_function
import re

match = re.compile(r'(\/xrootd\/[a-zA-z0-9|\/]+)\s.*')

with open('Authfile') as f:
    content = f.read()

results = match.findall(content)

for result in sorted(results):
    print(result)
