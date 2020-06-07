# FunctionBarrier

[![Build Status](https://travis-ci.com/AStupidBear/FunctionBarrier.jl.svg?branch=master)](https://travis-ci.com/AStupidBear/FunctionBarrier.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/AStupidBear/FunctionBarrier.jl?svg=true)](https://ci.appveyor.com/project/AStupidBear/FunctionBarrier-jl)
[![Coverage](https://codecov.io/gh/AStupidBear/FunctionBarrier.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/AStupidBear/FunctionBarrier.jl)

## Usage

```julia
a, b = 1, 2
@macroexpand @barrier begin
    c = a + b
    d = c + 1
    c, d
end
```

is equivalent to

```julia
a, b = 1, 2
function var"##422"(a, b)
    c = a + b
    d = c + 1
    (c, d)
end
(c, d) = var"##422"(a, b)
```