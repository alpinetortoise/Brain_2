import re

# Pull in the log file
input_file = open("access.log", "r")
fstring = input_file.readlines()

# Initialise our list and dictionary for traversal of the file
hits = []
field_count_dictionary = {}

# Regex for IP Addresses
pattern = re.compile(r'(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')

# Create a list of all the ip addresses, to be collated next
for line in fstring:
    hits.append(pattern.search(line)[0])

# Function for recording incrementing the dictionary
def record_entry(field_value):
    if not field_value in field_count_dictionary:
        field_count_dictionary[field_value] = 0
    field_count_dictionary[field_value] += 1

# Find the highest number of hits in the dictionary
def find_highest(dictionary):
    high = 0
    highKey = ""
    for record in dictionary:
        if dictionary[record] >= high:
            high = dictionary[record]
            highKey = record
    return highKey

# Function for sorting the dictionary from most hits to least
def dict_sort(dictionary):
    sorted_dict = {}
    while dictionary != {}:
        highest = find_highest(dictionary)
        sorted_dict[highest] = dictionary[highest]
        dictionary.pop(highest)
    return sorted_dict

# Move the list into the dictionary
for ip in hits:
    record_entry(ip)

# Sort the dictionary
field_count_dictionary = dict_sort(field_count_dictionary)

output_file = open("hits.csv", "a")
output_file.write("IP Address,Hits\n")
for ip in field_count_dictionary:
    output_file.write("{},{}\n".format(ip,field_count_dictionary[ip]))

# TODO: add gz decompression
