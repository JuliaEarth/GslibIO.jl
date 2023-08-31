# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

# utility functions
nextline(io) = strip(readline(io))
genpvars(dom) = ["x$i" for i in 1:embeddim(dom)]

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
  etable = (; zip(vars, eachcol(X))...)
  domain = CartesianGrid(dims, origin, spacing)
  meshdata(domain; etable)
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
  etable = (; (v => data[v] for v in setdiff(vars, pvars))...)
  domain = PointSet(points)
  meshdata(domain; etable)
end

"""
    GslibIO.save(file, geotable; pointvars=nothing, header=nothing)
    GslibIO.save(file, table, domain; pointvars=nothing, header=nothing)

Saves the `geotable` or `table` with `domain` to `file` using the GSLIB extended format.
As the GSLIB format only supports `CartesianGrid` and `PointSet`,
other domain types will be converted to `PointSet`.

It is possible to define how the point coordinate variables will be saved 
by passing a list of names (e.g. vector of strings) to the `pointvars` keyword argument,
otherwise the names "x1", "x2", ..., "xn" will be used.

Use the `header` keyword argument to define the title of the GSLIB file,
if omitted the following default title will be used: 
"This file was generated with GslibIO.jl".
"""
save(file::AbstractString, geotable::Data; kwargs...) = save(file, values(geotable), domain(geotable); kwargs...)

function save(file::AbstractString, table, domain::Domain; pointvars=nothing, header=nothing)
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  data = Tables.matrix(table)
  pvars = isnothing(pointvars) ? genpvars(domain) : pointvars
  pdata = mapreduce(g -> coordinates(centroid(g)), hcat, domain) |> transpose

  open(file; write=true) do io
    h = isnothing(header) ? HEADER : header
    write(io, "$h\n")
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

function save(file::AbstractString, table, grid::CartesianGrid; header=nothing, kwargs...)
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  data = Tables.matrix(table)

  open(file; write=true) do io
    h = isnothing(header) ? HEADER : header
    write(io, "$h\n")
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
