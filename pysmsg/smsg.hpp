#include <string>
#include <cstdint>

// We don't support values larger than 10MiB
const int MAX_VALUE_LEN = 1024 * 1024 * 10;
// Cython can't do C++ constructors with arguments,
// in a sane way, so these classes and apis are a bit
// awkward

enum SMSGResult {
    SMSG_OK             = 0,
    SMSG_EOF            = -1,
    SMSG_TOO_SHORT      = 1,
    SMSG_INVALID_LEN    = 2,
    SMSG_NO_CTOR        = 3,
};

/**  Represents a tag/value of an SMAN message */
struct SMSGTag {
    uint16_t tag;            // tag
    bool ctor;
    std::string value;       // value content
    size_t offset;           // start of tag within original data
};

/**
 * Iterator for tag/value pairs in an SMAN message
*/
class SMSGIter {
private:
    size_t offset = 0;
public:

   /**
    * Get the next tag from the passed in data buffer.
    * data must be the same buffer each time.
    *
    * @param data buffer to parse from
    * @param t output of parsed tag/value
    * @param mask_tag whether to remove the top bit of the tag
    *                 that indicates a constructor
    * @return true if tag was extracted, false otherwise
    * @exception std::exception subclasses on decoding errors
    */
    bool get_next_tag(const std::string &data, struct SMSGTag &t, bool mask_tag = false) noexcept(false);

    /**
     * Reset the iterator to start from the beginning.
     */
    void reset()
    {
        offset = 0;
    }
};

class SMSGEncoder {
private:
    std::string buffer;
    bool add_null_tag = true;
    bool add_newline = true;
public:

    void add_tag(const SMSGTag &tag, bool variable_len = false);

    void reset()
    {
        buffer = std::string();
    }

    // * @param add If the null tag terminator should be added at the end of the message
    void set_add_null_tag(bool add)
    {
        add_null_tag = add;
    }

    //* @param add If a \n should be added at the en of the message
    void set_add_newline(bool add)
    {
        add_newline = add;
    }


    /**
     * Finalizes the encoding, adding a 0 terminator tag and an optional newline

     * @return string& containing the encoded message. Any operation on the
     *         SMSGEncoder will invalidate this reference.
    */
    const std::string& finalize();
};
