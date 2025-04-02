#include "random_utils_c.h"
#include "random_utils.h"

static std::string __rand_str_result;

int random_utils_random_int(int min, int max)
{
    return random_int(min, max);
}

const char *random_utils_random_string(int length)
{
    __rand_str_result = random_string(static_cast<size_t>(length));
    return __rand_str_result.c_str();
}
