# minNum.py
# =========
#
# by Joshua Chubb
#
# A script to find the smallest number in a list

# initialise the list
myList = [1,5,24,9,31]

# initialise our minNum to the first element in the list
minNum = myList[0]

# logic, we use a for loop as it will iterate through an array
# doing our comparison number < minNum and assignment for each
# element of the array.
for number in myList:
    if number < minNum:
        minNum = number

print ("The smallest number in the list was: {}".format(minNum))
