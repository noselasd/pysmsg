#include "smsg.hpp"
#include <charconv>
#include <cstdio>
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

SMSGResult SMSGIter::get_next_tag(const std::string &data, struct SMSGTag &t, bool mask_tag)
{
    if (data.length() < offset +  5) { // at least one tag + 1 length digit or a ' '
        if (data.length() == offset) {
            return SMSG_EOF;
        }
        return SMSG_TOO_SHORT;
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
        t.value = std::string_view(&data[offset], 0);
    } else {
        auto rc = std::from_chars(&data[offset], data.data() + data.size(), len);
        if (rc.ec != std::errc() || len > MAX_VALUE_LEN) {
            return SMSG_INVALID_LEN;
        }

        offset += rc.ptr - &data[offset] + 1; //skip past length of length + separator
        if (len < 0 || offset + size_t(len) > data.size()) {
            return SMSG_TOO_SHORT;
        }

        t.value = std::string_view(&data[offset], len);
        offset += len;
    }

    t.tag = tag;
    t.ctor = ctor;
    t.offset = start;

    return SMSG_OK;
}



SMSGResult SMSGSerializer::add_tag(const SMSGTag &tag, bool variable_len)
{

    if (tag.value.size() > MAX_VALUE_LEN) {
        return SMSG_INVALID_LEN;
    }
    // tag
    snprintf(scratch_buffer, sizeof scratch_buffer, "%04X", ((tag.ctor << 15) | tag.tag) & 0xffff);

    buffer.append(scratch_buffer);

    // length
    if (!variable_len) {
        snprintf(scratch_buffer, sizeof scratch_buffer, "%zu", tag.value.length());
        buffer.append(scratch_buffer);
    }

    buffer.push_back(' ');

    // value
    buffer.append(tag.value);

    return SMSG_OK;
}

const std::string& SMSGSerializer::finalize(bool add_newline)
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
