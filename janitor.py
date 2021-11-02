from pymongo import MongoClient
from random import randint

import sys

client = MongoClient(sys.argv[1])
print("Connection successful")

client.drop_database('ycsb')

print('finished droping database')
