import pysmsg

# Takes 3 seconds vs 30 seconds in python XDRParser
with open("/home/noselasd/dev/data/dcdr.2022.06.26.06-100000", "rb") as input_file:
    with open("/home/noselasd/dev/data/dcdr.2022.06.26.06-100000.pysmsg", "wb") as output_file:
        while True:
            line = input_file.readline()
            if not line:
                break
            r = pysmsg.decode_smsg(line)
            # Get SIP status tag if it exists:
            sip_status = r["tags"].get(0x1503)
            if sip_status is not None:
                # And replace it with sip status 999
                r["tags"][0x1503] = "999"

            # Encode the message and write it to file
            out = pysmsg.encode_smsg(r)
            output_file.write(out)

