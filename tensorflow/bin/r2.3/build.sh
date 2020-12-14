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
BZL_VERSION="3.1.0"
TF_VERSION="2.3";
TF_REVISION="1";
TF_VERSION_FULL="${TF_VERSION}.${TF_REVISION}";
TF_VARIANT="cpu";
TF_SRC="${HOME}/.tensorflow/src";
TF_LIB="${HOME}/.tensorflow/lib/${TF_VERSION_FULL}-${TF_VARIANT}";

# Iterate over arguments list to configure the installation.
for i in "$@"
do
case $i in
  --gpu)
    TF_VARIANT="gpu"
    TF_LIB="${HOME}/.tensorflow/lib/${TF_VERSION_FULL}-${TF_VARIANT}";
    shift # past argument with no value
    ;;
  *)
    echo "[build tensorflow]: Error: Unknown arguments: ${i#*=}"
    exit 1
    ;;
esac
done

# TODO: check version of TF to determine version of Bazel to install
echo "TensorFlow: Building ${TF_VERSION_FULL}-${TF_VARIANT} using Bazel ${BZL_VERSION}";
echo "TensorFlow: Build: Using source path: ${TF_SRC}";
echo "TensorFlow: Build: Using output path: ${TF_LIB}";

# Clear any existing directories
if [[ -d "${TF_LIB}" ]];
then
  rm -rf ${TF_LIB};
  echo "TensorFlow: Build: Removing existing directory: ${TF_LIB}";
fi

# Download and install system dependencies
sudo apt update && sudo apt install -y pkg-config zip g++ zlib1g-dev unzip python3-dev python3-pip

# TODO: Check version and remove previous if it does not exist
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
  git clone --branch r${TF_VERSION} https://github.com/tensorflow/tensorflow.git ${TF_SRC}
fi

# Check for previous build and clean Bazel workspace if necessary
if [[ -d "${TF_SRC}/bazel-bin" ]] || [[ -d "${TF_SRC}/bazel-out" ]];
then
  echo "TensorFlow: Build: Removing symlinks to previous build";
  bazel clean --expunge
fi

# Configure and build targets
rm -f ${TF_SRC}/.tf_configure.bazelrc
cp ./tf_configure.bazelrc.${TF_VARIANT} ${TF_SRC}/.tf_configure.bazelrc
cd ${TF_SRC}
echo "TensorFlow: Build: Building targets";
bazel build //tensorflow:libtensorflow_cc.so //tensorflow:install_headers //third_party/eigen3:install_eigen_headers

# Copy all source contents
echo "TensorFlow: Build: Copying headers";
rm -rf ${TF_LIB}
mkdir -p ${TF_LIB}/include
cp -r -L ${TF_SRC}/bazel-bin/tensorflow/include/tensorflow ${TF_LIB}/include/
cp -r -L ${TF_SRC}/bazel-bin/tensorflow/include/absl ${TF_LIB}/include/
cp -r -L ${TF_SRC}/bazel-bin/tensorflow/include/src/google ${TF_LIB}/include/
cp -r -L ${TF_SRC}/bazel-bin/third_party/eigen3/include/* ${TF_LIB}/include/

# Copy binary contents
echo "TensorFlow: Build: Copying libraries";
mkdir -p ${TF_LIB}/lib
cp -rP ${TF_SRC}/bazel-bin/tensorflow/*.so* ${TF_LIB}/lib/
rm -rf ${TF_LIB}/lib/*.params ${TF_LIB}/lib/*.runfiles*

# Completion
echo "TensorFlow: Build: Done!";

# EOF
