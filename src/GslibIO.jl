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

# Legacy specification of the GSLIB format: http://www.gslib.com/gslib_help/format.html
# Note that in this context variables can be actual attributes as well as names of coordinates
struct LegacySpec
  header::String           # first line is a header in free format
  varnames::Vector{Symbol} # variable names, one per line
  data::Matrix{Float64}    # data matrix with variables as columns
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
    # first line is a free header
    header = readline(fs)

    # the second line contains the number of variables (the first integer)
    # and it may contain extra info (comments), which will be ignored
    words = split(readline(fs))
    nvars = parse(Int, words[1])
    varnames = [Symbol(strip(readline(fs))) for i in 1:nvars]

    # read remaning content as data
    data = readdlm(fs)

    LegacySpec(header, varnames, data)
  end
end

"""
    load_legacy(filename, dims; origin=(0.,0.,0.), spacing=(1.,1.,1.), na=-999)

Load legacy GSLIB `filename` into a grid with `dims`, `origin` and `spacing`.
Optionally set the value used for missings `na`.
"""
function load_legacy(filename::AbstractString, dims::NTuple{3,Int};
                     origin=(0.,0.,0.), spacing=(1.,1.,1.), na=-999)
  spec = parse_legacy(filename)                     

  # handle missing values
  replace!(spec.data, na=>NaN)

  # create data dictionary
  table = (; zip(spec.varnames, eachcol(spec.data))...)
  domain = RegularGrid(dims, origin, spacing)

  georef(table, domain)
end

"""
    load_legacy(filename, coordnames, na=-999)

Load legacy GSLIB `filename` into a PointSet using the properties in `coordnames` as coordinates.
Optionally set the value used for missings `na`.
"""
function load_legacy(filename::AbstractString, coordnames=(:x, :y, :z); na=-999)
  spec = parse_legacy(filename)

  @assert issubset(coordnames, spec.varnames) "invalid coordinate names"

  # handle missing values
  replace!(spec.data, na=>NaN)

  # we need to identify and separate coordinates and actual attributes
  coordinds = indexin(collect(coordnames), spec.varnames)
  if any(isnothing.(coordinds))
      @error "Some coordinate names could not be found in the file"
  end
  coords = spec.data[:,coordinds]'

  # create table with varnames not in coordnames
  attrinds = setdiff(1:length(spec.varnames), coordinds)
  attrnames = spec.varnames[attrinds]
  table = (; zip(attrnames, eachcol(spec.data[:,attrinds]))...)

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

# low level function for saving `data` to a legacy GSLIB format using `varnames` as variable names
function save_legacy(filename::AbstractString, data::AbstractMatrix, varnames::NTuple; 
                     na=-999.0, header="# This file was generated with GslibIO.jl")
  @assert size(data, 2) == length(varnames) "Invalid data for the specified variable names"
  nvars = size(data, 2)

  open(filename, "w") do f
    write(f, "$header\n")

    write(f, "$nvars\n")
    for v in varnames
      write(f, "$v\n")
    end

    # handle missing values
    replace!(data, NaN=>na)

    writedlm(f, data, ' ')
  end
end

"""
    save_legacy(file, sdata)

Save spatial data `sdata` to `filename` using standard GSLIB format. It replaces NaNs with `na` values
and it uses `coordnames` as the given variable name to coordinates
"""
function save_legacy(filename::AbstractString, sdata::SpatialData; coordnames=(:x, :y, :z), na=-999.0)
  table = values(sdata)
  sdomain = domain(sdata)
  
  if isa(sdomain, PointSet) 
    # add `coordinates` to data and `coordnames` to `varnames`
    coords = coordinates(sdomain)
    cdim = size(coords, 1)
    @assert cdim <= length(coordnames) "The length of coordinate names must be equal or greater than the coordinate dimension"

    varnames = cat([String(v) for v in coordnames[1:cdim]], names(table), dims=1)
    data = hcat(transpose(coords), Array(table))
  elseif isa(sdomain, RegularGrid)
    # a regular grid does not need to save coordinates
    varnames = names(table)
    data = Matrix(table)
  else
    error("Only PointSet and RegularGrid can be saved to the legacy GSLIB format")
  end  

  save_legacy(filename, data, varnames, na=na)
end

# This variant converts `varnames` from an Array to NTuple
save_legacy(filename::AbstractString, data::AbstractMatrix, varnames::AbstractArray; na=-999.0) =
    save_legacy(filename, data, NTuple{size(varnames, 1)}(Symbol.(varnames)), na=na)

end
