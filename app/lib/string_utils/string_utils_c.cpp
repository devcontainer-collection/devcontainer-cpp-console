#include "string_utils_c.h"
#include "string_utils.h"

#include <string>

// Static variable: buffer for return string (caution: may be unsafe in multi-threaded context)
static std::string __trim_result;

const char *string_utils_trim(const char *input)
{
    if (!input)
        return "";
    __trim_result = trim(std::string(input));
    return __trim_result.c_str();
}

bool string_utils_is_blank(const char *input)
{
    if (!input)
        return true;
    return isBlank(std::string(input));
}
