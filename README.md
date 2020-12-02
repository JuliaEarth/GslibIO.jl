# GslibIO.jl

Utilities to read/write *legacy* and *extended* [GSLIB](http://www.gslib.com/gslib_help/format.html) files in Julia.

[![Build Status](https://travis-ci.org/JuliaEarth/GslibIO.jl.svg?branch=master)](https://travis-ci.org/JuliaEarth/GslibIO.jl)
[![Coverage Status](https://codecov.io/gh/JuliaEarth/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaEarth/GslibIO.jl)

## Introduction

The GSLIB file format was introduced a long time ago for storing scattered locations or regular grids in text files that are easy to read. The only difference between both is that regular grids do not need to include the coordinates
as they can be inferred from the grid specification, following the *Fortran* convention, i.e.,
the index i (x-axis) varies first, followed by j (y-axis) and finally by k (z-axis).

For scattered locations the format is simple: it has a first line with a header, in the second line a number that
specify how many variables there are in the file, termed `nvars`. The next `nvars` lines contain the name
of each variable. Finally, the raw data in a standard tabular format delimited by spaces.

The following example illustrates the GSLIB format for a scattered locations dataset of two samples of copper:

```text
Demo datafile with x, y, z and copper
4
x
y
z
cu
1.0 2.0 3.0 0.82
2.0 2.0 3.0 0.97
```

Unfortunately, the GSLIB format is not self-explained due to the following:

1. it does not specify which variables are the coordinates
1. it doesn't specify the special symbol for missing values (e.g. `-999`)

Similarly, the GSLIB format for a regular grid with 2 x 2 x 2 nodes of copper is as follows:

```text
Demo datafile with a 3D grid with copper
1 2 2 2
cu
0.82
0.97
0.12
0.24
0.67
1.20
2.50
1.98
```

In this case, as the file is a regular grid, the coordinates are not needed. The second line contains four
integers: the first one is the number of variables (*1*, which is copper) and three more with the number of nodes,
but that is optional and for documentation only.

For the case of regular grids, the format specification is incomplete mainly because:

1. it doesn't contain the size of the grid (i.e. `(nx, ny, nz)`)
1. it doesn't specify the origin and spacing (i.e. `(ox, oy, oz)`, `(sx, sy, sz)`)

This package also introduces an extended GSLIB format that addresses the issues listed above:

```text
# optional comment lines at the start of the file
# more comments ...
<nx> <ny> <nz>
<ox> <oy> <oz>
<sx> <sy> <sz>
<property_name1>   <property_name2> ...   <property_nameN>
<property_value11> <property_value12> ... <property_value1N>
<property_value21> <property_value22> ... <property_value2N>
...
<property_value(Nx*Ny*Nz)1> <property_value(Nx*Ny*Nz)2> ... <property_value(Nx*Ny*Nz)N>
```

Inactive cells are marked with the special symbol `NaN`. This means that all properties are saved as floating point numbers regardless of interpretation (categorical or continuous).

## Installation

Get the latest stable release with Julia's package manager:

```julia
] add GslibIO
```

## Usage

This package follows Julia's [FileIO](https://github.com/JuliaIO/FileIO.jl) interface, it provides two functions:

### save

```julia
using FileIO

# save 3D arrays to extended GSLIB file
save(filename, [array1, array2, ...])
save(filename, array) # version with single array
```
where the following saving options are available:

- `origin` is the origin of the grid (default to `(0.,0.,0.)`)
- `spacing` is the spacing of the grid (default to `(1.,1.,1.)`)
- `header` contains additional comments about the data
- `propnames` is the name of each property being saved (default to `prop1`, `prop2`, ...)

### load

```julia
using FileIO

# read arrays from GSLIB file
grid = load(filename)
```
where

- `filename` **must have** extension `.gslib` or `.sgems`
- `array1`, `array2`, ... are 2D/3D Julia arrays
- `grid` is a `RegularGridData` object

The user can retrieve specific properties of the grid using dictionarly-like
syntax (e.g. `grid[:prop1]`), and the available property names with `variables(grid)`.
For additional functionality, please consult the
[GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl) documentation.

## Legacy format

Additionally, this package provides a load/save function for legacy GSLIB files:

```julia
using GslibIO

grid = GslibIO.load_legacy("some_grid.gslib", dims=(100, 100, 100), na=-999)
scatter = GslibIO.load_legacy("some_scattered_data.gslib", coordnames=(:East, :North, :Elevation), na=-999)

GslibIO.save_legacy("some_grid.gslib", grid, na=-999)
GslibIO.save_legacy("some_scattered_data.gslib", scatter, coordnames=(:east, :north, :elevation), na=-999)
```
