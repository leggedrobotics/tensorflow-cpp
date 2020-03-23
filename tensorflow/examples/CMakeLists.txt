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
project(TensorFlowExamples VERSION 0.2.0 LANGUAGES CXX)

#==
# Dependencies
#==

find_package(TensorFlow CONFIG REQUIRED)

#==
# Targets
#==

add_executable(tf_example_session src/example_session.cc)
target_link_libraries(tf_example_session PUBLIC TensorFlow::TensorFlow)
target_compile_features(tf_example_session PRIVATE cxx_std_14)

add_executable(tf_example_trainer src/example_trainer.cc)
target_link_libraries(tf_example_trainer PUBLIC TensorFlow::TensorFlow)
target_compile_features(tf_example_trainer PRIVATE cxx_std_14)

#==
# Installation
#==

install(
  TARGETS tf_example_session tf_example_trainer
  RUNTIME DESTINATION bin
)

# EOF
