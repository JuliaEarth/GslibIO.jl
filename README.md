# GslibIO.jl

Utilities to read/write *extended* and *legacy*
[GSLIB](http://www.gslib.com/gslib_help/format.html)
files in Julia.

[![Build Status](https://img.shields.io/github/workflow/status/JuliaEarth/GslibIO.jl/CI)](https://github.com/JuliaEarth/GslibIO.jl/actions)
[![Coverage Status](https://codecov.io/gh/JuliaEarth/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaEarth/GslibIO.jl)

## Overview

The GSLIB file format was introduced a long time ago for storing spatial
data over regular grids or point sets in text files that are easy to read.

The format specification is incomplete in both cases:

### Regular grids

- it doesn't contain the size of the grid (i.e. `(nx, ny, nz)`)
- it doesn't specify the origin and spacing (i.e. `(ox, oy, oz)`, `(sx, sy, sz)`)
- it doesn't specify the special symbol for inactive cells (e.g. `-999`)

### Point sets

- it doesn't specify which variable names are geospatial coordinates

This package introduces an extended GSLIB format that addresses the issues
listed above.

## Installation

Get the latest stable release with Julia's package manager:

```julia
] add GslibIO
```

## Usage

This package follows Julia's
[FileIO](https://github.com/JuliaIO/FileIO.jl) interface, it provides two
functions `save` and `load` for the *extended* GSLIB file format and two
functions `save_legacy` and `load_legacy` for the *legacy* GSLIB file format. Please consult the docstring of each function for more information.

A usual workflow consists of loading a legacy file with `load_legacy`
by setting the options manually, and then saving the data back to disk
in extended format with `save`. The new extended format can then be
loaded without any human intervention.

## Extended format

### Regular grids

Below is the extended format for spatial data over regular grids:

```
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

Inactive cells are marked with the special symbol `NaN`. This means that all properties are saved as floating point
numbers regardless of interpretation (categorical or continuous).
