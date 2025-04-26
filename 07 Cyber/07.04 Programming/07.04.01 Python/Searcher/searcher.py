pathOf_fileToSearch = input("Input the path of the file we want to search: ")
stringToSearch = input("Input the substring we want to search for: ")

fileToSearch = open(pathOf_fileToSearch)

for line in fileToSearch:
    if stringToSearch in line:
        print(line.rstrip())
