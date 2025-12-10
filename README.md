# GslibIO.jl

Load/save *extended* and *legacy*
[GSLIB](http://www.gslib.com/gslib_help/format.html)
files in Julia.

[![Build Status](https://img.shields.io/github/actions/workflow/status/JuliaEarth/GslibIO.jl/CI.yml?branch=master&style=flat-square")](https://github.com/JuliaEarth/GslibIO.jl/actions)
[![Coverage Status](https://codecov.io/gh/JuliaEarth/GslibIO.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaEarth/GslibIO.jl)

## Overview

The GSLIB file format was introduced a long time ago for storing geospatial
data over Cartesian grids or point sets in text files that are easy to read.
Unfortantely, the format specification is incomplete:

### Cartesian grids

- it doesn't contain the size of the grid (i.e. `(nx, ny, nz)`)
- it doesn't specify the origin and spacing (i.e. `(ox, oy, oz)`, `(sx, sy, sz)`)
- it doesn't specify the special symbol for inactive cells (e.g. `-999`)

### Point sets

- it doesn't specify which variable names are geospatial coordinates

This package introduces an extended GSLIB format that addresses these issues.
It also provides helper functions to load data in legacy format.

## Installation

Get the latest stable release with Julia's package manager:

```
] add GslibIO
```

## Usage

Please use `save` and `load` for the *extended* GSLIB file format and
`save_legacy` and `load_legacy` for the *legacy* GSLIB file format.
Consult the docstring of each function for more information.

An usual workflow consists of loading a legacy file with `load_legacy`
by setting the options manually, and then saving the data back to disk
in extended format with `save`. The new extended format can then be
loaded without human intervention.

```julia
using GslibIO

# load grid data stored in legacy format
data = GslibIO.load_legacy("legacy.gslib", (100,100,50), na=-999)

# save grid data in new extended format
GslibIO.save("extended.gslib", data)

# now it can be loaded without special options
GslibIO.load("extended.gslib")
```
