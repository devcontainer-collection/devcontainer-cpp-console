#include <iostream>
#include <string>
// #include "../lib/string_utils/string_utils.h"
// or
#include <string_utils.h>
// CMakeLists.txt will find the header files with patterns matching
// if you want to add more patterns or directories, you can add them in CMakeLists.txt

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
