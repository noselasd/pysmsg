from libcpp cimport bool
from libcpp.string cimport string
from libc.stdint cimport uint16_t
from collections import OrderedDict

cdef extern from "smsg.hpp":
    cdef cppclass SMSGTag:
        SMSGTag() except +
        uint16_t tag
        bool ctor
        string value # Copy here should be avoided (should be a string_view)
        size_t offset

    cdef cppclass SMSGIter nogil:
        SMSGIter() except +
        SMSGResult get_next_tag(string&, SMSGTag &t, bool mask_tag = false)
        reset()

    cdef cppclass SMSGSerializer:
        SMSGResult add_tag(const SMSGTag &tag, bool variable_len)
        const string& finalize(bool add_newline)

    cdef enum SMSGResult:
        SMSG_OK             = 0
        SMSG_EOF            = -1
        SMSG_TOO_SHORT      = 1
        SMSG_INVALID_LEN    = 2
        SMSG_NO_CTOR        = 3

def decode_smsg(data: bytes) -> (_, dict):
    """ Decode an SMSG record.
        Args:
            data: A serialized byte array of the SMSG
                  (May optionally end with newline)
        Returns:
            A (status, dict) pair.
            status : 0 = OK
                     1 = TOO_SHORT (Some may have been parsed, but indications are
                                   the message is not complete)
                     2 = INVALID_LEN A length field was invalid
                     3 = NO_CTOR The first tag was not a constructor

            dict is the record with the keys:
            "type": key maps to an int value of the
                    first tag, representing the record type.
            "type_value": Present if If the first tag is a constructed
                          type with a length, the "type_value" key maps
                          to a str of its value

            "tags": dict of int->str mapping for SMSG tags->values.
                    The highest bit of a tag is preserved, indicating a constructor.

            SMSG tags: tags is an uint16 type, valid tags can be in the range [0-32767].
                                 If the highest bit is set, tag & 0x8000 != 0, it indicates a constructor tag.
                                 To get the tag number, mask away the highest bit, tag &0x7fff.
                                 A constructor tag means it's value is made up of more tag/values.
                                 The special tag 0 indicates end of record, tag 0 is not preserved in the returned 'tags' dicr

    """
    cdef SMSGIter it
    cdef SMSGTag tag

    record = {}
    tags = OrderedDict()
    record["tags"] = tags

    cdef string xdr = data # This copy should be avoided.
    cdef SMSGResult rc = it.get_next_tag(xdr, tag)

    if rc != SMSG_OK:
        return (rc, record)

    if not tag.ctor:
        return (SMSG_NO_CTOR, record)

    record["type"] = tag.tag
    if not tag.value.empty():
        record["type_value"] = tag.value.decode("UTF-8", "backslashreplace")

    while rc == SMSG_OK:
        rc =  it.get_next_tag(xdr, tag)
        if rc != SMSG_OK:
            break
        if tag.tag == 0: # termination tag
            break
        tags[tag.tag] = tag.value.decode("UTF-8", "backslashreplace")

    if rc == SMSG_EOF:
        rc = SMSG_OK # Treat end with no 0 tag as OK

    return (rc, record)

def encode_smsg(msg: dict) -> (_, bytes):
    """ Encodes an SMSG record.
        Args:
            data: a dict with the keys:
                "type": key maps to an int value of the
                        record type key.
                "type_value": Present if If the first tag is a constructed
                            type with a length, the "type_value" key maps
                            to a str of its value
        Returns:
            A (status, dict) pair.
            status : 0 = OK
                     Anything else than 0 indicates an error

            dict is the record with the keys:
            "type": key maps to an int value of the
                    first tag, representing the record type.

            "tags": dict of int->str mapping for SMSG tags->values

            e.g. pass in
                    msg = {
                         type': 0x1001,
                         'tags': {
                                0x1020: '20010101 111213',
                                0x5555: 'abcd',
                                }
                    }

                    encode_smsg(msg) returns b'9001 102015 20010101 11121355554 abcd00000 \n'
    """


    cdef int type = msg.get("type")
    cdef SMSGSerializer serializer
    cdef SMSGTag tag

    tag.tag = type
    tag.ctor = True
    # Record type
    serializer.add_tag(tag, True)

    # tags
    for k, v in msg["tags"].items():
        tag.tag = k
        tag.value = bytes(v, "UTF-8")
        tag.ctor = (tag.tag & 0x8000) != 0
        serializer.add_tag(tag, False)


    return (0, serializer.finalize(True))
