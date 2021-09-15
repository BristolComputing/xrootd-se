from __future__ import print_function
import re

match = re.compile(r'(\/xrootd\/[A-z|\/]+)\s.*')

with open('Authfile') as f:
    content = f.read()

results = match.findall(content)

for result in sorted(set(results)):
    print(result)
