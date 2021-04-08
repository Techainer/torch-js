cmake_minimum_required(VERSION 3.18)
project(torch-js)

set(TORCH_VERSION 1.8.1)
set(TORCH_DEFAULT_CUDA "102")
set(TORCHVISION_VERSION v0.9.1)


# Not had libtorch at source dir
if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/build/libtorch/")
  find_package(CUDA)
  if(CUDA_FOUND)
    # Check for unsupported CUDA version
    if(NOT "${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" MATCHES
       "^(102|111)$")
      message(
        FATAL_ERROR
          "${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR} are not provided by libtorch. Please build from source and place it at ${CMAKE_CURRENT_BINARY_DIR}/libtorch/"
      )
    endif()
    set(LIBTORCH_SAVE_PATH
        "${CMAKE_CURRENT_SOURCE_DIR}/libtorch-cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}.zip"
    )
    if(NOT EXISTS ${LIBTORCH_SAVE_PATH})
      if(WIN32)
        if("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" STREQUAL
           ${TORCH_DEFAULT_CUDA})
          set(DOWNLOAD_LINK
              "https://download.pytorch.org/libtorch/cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}/libtorch-win-shared-with-deps-${TORCH_VERSION}.zip"
          )
          message(
            STATUS "Downloading libtorch for Windows from ${DOWNLOAD_LINK}")
          file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
        else()
          set(DOWNLOAD_LINK
              "https://download.pytorch.org/libtorch/cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}/libtorch-win-shared-with-deps-${TORCH_VERSION}%2Bcu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}-.zip"
          )
          message(
            STATUS "Downloading libtorch for Windows from ${DOWNLOAD_LINK}")
          file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
        endif()
      elseif(APPLE)
        message(
          SEND_ERROR
            "MacOS does not support NVIDIA GPU, hence CUDA, will use the CPU version instead"
        )
        set(DOWNLOAD_LINK
            "https://download.pytorch.org/libtorch/cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}/libtorch-macos-${TORCH_VERSION}.zip"
        )
        message(STATUS "Downloading libtorch for MacOS from ${DOWNLOAD_LINK}")
        file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
      else()
        if("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" STREQUAL
           ${TORCH_DEFAULT_CUDA})
          set(DOWNLOAD_LINK
              "https://download.pytorch.org/libtorch/cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}/libtorch-shared-with-deps-${TORCH_VERSION}.zip"
          )
          message(STATUS "Downloading libtorch for Linux from ${DOWNLOAD_LINK}")
          file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
        else()
          set(DOWNLOAD_LINK
              "https://download.pytorch.org/libtorch/cu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}/libtorch-shared-with-deps-${TORCH_VERSION}%2Bcu${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}.zip"
          )
          message(STATUS "Downloading libtorch for Linux from ${DOWNLOAD_LINK}")
          file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
        endif()
      endif()
    endif()
    message(STATUS "Unziping ${LIBTORCH_SAVE_PATH}")
    execute_process(COMMAND unzip -qq -o ${LIBTORCH_SAVE_PATH})
  else()
    set(LIBTORCH_SAVE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/libtorch-cpu.zip")
    if(NOT EXISTS ${LIBTORCH_SAVE_PATH})
      if(WIN32)
        set(DOWNLOAD_LINK
            "https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-${TORCH_VERSION}%2Bcpu.zip"
        )
        message(STATUS "Downloading libtorch for Windows from ${DOWNLOAD_LINK}")
        file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
      elseif(APPLE)
        set(DOWNLOAD_LINK
            "https://download.pytorch.org/libtorch/cpu/libtorch-macos-${TORCH_VERSION}.zip"
        )
        message(STATUS "Downloading libtorch for MacOS from ${DOWNLOAD_LINK}")
        file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
      else()
        set(DOWNLOAD_LINK
            "https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-${TORCH_VERSION}%2Bcpu.zip"
        )
        message(STATUS "Downloading libtorch for Linux from ${DOWNLOAD_LINK}")
        file(DOWNLOAD ${DOWNLOAD_LINK} ${LIBTORCH_SAVE_PATH})
      endif()
    endif()
    message(STATUS "Unziping ${LIBTORCH_SAVE_PATH}")
    execute_process(COMMAND unzip -qq -o ${LIBTORCH_SAVE_PATH})
  endif(CUDA_FOUND)
else()
  message(STATUS "libtorch found in ${CMAKE_CURRENT_BINARY_DIR}/libtorch/")
endif()

# Use C++14
set(CMAKE_CXX_STANDARD 14)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Set CUDA_ARCHITECTURES
if(CUDA_FOUND)
  if("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" MATCHES "^102$")
    set(TORCH_CUDA_ARCH_LIST "6.0+PTX;6.1+PTX;6.2+PTX;7.0+PTX;7.2+PTX;7.5+PTX")
  elseif("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" MATCHES "^111$")
    set(TORCH_CUDA_ARCH_LIST "6.0+PTX;6.1+PTX;6.2+PTX;7.0+PTX;7.2+PTX;7.5+PTX;8.0+PTX;8.6+PTX")
  endif()
endif()

set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR}/libtorch/)
find_package(Torch REQUIRED)

