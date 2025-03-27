cmake_minimum_required(VERSION 3.15)
project(mainCppProject LANGUAGES CXX)

# Set the C++ standard to C++20
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# # ----- include dir (manually) -----
# include_directories(
#     ${CMAKE_SOURCE_DIR}/lib/string_utils
# )
# # ===== include dir (manually) =====

# # ----- include dir (auto collect) -----
# Recursively find .h, .hpp files
file(GLOB_RECURSE HEADER_FILES
    # all .h, .hpp files
    ${CMAKE_SOURCE_DIR}/lib/*.h
    ${CMAKE_SOURCE_DIR}/lib/*.hpp
    ## or detail pattern matching
    # ${CMAKE_SOURCE_DIR}/lib/*/include/*.h
    # ${CMAKE_SOURCE_DIR}/lib/*/include/*.hpp
    # ${CMAKE_SOURCE_DIR}/lib/*/inc/*.h
    # ${CMAKE_SOURCE_DIR}/lib/*/inc/*.hpp
)
# Extract only the directories of each .h file
set(INCLUDE_DIRS "")
foreach(header ${HEADER_FILES})
    get_filename_component(dir ${header} DIRECTORY)
    list(APPEND INCLUDE_DIRS ${dir})
endforeach()
# Remove duplicates
list(REMOVE_DUPLICATES INCLUDE_DIRS)
# Register in include_directories
include_directories(${INCLUDE_DIRS})
# # ===== include dir (auto collect) =====

# Automatically collect source files
file(GLOB_RECURSE SOURCES
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/lib/**/*.cpp
)

add_executable(main ${SOURCES})

# Set output directory
set_target_properties(main PROPERTIES
    # RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/build
    RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${CMAKE_SOURCE_DIR}/build/debug
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_SOURCE_DIR}/build/release
)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    execute_process(COMMAND uname -m OUTPUT_VARIABLE ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(ARCH STREQUAL "aarch64")
        set(CMAKE_STRIP "aarch64-linux-gnu-strip")
    else()
        set(CMAKE_STRIP "strip")
    endif()

    add_custom_command(TARGET main POST_BUILD
        COMMAND ${CMAKE_STRIP} $<TARGET_FILE:main>
        COMMENT "🔧 Stripping binary for ${ARCH}"
    )
endif()