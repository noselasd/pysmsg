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
        bool get_next_tag(string&, SMSGTag &t) except +
        bool get_next_tag(string&, SMSGTag &t, bool masktag) except +
        reset()

    cdef cppclass SMSGEncoder:
        void add_tag(const SMSGTag &tag, bool variable_len) except +
        void set_add_newline(bool add)
        void set_add_null_tag(bool add)
        const string& finalize()


def decode_smsg(data: bytes) -> dict:
    cdef SMSGIter it
    cdef SMSGTag tag

    record = {}
    tags = OrderedDict()
    record["tags"] = tags

    cdef string xdr = data


    if not it.get_next_tag(xdr, tag, True):
        raise Exception("Could not decode initial tag")

    record["type"] = tag.tag
    if not tag.value.empty():
        record["type_value"] = tag.value.decode("UTF-8", "backslashreplace")

    while it.get_next_tag(xdr, tag):
        if tag.tag == 0: # termination tag
            break
        tags[tag.tag] = tag.value.decode("UTF-8", "backslashreplace")

    return record

def encode_smsg(msg: dict, *, add_null_tag : bool = True, add_newline : bool = True) -> bytes:

    cdef int type = msg["type"]
    cdef SMSGEncoder encoder
    cdef SMSGTag tag
    encoder.set_add_null_tag(add_null_tag)
    encoder.set_add_newline(add_newline)

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


    return encoder.finalize()
