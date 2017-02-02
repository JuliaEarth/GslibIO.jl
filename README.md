GslibIO.jl
==========

Utilities to read/write *extended* [GSLIB](http://www.gslib.com/gslib_help/format.html) files in Julia.

[![Build Status](https://travis-ci.org/juliohm/GslibIO.jl.svg?branch=master)](https://travis-ci.org/juliohm/GslibIO.jl)
[![Coverage Status](https://codecov.io/gh/juliohm/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/juliohm/GslibIO.jl)

Installation
------------

```julia
Pkg.add("GslibIO")
```

Usage
-----

This package follows Julia's [FileIO](https://github.com/JuliaIO/FileIO.jl) interface, it provides two functions:

```julia
using FileIO

# save 3D array to GSLIB file
save(filename, array)

# read 3D array from GSLIB file
gridobj = load(filename)
```
where `filename` **must have** extension `.gslib` or `.sgems`, `array` is a 3D Julia array and `gridobj` is an object that holds the array of properties (i.e. `gridobj.array`) and other parameters of the grid. Additional saving options are available:

- `origin` is the origin of the grid (default to `(0.,0.,0.)`)
- `spacing` is the spacing of the grid (default to `(1.,1.,1.)`)
- `header` contains additional comments about the data
- `propname` is the name of the property being saved
