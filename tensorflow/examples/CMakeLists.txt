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
# Authors: Vassilios Tsounis, tsounisv@ethz.ch
#=============================================================================
cmake_minimum_required(VERSION 3.10)
project(TensorFlowExamples VERSION 0.0.0 LANGUAGES CXX)

#==
# Dependencies
#==

find_package(TensorFlow CONFIG REQUIRED)

#==
# Build target
#==

add_executable(tf_hello_world src/main.cpp)
target_link_libraries(tf_hello_world PUBLIC TensorFlow::TensorFlow)
target_compile_features(tf_hello_world PRIVATE cxx_std_14)

#==
# Package installation
#==

install(
  TARGETS tf_hello_world
  RUNTIME DESTINATION bin
)

# EOF
