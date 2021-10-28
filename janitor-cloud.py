from pymongo import MongoClient
from random import randint

client = MongoClient('mongodb://mongo-0.mongo:27017,mongo-1.mongo:27017,mongo-2.mongo:27017/db')
print("Connection successful")

client.drop_database('ycsb')

print('finished droping database')
