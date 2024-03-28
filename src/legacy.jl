# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

# Legacy specification of the GSLIB format: http://www.gslib.com/gslib_help/format.html
# Note that in this context variables can be actual attributes as well as names of coordinates
struct LegacySpec
  header::String           # first line is a header in free format
  varnames::Vector{Symbol} # variable names, one per line
  data::Matrix{Float64}    # data matrix with variables as columns
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

    # variable names, one per line
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
function load_legacy(
  filename::AbstractString,
  dims::NTuple{3,Int};
  origin=(0.0, 0.0, 0.0),
  spacing=(1.0, 1.0, 1.0),
  na=-999
)
  spec = parse_legacy(filename)

  # handle missing values
  replace!(spec.data, na => NaN)

  # create table and domain
  table = (; zip(spec.varnames, eachcol(spec.data))...)
  domain = CartesianGrid(dims, origin, spacing)

  georef(table, domain)
end

"""
    load_legacy(filename, coordnames, na=-999)

Load legacy GSLIB `filename` into a point set using the properties in
`coordnames` as coordinates. Optionally set the value used for missings `na`.
"""
function load_legacy(filename::AbstractString, coordnames=[:x, :y, :z]; na=-999)
  spec = parse_legacy(filename)

  if isempty(coordnames) || coordnames ⊈ spec.varnames
    throw(ArgumentError("invalid coordinate names"))
  end

  # handle missing values
  replace!(spec.data, na => NaN)

  # create table
  table = (; zip(spec.varnames, eachcol(spec.data))...)

  georef(table, coordnames)
end

# low level function for saving data to a legacy GSLIB format
function save_legacy(filename::AbstractString, data::AbstractMatrix, varnames::NTuple, header::AbstractString, na)
  if size(data, 2) ≠ length(varnames)
    throw(ArgumentError("invalid data for the specified variable names"))
  end
  nvars = size(data, 2)

  # handle missing values
  datana = replace(data, NaN => na)

  open(filename, "w") do f
    write(f, "$header\n")
    write(f, "$nvars\n")
    for v in varnames
      write(f, "$v\n")
    end
    writedlm(f, datana, ' ')
  end
end

"""
    save_legacy(filename, data; coordnames=(:x,:y,:z), header="...", na=-999.0)

Save spatial `data` to `filename` in legacy GSLIB format. Optionally, specify the
`coordnames`, the `header` and the value `na` used to represent missing entries.
"""
function save_legacy(
  filename::AbstractString,
  geotable::AbstractGeoTable;
  coordnames=(:x, :y, :z),
  header="# This file was generated with GslibIO.jl",
  na=-999.0
)
  dom = domain(geotable)
  tab = values(geotable)

  if dom isa PointSet
    # add coordinates to data and coordnames to varnames
    if embeddim(dom) ≠ length(coordnames)
      throw(ArgumentError("the length of coordinate names must be equal to the coordinate dimension"))
    end
    varnames = [coordnames...; propertynames(tab)...]
    xs = (coordinates(centroid(dom, i)) for i in 1:nelements(dom))
    X = reduce(hcat, xs)'
    V = Tables.matrix(tab)
    matrix = [X V]
  elseif dom isa CartesianGrid
    # a regular grid does not need to save coordinates
    varnames = propertynames(tab)
    matrix = Tables.matrix(tab)
  else
    @error "can only save data defined on point sets or regular grids"
  end

  save_legacy(filename, matrix, Tuple(varnames), header, na)
end
