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
        void reset()

    cdef cppclass SMSGEncoder:
        void add_tag(const SMSGTag &tag, bool variable_len) except +
        void set_add_newline(bool add)
        void set_add_null_tag(bool add)
        void reset()
        const string& finalize()

# Decode class wrappers. We keep all C++ instances around as class members.
# Even though they're stateless, this helps us avoiding allocations.

cdef class Decoder:
    cdef SMSGIter it
    cdef SMSGTag tag
    cdef string xdr

    def decode(self, data: bytes) -> dict:

        record = {}
        tags = OrderedDict()
        record["tags"] = tags

        self.xdr = data

        self.it.reset()

        if not self.it.get_next_tag(self.xdr, self.tag, True):
            raise Exception("Could not decode initial tag")

        record["type"] = self.tag.tag
        if not self.tag.value.empty():
            record["type_value"] = self.tag.value.decode("UTF-8", "backslashreplace")

        while self.it.get_next_tag(self.xdr, self.tag):
            if self.tag.tag == 0: # termination tag
                break
            tags[self.tag.tag] = self.tag.value.decode("UTF-8", "backslashreplace")

        return record


cdef class Encoder:
    cdef SMSGEncoder encoder
    cdef SMSGTag tag

    cdef reset(self):
        self.encoder.reset()
        self.tag.value.resize(0)

    def add_null_tag(self, add : bool) -> Encoder:
        self.encoder.set_add_null_tag(add)
        return self

    def add_newline(self, add : bool) -> Encoder:
        self.encoder.set_add_newline(add)
        return self

    def encode(self, msg: dict) -> bytes:
        cdef int type = msg["type"]

        self.tag.tag = type
        self.tag.ctor = True
        self.reset()

        # Record type
        self.encoder.add_tag(self.tag, True)

        # tags
        for k, v in msg["tags"].items():
            self.tag.tag = k
            self.tag.value = bytes(str(v), "UTF-8")
            self.tag.ctor = (self.tag.tag & 0x8000) != 0
            self.encoder.add_tag(self.tag, False)


        return self.encoder.finalize()

def decode_smsg(data: bytes) -> dict:
    return Decoder().decode(data)

def encode_smsg(msg: dict, *, add_null_tag : bool = True, add_newline : bool = True) -> bytes:

    encoder = Encoder()
    encoder.add_null_tag(add_null_tag)
    encoder.add_newline(add_newline)

    return encoder.encode(msg)
