#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

records = {}

with open(sys.argv[1]) as fp:
    for line in fp:
        token = line.split()
        name = token[1]
        if name not in records:
            records[name] = 0

        if token[0] == "enter":
            records[name] += 1
        elif token[0] == "exit":
            records[name] -= 1

for name, count in records.items():
    if count != 0:
        print(name + " -> " + str(count))
            
