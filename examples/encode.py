import pysmsg

msg = {
    'type': 0x1001,
          'tags': {
             0x1020: '20010101 111213',
             0x5555: 'abcd',
         }
}


print(pysmsg.encode_smsg(msg))
