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
    * @return SMSGResult , SMSG_OK if all is ok
    */
    SMSGResult get_next_tag(const std::string &data, struct SMSGTag &t, bool mask_tag = false);

    /**
     * Reset the iterator to start from the beginning.
     */
    void reset()
    {
        offset = 0;
    }
};

class SMSGSerializer {
private:
    std::string buffer;
    char scratch_buffer[16];
public:
    SMSGResult add_tag(const SMSGTag &tag, bool variable_len = false);

    void reset()
    {
        buffer.resize(0);
    }

    const std::string& finalize(bool add_newline = true);
};
