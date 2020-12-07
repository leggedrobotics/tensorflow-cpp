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
    EIGEN_ARCHIVE_TYPE=$2
    EIGEN_ARCHIVE_NAME=$3
    EIGEN_ARCHIVE="${EIGEN_ARCHIVE_NAME}.${EIGEN_ARCHIVE_TYPE}"
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

# Default configurations
TENSORFLOW_VERSION="2.3"
RUN_CMAKE=false
INSTALL_PREFIX="${HOME}/.local"

# Iterate over arguments list to configure the installation.
for i in "$@"
do
case $i in
  --tf-version=*)
    TENSORFLOW_VERSION="${i#*=}"
    shift # past argument with no value
    ;;
  --run-cmake)
    RUN_CMAKE=true
    shift # past argument with no value
    ;;
  --install-prefix=*)
    INSTALL_PREFIX=$(eval realpath -m "${i#*=}")
    shift # past argument with no value
    ;;
  *)
    echo "[install docker]: Error: Unknown arguments: ${i#*=}"
    exit 1
    ;;
esac
done

# First check if an existing directory exists
if [[ -d "${EIGEN_DIR}/eigen3" ]];
then
  echo "Install: '${EIGEN_DIR}/eigen3' already exists. Please remove it before continuing.";
  exit;
fi

# Define mappings from TensorFlow versions to Eigen commits
if [[ "${TENSORFLOW_VERSION}" == "1.13" && -z ${EIGEN_ARCHIVE_URL} ]];
then
  EIGEN_COMMIT="9f48e814419e";
  EIGEN_ARCHIVE_TYPE="tar.gz"
  EIGEN_ARCHIVE_NAME="${EIGEN_COMMIT}"
  EIGEN_ARCHIVE_URL="https://storage.googleapis.com/mirror.tensorflow.org/bitbucket.org/eigen/eigen/get/${EIGEN_COMMIT}.${EIGEN_ARCHIVE_TYPE}"
elif [[ "${TENSORFLOW_VERSION}" == "1.15" && -z ${EIGEN_ARCHIVE_URL} ]];
then
  EIGEN_COMMIT="49177915a14a";
  EIGEN_ARCHIVE_TYPE="tar.gz"
  EIGEN_ARCHIVE_NAME="eigen-eigen-${EIGEN_COMMIT}"
  EIGEN_ARCHIVE_URL="https://storage.googleapis.com/mirror.tensorflow.org/bitbucket.org/eigen/eigen/get/${EIGEN_COMMIT}.${EIGEN_ARCHIVE_TYPE}"
elif [[ "${TENSORFLOW_VERSION}" == "2.3" && -z ${EIGEN_ARCHIVE_URL} ]];
then
  EIGEN_COMMIT="386d809bde475c65b7940f290efe80e6a05878c4";
  EIGEN_ARCHIVE_TYPE="tar.gz"
  EIGEN_ARCHIVE_NAME="eigen-${EIGEN_COMMIT}"
  EIGEN_ARCHIVE_URL="https://storage.googleapis.com/mirror.tensorflow.org/gitlab.com/libeigen/eigen/-/archive/${EIGEN_COMMIT}/eigen-${EIGEN_COMMIT}.${EIGEN_ARCHIVE_TYPE}"
else
  echo "Install: Version '${TENSORFLOW_VERSION}' not recognized. Please use one of the following: {1.13, 1.15, 2.3}";
  exit;
fi

# Step 1.: Download the archive
download_from_url ${EIGEN_ARCHIVE_URL} ${EIGEN_ARCHIVE_TYPE} ${EIGEN_ARCHIVE_NAME}

# Step 2.: Unpack archive into ${EIGEN_DIR}/eigen3
echo "Install: Unpacking Eigen into destination '${EIGEN_DIR}/eigen3'"
tar -xvzf ${EIGEN_ARCHIVE}
mv ${EIGEN_ARCHIVE_NAME} ${EIGEN_DIR}/eigen3
rm -rf ${EIGEN_ARCHIVE_NAME} ${EIGEN_ARCHIVE}

# Step 3.: Add the necessary package configuration file for Catkin
echo "Install: Adding Catkin package file to '${EIGEN_DIR}/eigen3'"
cp ${EIGEN_DIR}/package.xml.in ${EIGEN_DIR}/eigen3/package.xml

# Step 4.: Apply patch from tensorflow archives
echo "Install: Applying TensorFlow patch to '${EIGEN_DIR}/eigen3'"
cd ${EIGEN_DIR}/eigen3
wget "https://raw.githubusercontent.com/tensorflow/tensorflow/r${TENSORFLOW_VERSION}/third_party/eigen3/gpu_packet_math.patch"
patch -p1 < gpu_packet_math.patch
cd ${EIGEN_DIR}

# (Optionally) Steps 5+6 are optional
if [[ ${RUN_CMAKE} == true ]]
then
  # Step 5.: Removing existing Eigen installation
  echo "Install: Removing previous installation of Eigen3 at '${INSTALL_PREFIX}'."
  rm -rf ${INSTALL_PREFIX}/include/eigen3 ${INSTALL_PREFIX}/share/eigen3 ${INSTALL_PREFIX}/share/pkgconfig/eigen3.pc

  # Step 6.: Build and install Eigen
  echo "Install: Building and installing Eigen3 at '${INSTALL_PREFIX}'."
  mkdir -p ${EIGEN_DIR}/eigen3/build
  cd ${EIGEN_DIR}/eigen3/build
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
  make install -j
fi

# EOF
