GslibIO.jl
==========

Utilities to read/write [GSLIB](http://www.gslib.com/gslib_help/format.html) files in Julia.

[![Build Status](https://travis-ci.org/juliohm/GslibIO.jl.svg?branch=master)](https://travis-ci.org/juliohm/GslibIO.jl)
[![Coverage Status](https://codecov.io/gh/juliohm/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/juliohm/GslibIO.jl)

Installation
------------

```julia
Pkg.clone("https://github.com/SCRFMembers/GslibIO.jl.git")
```

Usage
-----

```julia
using FileIO

A = rand(10,10,10)

# save grid to file
save("realization.gslib", A)

# read grid from file
grid = load("real.gslib")

# array, origin and spacing
B = grid.array
origin = grid.origin
spacing = grid.spacing

@assert A == B
```
