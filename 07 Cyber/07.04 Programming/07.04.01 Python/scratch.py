import random

i = 0

while i == 0:
    random_number = random.randint(1,10)
    i = random_number % 2
    print("Random Number: ", random_number)
