#!/bin/bash

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

# Helper function for downloading Eigen archives
function download_from_url() {
  if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]];
  then
    EIGEN_ARCHIVE_URL=$1
    EIGEN_ARCHIVE_NAME="eigen-${EIGEN_COMMIT}"
    EIGEN_ARCHIVE="${EIGEN_ARCHIVE_NAME}.${EIGEN_ARCHIVE_TYPE}"
    echo "DOWNDLOAD: ${EIGEN_ARCHIVE}"
    echo "Install: Downloading Eigen from '${EIGEN_ARCHIVE_URL}'";
    echo "Install: Target directory is '${EIGEN_DIR}'";
    echo "Install: Target name is '${EIGEN_ARCHIVE}'";
    wget -v ${EIGEN_ARCHIVE_URL} -O "${EIGEN_ARCHIVE}"
  else
    echo "Install: Archive link is invalid for: '$1'";
  fi
}

#==
# Start
#==

# Set the source directory of this file
EIGEN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# First check if an existing directory exists
if [[ -d "${EIGEN_DIR}/eigen3" ]];
then
  echo "Install: '${EIGEN_DIR}/eigen3' already exists. Please remove it before continuing.";
  exit;
fi

# Set the default version of TensorFlow
if [[ -z ${TENSORFLOW_VERSION} ]]; then TENSORFLOW_VERSION="1.15"; fi

# Set default commit version
if [[ -z ${EIGEN_COMMIT} ]]; then EIGEN_COMMIT="49177915a14a"; fi

# Define mappings from TensorFlow versions to Eigen commits
if [[ "${TENSORFLOW_VERSION}" == "1.13" && -z ${EIGEN_COMMIT} ]]; then EIGEN_COMMIT="9f48e814419e"; fi
if [[ "${TENSORFLOW_VERSION}" == "1.15" && -z ${EIGEN_COMMIT} ]]; then EIGEN_COMMIT="49177915a14a"; fi

# Step 1.: Download the archive
EIGEN_ARCHIVE_TYPE="tar.gz"
EIGEN_ARCHIVE_URL="https://storage.googleapis.com/mirror.tensorflow.org/bitbucket.org/eigen/eigen/get/${EIGEN_COMMIT}.${EIGEN_ARCHIVE_TYPE}"
download_from_url ${EIGEN_ARCHIVE_URL}

# Step 3.: Unpackage archive into ./eigen3
echo "Install: Unpacking Eigen into destination '${EIGEN_DIR}/eigen3'"
tar -xvzf ${EIGEN_ARCHIVE}
mv eigen-${EIGEN_ARCHIVE_NAME} ${EIGEN_DIR}/eigen3
rm -rf eigen-${EIGEN_ARCHIVE_NAME} ${EIGEN_ARCHIVE}

# Step 4.: Add the necessary package configuration file for Catkin
echo "Install: Adding Catkin package file to '${EIGEN_DIR}/eigen3'"
cp ${EIGEN_DIR}/package.xml.in ${EIGEN_DIR}/eigen3/package.xml

# Step 4.: Apply patch from tensorflow archives
echo "Install: Applying TensorFlow patch to '${EIGEN_DIR}/eigen3'"
cd ${EIGEN_DIR}/eigen3
wget "https://raw.githubusercontent.com/tensorflow/tensorflow/r${TENSORFLOW_VERSION}/third_party/eigen3/gpu_packet_math.patch"
patch -p1 < gpu_packet_math.patch
cd ${EIGEN_DIR}

# Steps 5+6 are optional
if [[ $1 == "--run-cmake" ]];
then

  # Set install location
  if [[ -z "$2" ]]
  then
    EIGEN_INSTALL_PREFIX="${HOME}/.local"
  else
    EIGEN_INSTALL_PREFIX="$2"
  fi

  # Step 5.: Removing existing Eigen installation
  echo "Install: Removing previous installation of Eigen3 at '${EIGEN_INSTALL_PREFIX}'."
  rm -rf ${EIGEN_INSTALL_PREFIX}/include/eigen3 ${EIGEN_INSTALL_PREFIX}/share/eigen3 ${EIGEN_INSTALL_PREFIX}/share/pkgconfig/eigen3.pc

  # Step 6.: Build and install Eigen
  echo "Install: Building and installing Eigen3 at '${EIGEN_INSTALL_PREFIX}'."
  mkdir -p ${EIGEN_DIR}/eigen3/build
  cd ${EIGEN_DIR}/eigen3/build
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${EIGEN_INSTALL_PREFIX}
  make install -j
fi

# EOF
