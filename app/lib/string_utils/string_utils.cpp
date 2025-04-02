#include "string_utils.h"
#include <cctype>

// remove leading and trailing whitespace from a string
std::string trim(const std::string& str) {
    size_t first = str.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return ""; // 모두 공백일 경우
    size_t last = str.find_last_not_of(" \t\r\n");
    return str.substr(first, last - first + 1);
}

// check if string is empty or contains only whitespace
bool isBlank(const std::string& str) {
    for (char c : str) {
        if (!std::isspace(static_cast<unsigned char>(c))) return false;
    }
    return true;
}
