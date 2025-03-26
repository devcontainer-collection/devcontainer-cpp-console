cmake_minimum_required(VERSION 3.15)
project(MyConsoleApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# # ----- include dir (manually) -----
# include_directories(
#     ${CMAKE_SOURCE_DIR}/lib/string_utils
# )
# # ===== include dir (manually) =====

# ----- include dir (auto collect) -----
file(GLOB_RECURSE CANDIDATE_INCLUDE_DIRS
    ${CMAKE_SOURCE_DIR}/lib/*/include
    ${CMAKE_SOURCE_DIR}/lib/*/inc
    ${CMAKE_SOURCE_DIR}/lib/*/src/inc
)
foreach(path ${CANDIDATE_INCLUDE_DIRS})
    if(IS_DIRECTORY ${path})
        include_directories(${path})
    endif()
endforeach()
# ===== include dir (auto collect) =====

# 자동 소스 수집
file(GLOB_RECURSE SOURCES
    ${CMAKE_SOURCE_DIR}/src/*.cpp
    ${CMAKE_SOURCE_DIR}/lib/**/*.cpp
)

add_executable(main ${SOURCES})

# 출력 디렉토리 설정
set_target_properties(main PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/build
)
