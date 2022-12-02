import pysmsg

# Takes 3 seconds vs 30 seconds in python XDRParser
with open("/home/noselasd/dev/data/TnMaritime-raw-dcdr.2022.03.20.cdr", "rb") as f:
    while True:
        line = f.readline()
        if not line:
            break
        r = pysmsg.decode_smsg(line)
        #print(r)

