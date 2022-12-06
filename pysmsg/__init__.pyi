""" API for encoding/decoding UTEL SMSG format"""

# This file contains type definitions for the pysmsg package
# The actual code is written in Cython and C++

class Decoder:
    """ Decoder for SMSG format"""

    def decode(self, data: bytes) -> dict:
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

            Raises: Exceptions on decoding errors"""
        pass



class Encoder:
    """ Encoder for SMSG format"""
    def add_null_tag(self, add : bool) -> Encoder:
        """ If a null tag should be added at the end of the message.
            Default is True.
        """
        pass
    def add_newline(self, add : bool) -> Encoder:
        """ If a newline should be added at the end of the message.
            Default is True."""
        pass

    def encode(self, msg: dict) -> bytes:
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

        Raises: Exceptions on decoding errors"""
        pass

def decode_smsg(data: bytes) -> dict:
    """ Decode an SMSG record. Decoder().decode(..)
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

        Raises: Exceptions on decoding errors"""

    pass



def encode_smsg(msg: dict, add_null_tag : bool = True, *, add_newline : bool = True) -> bytes:
    """ Encodes an SMSG record. Convenience wrapper for Encoder().encode(..)
        Args:
            data: a dict with the keys:
                "type": key maps to an int value of the
                        record type key.
                "type_value": Present if If the first tag is a constructed
                            type with a length, the "type_value" key maps
                            to a str of its value
                "tags": dict of int->str mapping for SMSG tags->values.
            add_null_tag: If the null terminator tag should be added after all other tags
            add_newline:  if a newline should be added after all tags. Newline is the standard
                          message separator for SMSGs
        Returns: Encoded SMSG as a byte string

    """
    pass
