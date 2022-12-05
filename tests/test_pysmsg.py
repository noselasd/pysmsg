import pysmsg
from collections import OrderedDict
import sys

def test_decode_basic():
    record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X00000 ")
    expected = {'type': 0x1001, 'tags': OrderedDict([(0x1000, 'ABCD'), (0x2000, 'X')])}
    assert record == expected

    # New line at end should be accepted
    record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X00000 \n")
    assert record == expected

    # Record ends at null terminator, anything else is ignored
    record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X00000 11111 x\n")
    assert record == expected

    # TODO: should we accept missing space after null tag ?
    #record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X00000")
    #assert record == expected

def test_decode_no_terminator():
    # Null tag at end is not neccesary as long as the message ends
    record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X")
    expected = {'type': 0x1001, 'tags': OrderedDict([(0x1000, 'ABCD'), (0x2000, 'X')])}
    assert record == expected

    # New line at end should be accepted
    record = pysmsg.decode_smsg(b"9001 10004 ABCD20001 X\n")
    assert record == expected


def test_decode_unicode():
    # UTF-8 encoded, 😀 is 4 bytes æø is 4 bytes
    record = pysmsg.decode_smsg(bytes("9001 100010 Hello 😀7FFF4 æå00000 ", "UTF-8"))
    expected = {'type': 0x1001, 'tags': OrderedDict([(0x1000, 'Hello 😀'), (0x7fff, 'æå')])}
    assert record == expected

def test_decode_constructor_with_length():
    # If constructed type has a length, type_value contains its content. This
    # content is more tag/value pairs
    record = pysmsg.decode_smsg(bytes("90019 55553 12300000 ", "UTF-8"))
    expected = {'type': 0x1001, 'type_value': '55553 123', 'tags': OrderedDict()}
    assert record == expected



def test_encode_basic():
    record = {'type': 0x1001, 'tags': OrderedDict([(0x1000, 'Hello 😀'), (0x7fff, 'æå')])}
    expected = bytes("9001 100010 Hello 😀7FFF4 æå00000 \n", "UTF-8")
    encoded = pysmsg.encode_smsg(record)
    assert encoded == expected
