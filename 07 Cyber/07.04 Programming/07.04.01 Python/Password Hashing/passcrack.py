import hashlib
import argparse

parser = argparse.ArgumentParser(description='Attempts to find the word, from the wordlist, whose hash matches the inputted hash.')
parser.add_argument('-s', '--hash', dest='hash')
parser.add_argument('-w', '--wordlist', dest='wordlist', default="./rockyou.txt")
parser.add_argument('-l', '--hashlist', dest='hashlist')
parser.add_argument('-e', '--encoding', dest='encode', default="md5")

args = parser.parse_args()

input_hash = args.hash
input_filename = args.wordlist
input_hashlist = args.hashlist
encoding = args.encode

wordlist = open(input_filename, "rb")
hashes = []
if input_hashlist:
    for line in open(input_hashlist):
        hashes.append(line.rstrip())
elif input_hash:
    hashes = [input_hash]
else:
    hashes = [input("Input target hash: ")]

def encode(word, encoder):
    if encoder == "md5":
        return hashlib.md5(word).hexdigest()
    elif encoder == "sha-256":
        return hashlib.sha256(word).hexdigest()

def find_hashes(wordlist, encoder):
    hashes = {}
    for word in wordlist:
        word = word.rstrip()
        hashed = encode(word, encoder)
        hashes.update({hashed:word})
    return hashes

hashed_list = find_hashes(wordlist, encoding)
for target in hashes:
    if target in hashed_list.keys():
        print("Password Found: ", hashed_list[target].decode())
    else:
        print("Password not Found: ", target)
