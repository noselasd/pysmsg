import pysmsg

smsg_xdr = b"9001 55554 abcd00000 \n"
xdr = pysmsg.decode_smsg(smsg_xdr)
print("Decoded", xdr)

smsg_encoded =  pysmsg.encode_smsg(xdr)
print("Encoded ", smsg_encoded)
print("Original", smsg_xdr)


