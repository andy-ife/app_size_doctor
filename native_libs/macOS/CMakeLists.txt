cmake_minimum_required(VERSION 3.20)
project(mac_transcoder LANGUAGES CXX OBJC)

if(NOT APPLE)
  message(FATAL_ERROR "This CMake target is intended for macOS (APPLE).")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OBJCXX_STANDARD 17)
set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)

add_library(mac_transcoder SHARED
  av_transcoder.mm
)

target_include_directories(mac_transcoder PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
)

# Enable Objective-C ARC for av_transcoder.mm
set_source_files_properties(av_transcoder.mm PROPERTIES
  COMPILE_FLAGS "-fobjc-arc"
)

# Set deployment target if needed (e.g., macOS 11.0+ for AVVideoCodecTypeH264)
if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "Minimum macOS version" FORCE)
endif()

target_link_libraries(mac_transcoder PRIVATE
  "-framework Foundation"
  "-framework AVFoundation"
  "-framework CoreMedia"
  "-framework CoreVideo"
  "-framework AudioToolbox"
)