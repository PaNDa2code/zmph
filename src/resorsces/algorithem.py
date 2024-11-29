#!/usr/bin/python

# Author: PaNDa2Code
# Date: 2024-11-29
# Inspired by: [Steve Hanov] https://stevehanov.ca/blog/?id=119

import mmh3

class MinimalPerfectHash:
    def __init__(self, data: dict[str, int]):
        size = len(data)
        # Initialize buckets and tables
        buckets = [[] for _ in range(size)]

        self.intermediated_table = [None] * size
        self.values = [None] * size
        self.hash = lambda d, s : mmh3.hash(s, d, False)

        # Place keys into buckets
        for key in data.keys():
            buckets[self.hash(0, key) % size].append(key)
        # Sort buckets by size in descending order
        buckets.sort(key=len, reverse=True)

        # Process buckets with more than one key
        for bucket_index, bucket in enumerate(buckets):
            if len(bucket) <= 1: 
                break
            displacement = 1
            item = 0
            slots = []
            while item < len(bucket):
                slot = self.hash(displacement, bucket[item]) % size
                if self.values[slot] is not None or slot in slots:
                    displacement += 1
                    item = 0
                    slots = []
                else:
                    slots.append(slot)
                    item += 1

            self.intermediated_table[self.hash(0, bucket[0]) % size] = displacement

            for i in range(len(bucket)):
                self.values[slots[i]] = data[bucket[i]]

        # Handle buckets with a single item
        free_slots = [i for i, value in enumerate(self.values) if value is None]

        for bucket in buckets[bucket_index:]:
            if len(bucket) == 0:
                continue
            slot = free_slots.pop()
            self.intermediated_table[self.hash(0, bucket[0]) % size] = -slot - 1
            self.values[slot] = data[bucket[0]]

    def PerfectLookup(self, key):
        displacement = self.intermediated_table[self.hash(0, key) % len(self.intermediated_table)]
        if displacement < 0: return self.values[-displacement-1]
        return self.values[self.hash(displacement, key) % len(self.values)]

if __name__ == "__main__":
    data = {}
    with open("/usr/share/dict/words", "r") as file:
        for line, word in enumerate(file.readlines()):
            data[word.strip()] = line

    mph = MinimalPerfectHash(data)

    for key in data.keys():
        expicted_value = data[key]
        lookup_value = mph.PerfectLookup(key)
        # print(f"{key}:{lookup_value}")
        if expicted_value != lookup_value:
            print("mismatch lookup\n")
            exit(1)
