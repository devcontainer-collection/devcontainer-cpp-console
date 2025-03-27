#include <iostream>
#include <string>

#include "../lib/string_utils/string_utils.h"
// or
// #include <string_utils.h>
//  The debug include pattern is in cmakefiles.txt, and the cross-build pattern is in build-scripts/build.sh.

int main()
{
    std::string name;

    while (isBlank(name))
    {
        std::cout << "Enter your name: ";
        std::getline(std::cin, name);
        name = trim(name);
    }

    std::cout << "Hello, " << name << "!" << std::endl;
    return 0;
}