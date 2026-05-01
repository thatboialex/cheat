cmake_minimum_required(VERSION 3.20)

if(DEFINED CMAKE_CROSSCOMPILING)
    set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
    return()
endif()

if(NOT DEFINED PS5_PAYLOAD_SDK OR PS5_PAYLOAD_SDK STREQUAL "")
    set(PS5_PAYLOAD_SDK "$ENV{PS5_PAYLOAD_SDK}")
endif()

if(NOT PS5_PAYLOAD_SDK)
    message(FATAL_ERROR "PS5_PAYLOAD_SDK is required. Set it or pass -DPS5_PAYLOAD_SDK=/path/to/sdk.")
endif()

file(TO_CMAKE_PATH "${PS5_PAYLOAD_SDK}" PS5_PAYLOAD_SDK)
if(NOT EXISTS "${PS5_PAYLOAD_SDK}")
    message(FATAL_ERROR "PS5_PAYLOAD_SDK does not exist: ${PS5_PAYLOAD_SDK}")
endif()

set(CMAKE_SYSTEM_NAME FreeBSD)
set(CMAKE_SYSTEM_VERSION 12)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(PS5 1)

# SDK exposes two documented cross targets in existing project flags; keep repo default.
set(TOOLCHAIN_TRIPLE x86_64-pc-freebsd12-elf)

set(CMAKE_ASM_COMPILER clang)
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER_TARGET ${TOOLCHAIN_TRIPLE})
set(CMAKE_C_COMPILER_TARGET ${TOOLCHAIN_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${TOOLCHAIN_TRIPLE})

# Resolve SDK sysroot/include roots. Prefer real sysroot over local stubber tree.
set(_sdk_sysroot_candidates
    "${PS5_PAYLOAD_SDK}/sysroot"
    "${PS5_PAYLOAD_SDK}/target"
    "${PS5_PAYLOAD_SDK}/prospero"
)

set(PS5_SDK_SYSROOT "")
foreach(_candidate IN LISTS _sdk_sysroot_candidates)
    if(EXISTS "${_candidate}/usr/include/string.h" OR EXISTS "${_candidate}/include/string.h")
        set(PS5_SDK_SYSROOT "${_candidate}")
        break()
    endif()
endforeach()

if(PS5_SDK_SYSROOT)
    set(CMAKE_SYSROOT "${PS5_SDK_SYSROOT}")
else()
    message(WARNING "No SDK sysroot candidate with libc headers found under ${PS5_PAYLOAD_SDK}; falling back to compiler-managed includes.")
endif()

set(CMAKE_ASM_FLAGS_INIT "-fno-exceptions")
set(CMAKE_C_FLAGS_INIT "-fno-exceptions")
set(CMAKE_CXX_FLAGS_INIT "-fno-exceptions")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../linker.x")
set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld -fPIC -nodefaultlibs")
add_link_options("LINKER:-T,${LINKER_SCRIPT}")
set(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld -nostdlib")
add_link_options("LINKER:SHELL:-shared --build-id=none -zmax-page-size=16384 -zcommon-page-size=16384 --hash-style=sysv")

set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(CMAKE_C_LINKER_WRAPPER_FLAG "-Xlinker" " ")

# CMake find behavior should stay inside target SDK roots.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

message(STATUS "PS5_PAYLOAD_SDK=${PS5_PAYLOAD_SDK}")
message(STATUS "CMAKE_SYSROOT=${CMAKE_SYSROOT}")
