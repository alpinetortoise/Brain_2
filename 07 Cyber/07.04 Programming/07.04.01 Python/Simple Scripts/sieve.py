# sieve.py
# ========
#
# Found on the internet somewhere for finding the largest prime under 100

# Set the upper limit to be 100
MAX_PRIME = 100

# Initialise an array that contains True in all places up to MAX_PRIME
sieve = [True] * MAX_PRIME

# using a range function (returns an array that contains integers[1])
for i in range(2, MAX_PRIME):

# if sieve[i] is still True then print the number
  if sieve[i]:
    print(i)

# Then iterate through the rest of the list finding anything that has a
# factor of i
    for j in range(i*i, MAX_PRIME, i): # [2]
      sieve[j] = False

# [1] range(1, 10) will return the array [1,2,3,4,5,6,7,8,9,10]
#     more generally:
#     range(a, b) will return an array [a, a+1, a+2, ... b-1, b]
# [2] We can also add a third (optional) argument to our range call
#     This gives us a 'step' by which our range goes up.
#     ie. range(1, 10, 2) will return the array [1,3,5,7,9]
#     more generally:
#     range(a,b,c) will return an array [a, a+c, a+2c, ... b-c, b]
