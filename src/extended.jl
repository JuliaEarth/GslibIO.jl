# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENCE in the project root.
# ------------------------------------------------------------------

# type aliases
const Array2or3{T} = Union{AbstractArray{T,2},AbstractArray{T,3}}

"""
    load(file)

Load grid properties from `file`.
"""
function load(file::AbstractString)
  open(file) do f
    # skip header
    skipchars(_ -> false, f, linecomment='#')

    # read dimensions
    dims = parse.(Int, Tuple(split(readline(f))))
    orig = parse.(Float64, Tuple(split(readline(f))))
    spac = parse.(Float64, Tuple(split(readline(f))))

    # read property names
    vars = Symbol.(split(readline(f)))

    # read property values
    X = readdlm(f)

    # create data dictionary
    etable = (; zip(vars, eachcol(X))...)
    domain = CartesianGrid(dims, orig, spac)

    meshdata(domain, etable=etable)
  end
end

"""
    save(file, properties, dims; [optional parameters])

Save 1D `properties` to `file`, which originally had size `dims`.
"""
function save(
  file::AbstractString,
  properties::AbstractVector,
  dims::Dims{N};
  origin=ntuple(i -> 0.0, N),
  spacing=ntuple(i -> 1.0, N),
  header="",
  propnames=""
) where {N}
  # default property names
  isempty(propnames) && (propnames = ["prop$i" for i in 1:length(properties)])
  @assert length(propnames) == length(properties) "number of property names must match number of properties"

  # convert vector of names to a long string
  propnames = join(propnames, " ")

  # collect all properties in a big matrix
  P = reduce(hcat, properties)

  open(file, "w") do f
    # write header
    write(f, "# This file was generated with GslibIO.jl\n")
    !isempty(header) && write(f, "#\n# " * header * "\n")

    # write dimensions
    dimsstr = join([@sprintf "%i" i for i in dims], " ")
    origstr = join([@sprintf "%f" o for o in origin], " ")
    spacstr = join([@sprintf "%f" s for s in spacing], " ")
    write(f, dimsstr * "\n" * origstr * "\n" * spacstr * "\n")

    # write property name and values
    write(f, "$propnames\n")
    writedlm(f, P, ' ')
  end
end

"""
    save(file, properties, [optional parameters])

Save 2D/3D `properties` by first flattening them into 1D properties.
"""
function save(file::AbstractString, properties::Vector{A}; kwargs...) where {T,A<:Array2or3{T}}
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
save(file::AbstractString, property::A; kwargs...) where {T,A<:Array2or3{T}} = save(file, [property]; kwargs...)

"""
    save(file, data)

Save spatial `data` with `CartesianGrid` domain to `file`.
"""
function save(file::AbstractString, data::Data)
  grid = domain(data)
  table = values(data)
  cols = Tables.columns(table)
  vars = Tables.columnnames(cols)
  save(file, collect(cols), size(grid), origin=coordinates(minimum((grid))), spacing=spacing(grid), propnames=vars)
end
