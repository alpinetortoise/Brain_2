# minNum2.py
# ==========
#
# taken from lecture slides
#
# A broken implementation of minNum.py

myList = [1,0,24,9,31]
minSet = False
minNumber = 0
for number in myList:

# because we are doing an OR on our two initialisations when we get to
# element myList[2] we will set minNumber to 24, and then 9 at myList[3]
# we do have minSet which we can utilise, we would change the first line
# to the subsequent commented line, and add also add the second commented line
    if number < minNumber OR minNumber == 0:
#   if number < minNumber OR NOT minSet:
        minNumber = number
#       minSet = True

print("The minimum number in the list was: {}".format(minNumber))
