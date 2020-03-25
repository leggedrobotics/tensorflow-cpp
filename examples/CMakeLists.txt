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
project(tensorflow_examples VERSION 0.2.0 LANGUAGES CXX)

# Include GNU standard install directories module
include(GNUInstallDirs)

#==
# Dependencies
#==

find_package(TensorFlow CONFIG REQUIRED)

#==
# Targets
#==

add_executable(tf_example_trainer src/example_trainer.cc)
target_link_libraries(tf_example_trainer PUBLIC TensorFlow::TensorFlow)
target_compile_features(tf_example_trainer PRIVATE cxx_std_14)

#==
# Installation
#==

install(
  TARGETS tf_example_trainer
  RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}
)

# EOF
