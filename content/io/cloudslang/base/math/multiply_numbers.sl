#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
########################################################################################################
#!!
#! @description: Multiply two numbers as floating point values.
#! @input value1: first value as number or string
#! @input value2: second value as number or string
#! @result SUCCESS: always
#!!#
########################################################################################################
namespace: io.cloudslang.base.math

decision:
  name: multiply_numbers
  inputs:
    - value1
    - value2
  outputs:
    - result: ${float(value1) * float(value2)}
  results:
    - SUCCESS
