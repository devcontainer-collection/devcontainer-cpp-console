#pragma once

#ifdef __cplusplus
extern "C"
{
#endif

    int random_utils_random_int(int min, int max);
    const char *random_utils_random_string(int length); // 반환값은 static

#ifdef __cplusplus
}
#endif