if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/torchvision")
  set(TORCHVISON_SAVE_PATH
      "${CMAKE_CURRENT_SOURCE_DIR}/torchvision-${TORCHVISION_VERSION}.zip"
  )
  if(NOT EXISTS ${TORCHVISON_SAVE_PATH})
    set(DOWNLOAD_LINK
        "https://github.com/pytorch/vision/archive/refs/tags/${TORCHVISION_VERSION}.zip"
    )
    message(
      STATUS "Downloading torchvsion from ${DOWNLOAD_LINK}")
    file(DOWNLOAD ${DOWNLOAD_LINK} ${TORCHVISON_SAVE_PATH})
  endif()
  message(STATUS "Unziping ${TORCHVISON_SAVE_PATH}")
  execute_process(COMMAND unzip -qq -o ${TORCHVISON_SAVE_PATH})
  string(REPLACE "v" "" TORCHVISON_VERSION_NUM_ONLY ${TORCHVISION_VERSION})
  execute_process(COMMAND mv ${CMAKE_CURRENT_BINARY_DIR}/vision-${TORCHVISON_VERSION_NUM_ONLY} ${CMAKE_CURRENT_BINARY_DIR}/vision)
  message(STATUS "Compliling torchvision")



  if(CUDA_FOUND)
    # patch torchvision with a proper CUDA_ARCHITECTURES list like:
    # set_property(TARGET torchvision PROPERTY CUDA_ARCHITECTURES 60 61 62 70 72 75 80 86)
    if("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" MATCHES "^102$")
      execute_process(
        COMMAND
          sed -i "103 i set_property(TARGET torchvision PROPERTY CUDA_ARCHITECTURES 60 61 62 70 72 75)" "${CMAKE_CURRENT_BINARY_DIR}/vision/CMakeLists.txt")
    elseif("${CUDA_VERSION_MAJOR}${CUDA_VERSION_MINOR}" MATCHES "^111$")
      execute_process(
        COMMAND
          sed -i "103 i set_property(TARGET torchvision PROPERTY CUDA_ARCHITECTURES 60 61 62 70 72 75 80 86)" "${CMAKE_CURRENT_BINARY_DIR}/vision/CMakeLists.txt")
    endif()
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=Release -DWITH_CUDA=${CUDA_FOUND}
        -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/libtorch
        "-DTORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}" -S
        "${CMAKE_CURRENT_BINARY_DIR}/vision/" -B
        "${CMAKE_CURRENT_BINARY_DIR}/vision/build/"
      COMMAND_ECHO
      STDOUT
    )
  else()
    execute_process(
      COMMAND
        ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=Release -DWITH_CUDA=${CUDA_FOUND}
        -DCMAKE_PREFIX_PATH=${CMAKE_CURRENT_BINARY_DIR}/libtorch -S
        "${CMAKE_CURRENT_BINARY_DIR}/vision/" -B
        "${CMAKE_CURRENT_BINARY_DIR}/vision/build/"
      COMMAND_ECHO
      STDOUT
    )
  endif()
  execute_process(
    COMMAND ${CMAKE_COMMAND} --build "${CMAKE_CURRENT_BINARY_DIR}/vision/build"
            --config Release)
  execute_process(
    COMMAND
      ${CMAKE_COMMAND} --install "${CMAKE_CURRENT_BINARY_DIR}/vision/build"
      --prefix "${CMAKE_CURRENT_BINARY_DIR}/torchvision")
else()
  message(STATUS "torchvision found in ${CMAKE_CURRENT_BINARY_DIR}/torchvision")
endif()

set(CMAKE_PREFIX_PATH
    ${CMAKE_PREFIX_PATH};${CMAKE_CURRENT_BINARY_DIR}/torchvision/)
find_package(TorchVision)

# find_package( Boost 1.40 REQUIRED COMPONENTS system filesystem)

if(WIN32)

elseif(APPLE)
  set(CMAKE_BUILD_RPATH @loader_path;@executable_path)
else()
  set(CMAKE_BUILD_RPATH $ORIGIN)
endif()

include_directories(${CMAKE_JS_INC})

file(GLOB SOURCE_FILES "src/*.cc" "src/*.h")
add_library(${PROJECT_NAME} SHARED ${SOURCE_FILES} ${CMAKE_JS_SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "" SUFFIX ".node")

# Include N-API wrappers
execute_process(
  COMMAND node -p "require('node-addon-api').include"
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE NODE_ADDON_API_DIR)
string(REPLACE "\n" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
string(REPLACE "\"" "" NODE_ADDON_API_DIR ${NODE_ADDON_API_DIR})
target_include_directories(${PROJECT_NAME} PRIVATE ${NODE_ADDON_API_DIR})
add_definitions(-DNAPI_VERSION=3)

target_link_libraries(${PROJECT_NAME} ${TORCH_LIBRARIES})

target_include_directories(
  ${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/torchvision/include")
target_link_libraries(${PROJECT_NAME} TorchVision::TorchVision)

# target_link_libraries(${PROJECT_NAME} "${Boost_LIBRARIES}")

target_link_libraries(${PROJECT_NAME} ${CMAKE_JS_LIB})

add_custom_command(
  TARGET torch-js
  POST_BUILD
  COMMAND
    ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_CURRENT_BINARY_DIR}/libtorch/lib" $<TARGET_FILE_DIR:torch-js>)

if(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/torchvision/bin")
  add_custom_command(
    TARGET torch-js
    POST_BUILD
    COMMAND
      ${CMAKE_COMMAND} -E copy_directory
      "${CMAKE_CURRENT_BINARY_DIR}/torchvision/bin" $<TARGET_FILE_DIR:torch-js>)
elseif(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/torchvision/lib")
  add_custom_command(
    TARGET torch-js
    POST_BUILD
    COMMAND
      ${CMAKE_COMMAND} -E copy_directory
      "${CMAKE_CURRENT_BINARY_DIR}/torchvision/lib" $<TARGET_FILE_DIR:torch-js>)
elseif(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/torchvision/lib64")
  add_custom_command(
    TARGET torch-js
    POST_BUILD
    COMMAND
      ${CMAKE_COMMAND} -E copy_directory
      "${CMAKE_CURRENT_BINARY_DIR}/torchvision/lib64"
      $<TARGET_FILE_DIR:torch-js>)
endif()
