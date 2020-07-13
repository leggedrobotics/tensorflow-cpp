#=============================================================================
# Copyright (C) 2020, Robotic Systems Lab, ETH Zurich
# All rights reserved.
# http://www.rsl.ethz.ch
# https://github.com/leggedrobotics/tensorflow-cpp
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# Authors: Vassilios Tsounis, tsounsiv@ethz.ch
#=============================================================================
cmake_minimum_required(VERSION 3.10)
project(TensorFlow VERSION 0.2.0 LANGUAGES CXX)

# Include CMake helper packages and utilities
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

#==
# Options
#==

option(TF_USE_GPU "Configures TensorFlow for Nvidia CUDA GPUs." OFF)
option(TF_USE_IN_SOURCE "Configures TensorFlow for in-source builds." OFF)

#==
# Dependencies
#==

# NONE

#==
# Build configuration
#==

# Step 1: Determine if a provided or custom build should be used
if(NOT DEFINED TENSORFLOW_ROOT)
  # Sets the version to use if not otherwise specied by the user
  # NOTE: Users wanting to use other provided versions should specify
  # this at build time using command line: -DTENSORFLOW_VERSION=<VERSION>
  if(NOT DEFINED TENSORFLOW_VERSION)
    set(TENSORFLOW_VERSION "1.15.2")
  endif()
  # Sets to use CPU-only (default) or GPU-enabled (optional) builds
  if(TF_USE_GPU)
    set(TENSORFLOW_DIST ${TENSORFLOW_VERSION}-gpu)
  else()
    set(TENSORFLOW_DIST ${TENSORFLOW_VERSION}-cpu)
  endif()
  # Retrieve pre-built binaries and headers if they dont exist
  set(TENSORFLOW_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/lib/${TENSORFLOW_DIST})
  if(NOT EXISTS ${TENSORFLOW_SRC_DIR})
    # Determine the URL for the archive download based on the desired version
    set(TENSORFLOW_ARCHIVE_SRC_URL "https://github.com/leggedrobotics/tensorflow-cpp/releases/download")
    if(${TENSORFLOW_VERSION} STREQUAL "1.15.2")
      set(TENSORFLOW_ARCHIVE_URL "${TENSORFLOW_ARCHIVE_SRC_URL}/v0.2.0/${TENSORFLOW_DIST}.zip")
    elseif(${TENSORFLOW_VERSION} STREQUAL "1.13.2")
      set(TENSORFLOW_ARCHIVE_URL "${TENSORFLOW_ARCHIVE_SRC_URL}/v0.1.1/${TENSORFLOW_DIST}.zip")
    else()
      message(FATAL_ERROR "tensorflow-cpp: Version '${TENSORFLOW_VERSION}' is not supported.")
    endif()
    # Set the archive file
    set(TENSORFLOW_ARCHIVE_ZIP ${TENSORFLOW_SRC_DIR}.zip)
    # Download the archive if it's not present in the library directory
    if(NOT EXISTS ${TENSORFLOW_ARCHIVE_ZIP})
      message(STATUS "tensorflow-cpp: Downloading binaries from '${TENSORFLOW_ARCHIVE_URL}' as '${TENSORFLOW_ARCHIVE_ZIP}'. Please wait until completed ...")
      file(DOWNLOAD ${TENSORFLOW_ARCHIVE_URL} ${TENSORFLOW_ARCHIVE_ZIP} SHOW_PROGRESS STATUS TENSORFLOW_ARCHIVE_STATUS)
      list(GET ${TENSORFLOW_ARCHIVE_STATUS} 0 TENSORFLOW_ARCHIVE_STATUS_RESULT)
      if (${TENSORFLOW_ARCHIVE_STATUS_RESULT})
        list(GET ${TENSORFLOW_ARCHIVE_STATUS} 1 TENSORFLOW_ARCHIVE_STATUS_ERROR)
        message(FATAL_ERROR "tensorflow-cpp: Failed to download '${TENSORFLOW_ARCHIVE_URL}': Error: ${TENSORFLOW_ARCHIVE_STATUS_ERROR}")
      endif ()
      message(STATUS "tensorflow-cpp: Completed download of '${TENSORFLOW_ARCHIVE_URL}'.")
    endif()
    # Extract the downloaded archive
    message(STATUS "tensorflow-cpp: Extracting '${TENSORFLOW_ARCHIVE_URL}' ...")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar -xf ${TENSORFLOW_ARCHIVE_ZIP} WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lib)
    message(STATUS "tensorflow-cpp: Completed extraction of '${TENSORFLOW_ARCHIVE_URL}'.")
  endif()
  get_filename_component(TENSORFLOW_SRC_DIR ${TENSORFLOW_SRC_DIR} ABSOLUTE)
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
file(GLOB TENSORFLOW_HDRS RELATIVE ${TENSORFLOW_SRC_DIR}/include ${TENSORFLOW_SRC_DIR}/include/*)
foreach(subdir ${TENSORFLOW_HDRS})
  list(APPEND TENSORFLOW_SRC_HEADERS ${TENSORFLOW_SRC_DIR}/include/${subdir})
  list(APPEND TENSORFLOW_HEADERS ${TENSORFLOW_INSTALL_DIR}/include/tensorflow/${subdir})
endforeach()

# Collect a list of library binaries
file(GLOB TENSORFLOW_LIBS RELATIVE ${TENSORFLOW_SRC_DIR}/lib ${TENSORFLOW_SRC_DIR}/lib/*)
foreach(lib ${TENSORFLOW_LIBS})
  list(APPEND TENSORFLOW_SRC_LIBRARIES ${TENSORFLOW_SRC_DIR}/lib/${lib})
  list(APPEND TENSORFLOW_LIBRARIES ${TENSORFLOW_INSTALL_DIR}/lib/${lib})
endforeach()

# Define interface target
add_library(${PROJECT_NAME} INTERFACE)
target_include_directories(${PROJECT_NAME}
  INTERFACE
    $<BUILD_INTERFACE:${TENSORFLOW_SRC_DIR}/include>
    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include/tensorflow>
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
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tensorflow
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
      ${CMAKE_INSTALL_INCLUDEDIR}/tensorflow
  )
  install(
    FILES
      ${TENSORFLOW_SRC_LIBRARIES}
    DESTINATION
      ${CMAKE_INSTALL_LIBDIR}
  )
endif ()

# EOF
