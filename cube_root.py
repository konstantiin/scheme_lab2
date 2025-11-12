import math
import numpy

def cube_alg(x):
    return math.floor(numpy.cbrt(x))

def cube_hw(x):
    y = 0
    for s in range(30, -3, -3):
        y = 2*y
        b = (3*y*(y + 1) + 1) << s
        if (x >= b):
            x = x - b
            y = y + 1
    return y

# Test
for x in range(0, 5, 1):
    a = pow(x, 3)
    alg_val = cube_alg(a)
    hw_val = cube_hw(a)
    if (alg_val == hw_val):
        print("Correct! x: ", str(a).ljust(6), "; y: ", str(hw_val).ljust(6))
    else:
        print("ERROR! x: ", str(a).ljust(6), "; y(model): ", str(alg_val).ljust(6), "; y(hw): ", hex(hw_val).ljust(6))