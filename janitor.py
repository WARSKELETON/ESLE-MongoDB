from pymongo import MongoClient
from random import randint

client = MongoClient('mongodb://mongo1:30001,mongo2:30002,mongo3:30003/db?replicaSet=my-replica-set')
print("Connection successful")

client.drop_database('ycsb')

print('finished droping database')
