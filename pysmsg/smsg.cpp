#include "smsg.hpp"
#include <charconv>
#include <stdexcept>

#define UC_STRINGIFY(x) UC_STRINGIFY_HLP(x)
#define UC_STRINGIFY_HLP(x) #x

#define xbt2int(c)        ( (unsigned int) ((c)>'9')? (c)-'7' : (c)-'0' )
static unsigned int fourxbt2int(const char *x)
{
    unsigned int i0,i1,i2,i3;


    i0 = xbt2int(*(x+0));
    i1 = xbt2int(*(x+1));
    i2 = xbt2int(*(x+2));
    i3 = xbt2int(*(x+3));

   return ( (i0<<12) + (i1<<8) + (i2<<4) + i3 );
}


// Fast hex encoder for uint16_t, result have to be atleast 5 bytes and will be nul terminated
static void hex_encode(uint16_t val, char *result)
{
    static const char hex_chars[] = "0123456789ABCDEF";
    result[0] = hex_chars[(val >> 12) & 0x000f];
    result[1] = hex_chars[(val >> 8 ) & 0x000f];
    result[2] = hex_chars[(val >> 4 ) & 0x000f];
    result[3] = hex_chars[(val      ) & 0x000f];

    result[4] = 0;
}


bool SMSGIter::get_next_tag(const std::string &data, struct SMSGTag &t, bool mask_tag)
{
    if (data.length() < offset +  5) { // at least one tag + 1 length digit or a ' '
        if (data.length() == offset || data[offset] == '\n') {
            return false;
        }
        throw std::length_error("Message too short for decoding tag");
    }

    size_t start = offset;
    uint16_t tag = uint16_t(fourxbt2int(&data[offset]));
    bool ctor = false;
    int len;

    if (tag & 0x8000) {
        ctor = true;
        if (mask_tag) {
            tag &= 0x7fff;
        }
    }
    offset += 4;
    if (data[offset] == ' ') {
        len = -2;
        ++offset;
        t.value.resize(0);
    } else {
        auto rc = std::from_chars(&data[offset], data.data() + data.size(), len);
        if (rc.ec != std::errc() || len > MAX_VALUE_LEN) {
           throw std::length_error("Failed decoding tag length");
        }

        offset += rc.ptr - &data[offset] + 1; //skip past length of length + separator
        if (len < 0 || offset + size_t(len) > data.size()) {
            throw std::length_error("Tag length is larger than remaining data in the message");
        }

        t.value.assign(&data[offset], len);
        offset += len;
    }

    t.tag = tag;
    t.ctor = ctor;
    t.offset = start;

    return true;
}



void SMSGEncoder::add_tag(const SMSGTag &tag, bool variable_len)
{

    if (tag.value.size() > MAX_VALUE_LEN) {
        throw std::length_error("Value length is too large (>" UC_STRINGIFY(MAX_VALUE_LEN) ")");
    }
    char tmp[16];
    // tag
    hex_encode((tag.ctor << 15) | (tag.tag & 0xffff), tmp);

    buffer.append(tmp);

    // length
    if (!variable_len) {
        auto rc = std::to_chars(tmp, tmp + sizeof(tmp) - 1, tag.value.size());
        if (rc.ec != std::errc()) {
            throw std::runtime_error("Error converting tag length");
        }
        rc.ptr[0] = 0;

        buffer.append(tmp);
    }

    buffer.push_back(' ');

    // value
    buffer.append(tag.value);
}

const std::string& SMSGEncoder::finalize(bool add_newline)
{
    static const SMSGTag null_tag = {
        .tag = 0,
        .ctor = false,
        .offset = 0,
    };

    add_tag(null_tag);
    if (add_newline) {
        buffer.push_back('\n');
    }

    return buffer;
}
