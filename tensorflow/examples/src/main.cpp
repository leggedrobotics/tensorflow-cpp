/*!
 * @author    Vassilios Tsounis
 * @email     tsounisv@ethz.ch
 *
 * Copyright (C) 2020 Robotic Systems Lab, ETH Zurich.
 * All rights reserved.
 * http://www.rsl.ethz.ch/
 */

// C/C++
#include <iostream>

// TensorFlow
#include <tensorflow/core/platform/env.h>
#include <tensorflow/core/public/session.h>

int main(int argc, char **argv)
{
  using namespace tensorflow;
  Session* session;
  Status status = NewSession(SessionOptions(), &session);
  if (!status.ok()) { throw std::runtime_error(status.ToString()); }
  std::cout << "Session created successfully!" << std::endl;
  return 0;
}

/* EOF */
