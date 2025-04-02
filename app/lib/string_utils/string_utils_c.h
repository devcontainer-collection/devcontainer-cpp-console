#pragma once

#ifdef __cplusplus
extern "C"
{
#endif

    // trim: remove leading and trailing whitespace from a string
    const char *string_utils_trim(const char *input);

    // check if a string is blank (empty or contains only whitespace)
    bool string_utils_is_blank(const char *input);

#ifdef __cplusplus
}
#endif
