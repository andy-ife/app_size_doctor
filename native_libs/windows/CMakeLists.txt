cmake_minimum_required(VERSION 3.20)
project(mf_transcoder LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(mf_transcoder SHARED
  mf_transcoder.cpp
)

target_include_directories(mf_transcoder PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_definitions(mf_transcoder PRIVATE
  MF_TRANSCODER_BUILD_DLL
  UNICODE
  _UNICODE
)

target_link_libraries(mf_transcoder PRIVATE
  mfplat
  mfreadwrite
  mfuuid
  ole32
)