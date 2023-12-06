# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

# utility functions
nextline(io) = strip(readline(io))

function genpvars(Dim, vars)
  pvars = if Dim == 1
    [:x]
  elseif Dim == 2
    [:x, :y]
  else
    [:x, :y, :z]
  end

  # make unique
  map(pvars) do var
    while var ∈ vars
      var = Symbol(var, :_)
    end
    var
  end
end

# constants
const DOMTYPES = ["grid", "pset"]
const HEADER = "This file was generated with GslibIO.jl"

"""
    GslibIO.load(file)

Loads a geotable from GSLIB extended format.
"""
function load(file::AbstractString)
  open(file) do io
    # skip header
    readline(io)

    # domain type
    domtype = nextline(io)
    @assert domtype ∈ DOMTYPES "invalid domain type"

    # load data
    if domtype == "grid"
      _load_grid(io)
    else
      _load_pset(io)
    end
  end
end

function _load_grid(io::IO)
  # read domain parameters
  dims = Tuple(parse.(Int, eachsplit(nextline(io))))
  origin = Tuple(parse.(Float64, eachsplit(nextline(io))))
  spacing = Tuple(parse.(Float64, eachsplit(nextline(io))))

  # read variable count
  nvars = parse(Int, nextline(io))

  # read variable names
  vars = map(i -> Symbol(nextline(io)), 1:nvars)

  # read variable values
  X = readdlm(io)

  # create data table
  values = (; zip(vars, eachcol(X))...)
  domain = CartesianGrid(dims, origin, spacing)
  georef(values, domain)
end

function _load_pset(io::IO)
  # read variable count and point variables
  nvars = 0
  pvars = Symbol[]
  while true
    line = nextline(io)
    if all(isdigit, line)
      nvars = parse(Int, line)
      break
    end
    push!(pvars, Symbol(line))
  end

  # read variable names
  vars = map(i -> Symbol(nextline(io)), 1:nvars)

  # read variable values
  X = readdlm(io)

  # create data table
  data = Dict(zip(vars, eachcol(X)))
  points = map(Point, (data[v] for v in pvars)...)
  values = (; (v => data[v] for v in setdiff(vars, pvars))...)
  domain = PointSet(points)
  georef(values, domain)
end

"""
    GslibIO.save(file, geotable; pointvars, header)
    GslibIO.save(file, table, domain; pointvars, header)

Saves the `geotable` or `table` with `domain` to `file` using the GSLIB extended format.
As the GSLIB format only supports `CartesianGrid` and `PointSet`,
other domain types will be converted to `PointSet`.

It is possible to define how the point coordinate variables will be saved 
by passing a list of names (e.g. vector of strings or symbols) to the `pointvars` keyword argument,
otherwise the names "x", "y" and "z" will be used.

Use the `header` keyword argument to define the title of the GSLIB file,
if omitted the following default title will be used: 
"This file was generated with GslibIO.jl".
"""
save(file::AbstractString, geotable::AbstractGeoTable; kwargs...) =
  save(file, values(geotable), domain(geotable); kwargs...)

function save(file::AbstractString, table, domain::Domain; pointvars=nothing, header=HEADER)
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  Dim = embeddim(domain)

  if Dim > 3
    throw(ArgumentError("embedding dimensions greater than 3 are not supported"))
  end

  pvars = if isnothing(pointvars)
    genpvars(Dim, vars)
  else
    if length(pointvars) ≠ Dim
      throw(ArgumentError("the length of `pointvars` must be equal to $Dim (embedding dimension)"))
    end
    pointvars
  end

  data = Tables.matrix(table)
  pdata = mapreduce(g -> coordinates(centroid(g)), hcat, domain) |> transpose

  open(file; write=true) do io
    write(io, "$header\n")
    write(io, "pset\n")
    for var in pvars
      write(io, "$var\n")
    end
    nvars = length(pvars) + length(vars)
    write(io, "$nvars\n")
    for var in pvars
      write(io, "$var\n")
    end
    for var in vars
      write(io, "$var\n")
    end
    writedlm(io, [pdata data])
  end
end

function save(file::AbstractString, table, grid::CartesianGrid; header=HEADER, kwargs...)
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  data = Tables.matrix(table)

  open(file; write=true) do io
    write(io, "$header\n")
    write(io, "grid\n")
    write(io, join(size(grid), " ") * "\n")
    write(io, join(coordinates(minimum(grid)), " ") * "\n")
    write(io, join(spacing(grid), " ") * "\n")
    nvars = length(vars)
    write(io, "$nvars\n")
    for var in vars
      write(io, "$var\n")
    end
    writedlm(io, data)
  end
end
