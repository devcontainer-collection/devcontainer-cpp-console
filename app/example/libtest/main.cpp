#include <iostream>
#include "random_utils.h"

int main()
{
    int value = random_utils_random_int(1, 100);
    const char *str = random_utils_random_string(10);

    std::cout << "랜덤 정수: " << value << std::endl;
    std::cout << "랜덤 문자열: " << str << std::endl;

    return 0;
}
