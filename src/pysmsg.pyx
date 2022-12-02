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

    cdef cppclass SMSGIter:
        SMSGIter() except +
        bool get_next_tag(string&, SMSGTag &t, bool mask_tag = false) except +
        reset()

    cdef cppclass SMSGEncoder:
        void add_tag(const SMSGTag &tag, bool variable_len) except +
        const string& finalize(bool add_newline)


def decode_smsg(data: bytes) -> dict:
    """ Decode an SMSG record.
        Args:
            data: A serialized byte array of the SMSG
                  (May optionally end with newline)
        Returns: dict with the keys:
            "type": maps to an int value of the
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
                                 The special tag 0 indicates end of record, tag 0 is not preserved in the returned 'tags' dict

        Raises: Exceptions on decoding errors

    """
    cdef SMSGIter it
    cdef SMSGTag tag

    record = {}
    tags = OrderedDict()
    record["tags"] = tags

    cdef string xdr = data # This copy should be avoided.


    if not it.get_next_tag(xdr, tag):
        raise Exception("Could not decode initial tag")

    record["type"] = tag.tag
    if not tag.value.empty():
        record["type_value"] = tag.value.decode("UTF-8", "backslashreplace")

    while it.get_next_tag(xdr, tag):
        if tag.tag == 0: # termination tag
            break
        tags[tag.tag] = tag.value.decode("UTF-8", "backslashreplace")

    return record

def encode_smsg(msg: dict) -> bytes:
    """ Encodes an SMSG record.
        Args:
            data: a dict with the keys:
                "type": key maps to an int value of the
                        record type key.
                "type_value": Present if If the first tag is a constructed
                            type with a length, the "type_value" key maps
                            to a str of its value
                "tags": dict of int->str mapping for SMSG tags->values.
        Returns: THe encoded SMSG as a byte string

    """


    cdef int type = msg["type"]
    cdef SMSGEncoder encoder
    cdef SMSGTag tag

    tag.tag = type
    tag.ctor = True
    # Record type
    encoder.add_tag(tag, True)

    # tags
    for k, v in msg["tags"].items():
        tag.tag = k
        tag.value = bytes(str(v), "UTF-8")
        tag.ctor = (tag.tag & 0x8000) != 0
        encoder.add_tag(tag, False)


    return encoder.finalize(True)
