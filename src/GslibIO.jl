# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

module GslibIO

using FileIO
using Printf
using DelimitedFiles

using GeoStatsBase

# type aliases
const Array2or3{T} = Union{AbstractArray{T,2},AbstractArray{T,3}}

# legacy specification of the GSLIB format
# (see documentation here: http://www.gslib.com/gslib_help/format.html)
struct LegacySpec
  header::String           # Content of the first line (documentation only)
  nvars::Int               # An integer with the number of variables (first integer in the second line)
  varnames::Vector{Symbol} # The variable names as Symbol in the following `nvars` lines
end

"""
    load(file)

Load grid properties from `file`.
"""
function load(file::File{format"GSLIB"})
  open(file) do f
    fs = stream(f)

    # skip header
    skipchars(_ -> false, fs, linecomment='#')

    # read dimensions
    dims = parse.(Int,     Tuple(split(readline(fs))))
    orig = parse.(Float64, Tuple(split(readline(fs))))
    spac = parse.(Float64, Tuple(split(readline(fs))))

    # read property names
    vars = Symbol.(split(readline(fs)))

    # read property values
    X = readdlm(fs)

    # create data dictionary
    data = (; zip(vars, eachcol(X))...)
    domain = RegularGrid(dims, orig, spac)

    georef(data, domain)
  end
end

# helper function to parse a legacy GSLIB file
function parse_legacy(filename::AbstractString)
  open(filename) do fs
    header = readline(fs)
    # the second line contains the number of variables (the first integer)
    # and it may contain extra info (comments), which will be ignored
    linesplit = split(readline(fs))
    nvars = parse(Int, linesplit[1])
    varnames = [Symbol(strip(readline(fs))) for i in 1:nvars]

    metadata = LegacySpec(header, nvars, varnames)

    # read data
    data = readdlm(fs)

    metadata, data
  end
end

"""
    load_legacy(filename, dims; origin=(0.,0.,0.), spacing=(1.,1.,1.), na=-999)

Load legacy GSLIB `filename` into a grid with `dims`, `origin` and `spacing`.
Optionally set the value used for missings `na`.
"""
function load_legacy(filename::AbstractString, dims::NTuple{3,Int};
                     origin=(0.,0.,0.), spacing=(1.,1.,1.), na=-999)
  metadata, data = parse_legacy(filename)                     

  # handle missing values
  replace!(data, na=>NaN)

  # create data dictionary
  table = (; zip(metadata.varnames, eachcol(data))...)
  domain = RegularGrid(dims, origin, spacing)

  georef(table, domain)

end

"""
    load_legacy(filename, coordnames, na=-999)

Load legacy GSLIB `filename` into a PointSet using the properties in `coordnames` as coordinates.
Optionally set the value used for missings `na`.
"""
function load_legacy(filename::AbstractString, coordnames=(:x, :y, :z); na=-999)
  metadata, data = parse_legacy(filename)

  # handle missing values
  replace!(data, na=>NaN)

  # create temporary data dictionary to split later
  # coordinates and attributes
  tableall = Dict(zip(metadata.varnames, eachcol(data)))

  # create data for coordinates
  coords = transpose(reduce(hcat, [tableall[c] for c in coordnames]))
  # create table with varnames not in coordnames
  attrnames = [c for c in metadata.varnames if c ∉  coordnames]
  table = (; zip(attrnames, [tableall[c] for c in attrnames])...)

  georef(table, PointSet(coords))
end

"""
    save(file, properties, dims; [optional parameters])

Save 1D `properties` to `file`, which originally had size `dims`.
"""
function save(file::File{format"GSLIB"},
              properties::AbstractVector, dims::Dims{N};
              origin=ntuple(i->0.0,N), spacing=ntuple(i->1.0,N),
              header="", propnames="") where {N}
  # default property names
  isempty(propnames) && (propnames = ["prop$i" for i=1:length(properties)])
  @assert length(propnames) == length(properties) "number of property names must match number of properties"

  # convert vector of names to a long string
  propnames = join(propnames, " ")

  # collect all properties in a big matrix
  P = reduce(hcat, properties)

  open(file, "w") do f
    # write header
    write(f, "# This file was generated with GslibIO.jl\n")
    !isempty(header) && write(f, "#\n# "*header*"\n")

    # write dimensions
    dimsstr = join([@sprintf "%i" i for i in dims], " ")
    origstr = join([@sprintf "%f" o for o in origin], " ")
    spacstr = join([@sprintf "%f" s for s in spacing], " ")
    write(f, dimsstr*"\n"*origstr*"\n"*spacstr*"\n")

    # write property name and values
    write(f, "$propnames\n")
    writedlm(stream(f), P, ' ')
  end
end

"""
    save(file, properties, [optional parameters])

Save 2D/3D `properties` by first flattening them into 1D properties.
"""
function save(file::File{format"GSLIB"}, properties::Vector{A};
              kwargs...) where {T,A<:Array2or3{T}}
  # sanity checks
  @assert length(Set(size.(properties))) == 1 "properties must have the same size"

  # retrieve grid size
  dims = size(properties[1])

  # flatten and proceed with pipeline
  flatprops = [vec(prop) for prop in properties]

  save(file, flatprops, dims, kwargs...)
end

"""
    save(file, property)

Save single 2D/3D `property` by wrapping it into a singleton collection.
"""
function save(file::File{format"GSLIB"},
              property::A; kwargs...) where {T,A<:Array2or3{T}}
  save(file, [property]; kwargs...)
end

"""
    save(file, sdata)

Save spatial data `sdata` with `RegularGrid` domain to `file`.
"""
function save(file::File{format"GSLIB"}, sdata::AbstractData)
  vars  = name.(variables(sdata))
  grid  = domain(sdata)
  table = values(sdata)
  save(file, collect(eachcol(table)), size(grid),
       origin=origin(grid), spacing=spacing(grid),
       propnames=vars)
end

end
