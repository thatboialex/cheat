cmake_minimum_required(VERSION 3.20)

if(DEFINED CMAKE_CROSSCOMPILING AND CMAKE_CROSSCOMPILING)
    set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)
    return()
endif()

set(TOOLCHAIN_PATH "${CMAKE_CURRENT_LIST_DIR}")

# Resolve PS5_PAYLOAD_SDK from CMake var or environment.
if(NOT DEFINED PS5_PAYLOAD_SDK OR PS5_PAYLOAD_SDK STREQUAL "")
    set(PS5_PAYLOAD_SDK "$ENV{PS5_PAYLOAD_SDK}")
endif()

if(NOT PS5_PAYLOAD_SDK)
    message(FATAL_ERROR
        "PS5_PAYLOAD_SDK is required. Set the env var PS5_PAYLOAD_SDK or pass "
        "-DPS5_PAYLOAD_SDK=/path/to/ps5-payload-sdk to cmake.")
endif()

file(TO_CMAKE_PATH "${PS5_PAYLOAD_SDK}" PS5_PAYLOAD_SDK)

if(NOT EXISTS "${PS5_PAYLOAD_SDK}")
    message(FATAL_ERROR "PS5_PAYLOAD_SDK does not exist: ${PS5_PAYLOAD_SDK}")
endif()

# The ps5-payload-sdk install layout is:
#   ${PS5_PAYLOAD_SDK}/target/include    standard libc / FreeBSD / PS5 headers
#   ${PS5_PAYLOAD_SDK}/target/lib        libc.a, crt1.o, libSce*.so etc.
#   ${PS5_PAYLOAD_SDK}/bin               prospero-* host wrappers
# The SDK Makefile must have been run with `make DESTDIR=${PS5_PAYLOAD_SDK} install`
# (or the SDK release zip extracted) before configuring this project.
set(_PS5_TARGET_ROOT  "${PS5_PAYLOAD_SDK}/target")
set(_PS5_TARGET_INCLUDE "${_PS5_TARGET_ROOT}/include")
set(_PS5_TARGET_LIB     "${_PS5_TARGET_ROOT}/lib")

if(NOT EXISTS "${_PS5_TARGET_INCLUDE}/string.h")
    message(FATAL_ERROR
        "PS5 SDK target headers not found at ${_PS5_TARGET_INCLUDE}.\n"
        "Run `make DESTDIR=${PS5_PAYLOAD_SDK} install` inside the SDK checkout, "
        "or extract the SDK release zip into ${PS5_PAYLOAD_SDK}.")
endif()

set(CMAKE_SYSTEM_NAME       FreeBSD)
set(CMAKE_SYSTEM_VERSION    9)
set(CMAKE_SYSTEM_PROCESSOR  x86_64)
set(CMAKE_CROSSCOMPILING    1)

set(PS5 1)
set(PROSPERO 1)

# Use the installed SDK target tree as the sysroot so <string.h>, <stdlib.h>,
# <elf.h>, and the FreeBSD/PS5 system headers are discoverable via -isysroot.
set(CMAKE_SYSROOT "${_PS5_TARGET_ROOT}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_STANDARD_DEFAULT 17)
set(CMAKE_CXX_STANDARD_DEFAULT 20)

# The cheats-only sources compile with the PS5 (Sony) clang triple.
set(TOOLCHAIN_TRIPLE x86_64-sie-ps5)

set(CMAKE_ASM_COMPILER clang)
set(CMAKE_ASM_COMPILER_TARGET ${TOOLCHAIN_TRIPLE})
set(CMAKE_C_COMPILER   clang)
set(CMAKE_C_COMPILER_TARGET   ${TOOLCHAIN_TRIPLE})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${TOOLCHAIN_TRIPLE})

set(CMAKE_ASM_FLAGS_INIT "-fno-exceptions")
set(CMAKE_C_FLAGS_INIT   "-fno-exceptions")
set(CMAKE_CXX_FLAGS_INIT "-fno-exceptions")

# Inject the SDK target include dir as the FIRST system include for every
# translation unit. We add it via CMAKE_<LANG>_STANDARD_INCLUDE_DIRECTORIES
# (rather than -isystem in CMAKE_C_FLAGS_INIT) so it is appended via
# `-isystem` to every compile command without being detected as part of the
# compiler's implicit include set (which would let CMake silently strip it).
# Subprojects that reset CMAKE_C_FLAGS therefore still get the SDK headers.
set(_PS5_CXX_INCLUDE "${_PS5_TARGET_INCLUDE}/c++/v1")
set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES   "${_PS5_TARGET_INCLUDE}")
if(EXISTS "${_PS5_CXX_INCLUDE}")
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES
        "${_PS5_CXX_INCLUDE}" "${_PS5_TARGET_INCLUDE}")
else()
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${_PS5_TARGET_INCLUDE}")
endif()
set(CMAKE_ASM_STANDARD_INCLUDE_DIRECTORIES "${_PS5_TARGET_INCLUDE}")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(LINKER_SCRIPT "${CMAKE_CURRENT_LIST_DIR}/../linker.x")
# Note: clang's `x86_64-sie-ps5` target rejects `-fuse-ld=lld`; lld is already
# the default linker driven by the SDK's prospero-lld wrapper / clang for this
# target, so we omit -fuse-ld here.

# Linker behaviour differs by output role:
# - shellui.elf is the etaHEN-style PT_DYN payload that libNineS injects into
#   the SceShellUI process. It needs --shared + the in-tree linker.x.
# - daemon.elf is a real PS5 payload that ps5-payload-elfldr style loaders
#   load via e_entry, so it must NOT use --shared and must keep `crt1.o` plus
#   the standard PS5 runtime libs that prospero-clang auto-injects.
#
# `add_link_options` is global, so we gate the etaHEN-only flags on the target
# name with a generator expression. The shellui target opts in; everything
# else (daemon) gets a clean executable link.
set(_PS5_ETAHEN_TARGETS shellui)
set(_PS5_IS_ETAHEN "$<IN_LIST:$<TARGET_PROPERTY:NAME>,${_PS5_ETAHEN_TARGETS}>")

set(CMAKE_EXE_LINKER_FLAGS "-fPIC -L${_PS5_TARGET_LIB}")
set(CMAKE_SHARED_LINKER_FLAGS "-nostdlib -L${_PS5_TARGET_LIB}")

add_link_options(
    "$<${_PS5_IS_ETAHEN}:-nodefaultlibs>"
    "$<${_PS5_IS_ETAHEN}:LINKER:-T,${LINKER_SCRIPT}>"
    # Pass `--shared` (long form) so the SDK's prospero-lld wrapper, which only
    # recognises the long form when deciding to drop its default `-pie`, does
    # not produce a `-shared`+`-pie` conflict.
    "$<${_PS5_IS_ETAHEN}:LINKER:SHELL:--shared --build-id=none -zmax-page-size=16384 -zcommon-page-size=16384 --hash-style=sysv>"
)

set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(CMAKE_C_LINKER_WRAPPER_FLAG "-Xlinker" " ")
