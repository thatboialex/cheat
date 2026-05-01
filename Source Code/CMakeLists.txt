cmake_minimum_required (VERSION 3.20)

project("etaHEN_cheats_only")

set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_ROOT}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_ROOT}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_ROOT}/lib)

if(NOT DEFINED PS5_PAYLOAD_SDK OR PS5_PAYLOAD_SDK STREQUAL "")
  set(PS5_PAYLOAD_SDK "$ENV{PS5_PAYLOAD_SDK}")
endif()

if(NOT PS5_PAYLOAD_SDK)
  message(FATAL_ERROR "PS5_PAYLOAD_SDK is required. Set PS5_PAYLOAD_SDK or pass -DPS5_PAYLOAD_SDK=/path/to/ps5-payload-sdk.")
endif()

file(TO_CMAKE_PATH "${PS5_PAYLOAD_SDK}" PS5_PAYLOAD_SDK)
if(NOT EXISTS "${PS5_PAYLOAD_SDK}")
  message(FATAL_ERROR "PS5_PAYLOAD_SDK does not exist: ${PS5_PAYLOAD_SDK}")
endif()

message(STATUS "PS5_PAYLOAD_SDK=${PS5_PAYLOAD_SDK}")
message(STATUS "CMAKE_SYSROOT=${CMAKE_SYSROOT}")
message(STATUS "CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}")

include_directories (SYSTEM "${PROJECT_ROOT}/include")

# The ps5-payload-sdk install layout puts every libc / FreeBSD / PS5 header
# under ${PS5_PAYLOAD_SDK}/target/include after `make DESTDIR=<sdk> install`.
if(EXISTS "${PS5_PAYLOAD_SDK}/target/include")
  include_directories(SYSTEM "${PS5_PAYLOAD_SDK}/target/include")
endif()
if(EXISTS "${PS5_PAYLOAD_SDK}/include")
  include_directories(SYSTEM "${PS5_PAYLOAD_SDK}/include")
endif()
if(EXISTS "${PS5_PAYLOAD_SDK}")
  include_directories(SYSTEM "${PS5_PAYLOAD_SDK}")
endif()

# Cheats-only build graph.
# Required order: NidResolver -> hijacker -> shellui/daemon.
add_subdirectory(libNidResolver)
add_subdirectory(libhijacker)
add_subdirectory(libNineS)
add_subdirectory(libelfldr)
add_subdirectory(libSelfDecryptor)
add_subdirectory(shellui)
add_subdirectory(daemon)
