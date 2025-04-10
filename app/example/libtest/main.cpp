#include <iostream>
#include "random_utils.h"

int main()
{
    int value = random_utils_random_int(1, 100);
    const char *str = random_utils_random_string(10);

    std::cout << "Random Int: " << value << std::endl;
    std::cout << "Random String: " << str << std::endl;

    return 0;
}
