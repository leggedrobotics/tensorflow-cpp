#=============================================================================
# Copyright (C) 2019, Robotic Systems Lab, ETH Zurich
# All rights reserved.
# http://www.rsl.ethz.ch
# https://bitbucket.org/leggedrobotics/tensorflow
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# Authors: Vassilios Tsounis, tsounsiv@ethz.ch
#=============================================================================
cmake_minimum_required(VERSION 3.10)
project(TensorFlow VERSION 0.0.0 LANGUAGES CXX)

# Include CMake helper packages and utilities
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

#==
# Options
#==

# Configures the use of the  pre-built library built for CPU-only support.
option(TF_CPU_ONLY "Configures TensorFlow for CPU-only computations." OFF)
option(TF_USE_IN_SOURCE "Configures TensorFlow for in-source builds." OFF)

#==
# Dependencies
#==

# Eigen: A C++ template library for linear algebra
find_package(Eigen3 REQUIRED HINTS ${Eigen3_HINT})
if(EIGEN3_FOUND)
  message(STATUS "Eigen3:")
  message(STATUS "  Version: ${EIGEN3_VERSION_STRING}")
  message(STATUS "  Includes: ${EIGEN3_INCLUDE_DIRS}")
endif()

#==
# Build configuration
#==

# Step 1: Determine if a provided or custom build should be used
if(NOT DEFINED TENSORFLOW_ROOT)
  # Sets the version to use if not otherwise specied by the user
  # NOTE: Users wanting to use other provided versions should specify
  # this at build time using command line: -DTENSORFLOW_VERSION=<VERSION>
  if(NOT DEFINED TENSORFLOW_VERSION)
    set(TENSORFLOW_VERSION "1.13.2")
  endif()
  # Sets to use CPU-only or GPU-enabled builds
  if(TF_CPU_ONLY)
    set(TENSORFLOW_DIST ${TENSORFLOW_VERSION}-cpu)
  else()
    set(TENSORFLOW_DIST ${TENSORFLOW_VERSION}-gpu)
  endif()
  set(TENSORFLOW_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/lib/${TENSORFLOW_DIST})
  # Retrieve pre-built binaries and headers if they dont exist
  if(NOT EXISTS ${TENSORFLOW_SRC_DIR})
    set(TFLIBZIP ${TENSORFLOW_SRC_DIR}.zip)
    set(TFLIBURL https://github.com/leggedrobotics/tensorflow-cpp/releases/download/v0.1.0/${TENSORFLOW_DIST}.zip)
    message(STATUS "Downloading binaries from '${TFLIBURL}'. Please wait ...")
    if(NOT EXISTS ${TFLIBZIP})
      file(DOWNLOAD ${TFLIBURL} ${TFLIBZIP})
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar -xf ${TFLIBZIP} WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lib)
  endif()
  message(STATUS "Done.")
  get_filename_component(TENSORFLOW_SRC_DIR ${TENSORFLOW_SRC_DIR} REALPATH)
else()
  # Uses user-specified (custom) build
  set(TENSORFLOW_VERSION "Custom")
  set(TENSORFLOW_SRC_DIR ${TENSORFLOW_ROOT})
endif()

# Step 2: Determine if to include headers and libraries in-source or via the installation path
if (TF_USE_IN_SOURCE)
  set(TENSORFLOW_INSTALL_DIR ${TENSORFLOW_SRC_DIR})
else()
  set(TENSORFLOW_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
endif()

#==
# Build target
#==

# Collect a list of header directories
FILE(GLOB TENSORFLOW_HDRS RELATIVE ${TENSORFLOW_SRC_DIR}/include ${TENSORFLOW_SRC_DIR}/include/*)
foreach(subdir ${TENSORFLOW_HDRS})
  list(APPEND TENSORFLOW_SRC_HEADERS ${TENSORFLOW_SRC_DIR}/include/${subdir})
  list(APPEND TENSORFLOW_HEADERS ${TENSORFLOW_INSTALL_DIR}/include/${subdir})
endforeach()
list(APPEND TENSORFLOW_SRC_HEADERS ${TENSORFLOW_SRC_DIR}/include/bazel-genfiles)
list(APPEND TENSORFLOW_HEADERS ${TENSORFLOW_INSTALL_DIR}/include/bazel-genfiles)

# Collect a list of library binaries
FILE(GLOB TENSORFLOW_LIBS RELATIVE ${TENSORFLOW_SRC_DIR}/lib ${TENSORFLOW_SRC_DIR}/lib/*)
foreach(lib ${TENSORFLOW_LIBS})
  list(APPEND TENSORFLOW_SRC_LIBRARIES ${TENSORFLOW_SRC_DIR}/lib/${lib})
  list(APPEND TENSORFLOW_LIBRARIES ${TENSORFLOW_INSTALL_DIR}/lib/${lib})
endforeach()

# Define interface target
add_library(${PROJECT_NAME} INTERFACE)
target_include_directories(${PROJECT_NAME}
  INTERFACE
    $<BUILD_INTERFACE:${TENSORFLOW_SRC_DIR}/include>
    $<BUILD_INTERFACE:${TENSORFLOW_SRC_DIR}/include/bazel-genfiles>
    "$<BUILD_INTERFACE:${EIGEN3_INCLUDE_DIRS}>"
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/bazel-genfiles>
    "$<INSTALL_INTERFACE:${EIGEN3_INCLUDE_DIRS}>"
)
target_link_libraries(${PROJECT_NAME} INTERFACE ${TENSORFLOW_LIBRARIES})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

#==
# Package targets
#==

install(TARGETS ${PROJECT_NAME}
  EXPORT ${PROJECT_NAME}-targets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

export(TARGETS ${PROJECT_NAME}
  NAMESPACE ${PROJECT_NAME}::
  FILE ${PROJECT_NAME}-targets.cmake
)

install(EXPORT ${PROJECT_NAME}-targets
  FILE ${PROJECT_NAME}-targets.cmake
  NAMESPACE ${PROJECT_NAME}::
  DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake
)

#==
# Package configuration
#==

# Set package configurations
set(CONFIG_VERSION ${TENSORFLOW_VERSION})
set(CONFIG_DIRECTORY ${TENSORFLOW_INSTALL_DIR})

# Generate package configuration file
configure_package_config_file(
  ${CMAKE_CURRENT_LIST_DIR}/cmake/tensorflow-config.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/cmake/tensorflow-config.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake
)

# Generate package version file
write_basic_package_version_file(cmake/tensorflow-config-version.cmake
  VERSION ${TENSORFLOW_VERSION}
  COMPATIBILITY AnyNewerVersion
)

#==
# Package installation
#==

# Install package configuration files
install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/tensorflow-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/tensorflow-config-version.cmake
  DESTINATION
    ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake
)

# Install the library (i.e. headers and libraries) if not used in-source
if (NOT TF_USE_IN_SOURCE)
  install(
    DIRECTORY
      ${TENSORFLOW_SRC_HEADERS}
    DESTINATION
      ${CMAKE_INSTALL_INCLUDEDIR}
  )
  install(
    FILES
      ${TENSORFLOW_SRC_LIBRARIES}
    DESTINATION
      ${CMAKE_INSTALL_LIBDIR}
  )
endif ()

# EOF
