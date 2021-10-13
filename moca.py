import time
import concurrent.futures
import logging
import sys
from pymongo import MongoClient
from random import randint

client = MongoClient(port=3000)
db = client.business

def thread_function(max_delay):
    counter = 0
    # Run for 30 seconds
    t_end = time.time() + max_delay
    while time.time() < t_end:
        mycol = db.reviews
        myquery = { "cuisine": "Italian" }

        mydoc = mycol.find(myquery)

        #for x in mydoc:
            #logging.info(x)
        counter += 1
    return counter

if __name__ == "__main__":
    format = "%(asctime)s: %(message)s"
    logging.basicConfig(format=format, level=logging.INFO,
                        datefmt="%H:%M:%S")

    if len(sys.argv) == 3:
        workers = int(sys.argv[1])
        max_delay = int(sys.argv[2])

        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
            future = executor.submit(thread_function, max_delay)
            total_ops = future.result()
            print(f'Total Operations = {total_ops}')
            print(f'Operations/sec = {total_ops / max_delay}')
        
    else:
        print("Usage: python moca.py {workers} {max_delay_seconds}")
