import pysmsg

xdr = b"9001 55554 abcd00000 \n"
status, r = pysmsg.decode_smsg(xdr)
print(status, r)

d = pysmsg.encode_smsg(r)
print(d)


