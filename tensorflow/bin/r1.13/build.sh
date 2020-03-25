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

# Set default versions
BZL_VERSION="0.19.2"

# Set the default version and variant
if [[ -z ${TF_VERSION} ]];
then TF_VERSION="1.13";
fi
if [[ -z ${TF_VARIANT} ]];
then TF_VARIANT="gpu";
fi

# TODO: check version of TF to determine version of Bazel to install
echo "TensorFlow: Building ${TF_VERSION}-${TF_VARIANT} using Bazel ${BZL_VERSION}";

# Set the default source directory
if [[ -z ${TF_SRC} ]];
then
  TF_SRC="${HOME}/.tensorflow/src";
  echo "TensorFlow: Build: Using default source path: ${TF_SRC}";
else
  echo "TensorFlow: Build: Using source path: ${TF_SRC}";
fi

# Set the default output directory
if [[ -z ${TF_LIB} ]];
then
  TF_LIB="${HOME}/.tensorflow/lib/${TF_VERSION}-${TF_VARIANT}";
  echo "TensorFlow: Build: Using default output path: ${TF_LIB}";
else
  echo "TensorFlow: Build: Using output path: ${TF_LIB}";
fi

# Clear any existing directories
if [[ -d "${TF_LIB}" ]];
then
  rm -rf ${TF_LIB};
  echo "TensorFlow: Build: Removing existing directory: ${TF_LIB}";
fi

# Download and install system dependencies
sudo apt-get install -y pkg-config zip g++ zlib1g-dev unzip python python3

# Download and install Bazel
if ! [[ -x "$(command -v bazel)" ]];
then
  echo "TensorFlow: Build: Installing Bazel ${BZL_VERSION}";
  wget https://github.com/bazelbuild/bazel/releases/download/${BZL_VERSION}/bazel-${BZL_VERSION}-installer-linux-x86_64.sh -P /tmp/bazel/
  chmod +x /tmp/bazel/bazel-${BZL_VERSION}-installer-linux-x86_64.sh
  /tmp/bazel/bazel-${BZL_VERSION}-installer-linux-x86_64.sh --prefix=/home/$USER/.local
fi

# Clone TensorFlow source
if ! [[ -d "${TF_SRC}" ]];
then
  echo "TensorFlow: Build: Cloning TensorFlow";
  git clone https://github.com/tensorflow/tensorflow.git ${TF_SRC};
fi

# Configure and build TensorFlow
if [[ -d "${TF_SRC}/bazel-bin" ]];
then
  echo "TensorFlow: Build: Removing symlinks to previous build";
  rm -r ${TF_SRC}/bazel-*
fi

cp tf_configure.bazelrc.${TF_VARIANT} ${TF_SRC}/.tf_configure.bazelrc
cd ${TF_SRC}
git checkout r${TF_VERSION}
echo "TensorFlow: Build: Building 'libtensorflow_cc'";
bazel build //tensorflow:libtensorflow_cc.so

# Create the output directories
mkdir -p ${TF_LIB}/include/third_party
mkdir -p ${TF_LIB}/include/tensorflow
mkdir -p ${TF_LIB}/include/nsync
mkdir -p ${TF_LIB}/include/gemmlowp
mkdir -p ${TF_LIB}/include/bazel-genfiles
mkdir -p ${TF_LIB}/lib

# Copy all source contents
echo "TensorFlow: Build: Copying headers";
cp -r -L ${TF_SRC}/bazel-genfiles/* ${TF_LIB}/include/bazel-genfiles
cp -r -L ${TF_SRC}/bazel-src/tensorflow/* ${TF_LIB}/include/tensorflow
cp -r -L ${TF_SRC}/bazel-src/external/nsync/public ${TF_LIB}/include/nsync/
cp -r -L ${TF_SRC}/bazel-src/external/gemmlowp/public ${TF_LIB}/include/gemmlowp/
cp -r -L ${TF_SRC}/bazel-src/external/protobuf_archive/src/* ${TF_LIB}/include/
cp -r -L ${TF_SRC}/bazel-src/external/com_google_absl/absl ${TF_LIB}/include/
cp -r -L ${TF_SRC}/bazel-src/third_party/* ${TF_LIB}/include/third_party/

# Remove all files which are not header files, and remove all residual empty directories
find ${TF_LIB}/include -type f -not -name '*.h' -not -name "*.cuh" -not -name "*.hpp" -delete
find ${TF_LIB}/include -empty -type d -delete

# Copy TensorFlow-specific Eigen3 headers
mkdir -p ${TF_LIB}/include/third_party/eigen3
cp -r -L ${TF_SRC}/third_party/eigen3 ${TF_LIB}/include/third_party/

# Copy binary contents
echo "TensorFlow: Build: Copying libraries";
cp ${TF_SRC}/bazel-bin/tensorflow/libtensorflow_cc.so ${TF_LIB}/lib/
cp ${TF_SRC}/bazel-bin/tensorflow/libtensorflow_framework.so ${TF_LIB}/lib/
cp ${TF_SRC}/bazel-src/bazel-out/host/bin/external/protobuf_archive/libprotobuf.so ${TF_LIB}/lib;

# Completion
echo "TensorFlow: Build: Done!";

# EOF
