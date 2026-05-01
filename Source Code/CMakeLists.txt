cmake_minimum_required (VERSION 3.20)

project("etaHEN_cheats_only")

set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_ROOT}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_ROOT}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_ROOT}/lib)

include_directories (SYSTEM "${PROJECT_ROOT}/include")
include_directories(SYSTEM "${PS5_PAYLOAD_SDK}")
include_directories(SYSTEM "${PS5_PAYLOAD_SDK}/include")

# Cheats-only build graph.
add_subdirectory(libhijacker)
add_subdirectory(libNineS)
add_subdirectory(libelfldr)
add_subdirectory(libSelfDecryptor)
add_subdirectory(shellui)
add_subdirectory(daemon)
