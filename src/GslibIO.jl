__precompile__(true)

module GslibIO

using FileIO

"""
    GslibGRID

Type holding all necessary information for saving/loading properties.
"""
struct GslibGRID{T<:AbstractFloat,A<:AbstractArray{T,3}}
  properties::Vector{A}
  propnames::Vector{String}
  origin::NTuple{3,T}
  spacing::NTuple{3,T}
end

"""
    load(file)

Load grid properties from `file`.
"""
function load(file::File{format"GSLIB"})
  f = open(file)
  fs = stream(f)

  # skip header
  skipchars(fs, _ -> false, linecomment='#')

  # read dimensions
  nx, ny, nz = split(readline(fs))
  ox, oy, oz = split(readline(fs))
  dx, dy, dz = split(readline(fs))
  nx, ny, nz = map(s -> parse(Int, s), [nx,ny,nz])
  ox, oy, oz = map(s -> parse(Float64, s), [ox,oy,oz])
  dx, dy, dz = map(s -> parse(Float64, s), [dx,dy,dz])

  # read property names
  propnames = String.(split(readline(fs)))

  # read property values
  P = readdlm(fs)

  close(f)

  # reshape properties to grid size
  properties = [reshape(P[:,j], nx, ny, nz) for j=1:size(P,2)]

  GslibGRID(properties, propnames, (ox,oy,oz), (dx,dy,dz))
end

"""
    save(file, properties, propsize; [optional parameters])

Save 1D `properties`, which originally had 3D size `propsize`.
"""
function save(file::File{format"GSLIB"},
              properties::Vector{V}, propsize::Tuple;
              origin=(0.,0.,0.), spacing=(1.,1.,1.),
              header="", propnames="") where {T<:AbstractFloat,V<:AbstractArray{T,1}}
  # default property names
  isempty(propnames) && (propnames = ["prop$i" for i=1:length(properties)])
  @assert length(propnames) == length(properties) "number of property names must match number of properties"

  # convert vector of names to a long string
  propnames = join(propnames, " ")

  # collect all properties in a big matrix
  P = hcat(properties...)

  open(file, "w") do f
    # write header
    write(f, "# This file was generated with GslibIO.jl\n")
    !isempty(header) && write(f, "#\n# "*header*"\n")

    # write dimensions
    write(f, @sprintf("%i %i %i\n", propsize...))
    write(f, @sprintf("%f %f %f\n", origin...))
    write(f, @sprintf("%f %f %f\n", spacing...))

    # write property name and values
    write(f, "$propnames\n")
    writedlm(stream(f), P, ' ')
  end
end

"""
    save(file, properties, [optional parameters])

Save 3D `properties` by first flattening them into 1D properties.
"""
function save(file::File{format"GSLIB"}, properties::Vector{A};
              kwargs...) where {T<:AbstractFloat,A<:AbstractArray{T,3}}
  # sanity checks
  @assert length(Set(size.(properties))) == 1 "properties must have the same size"

  # retrieve grid size
  propsize = size(properties[1])

  # flatten and proceed with pipeline
  flatprops = [prop[:] for prop in properties]

  save(file, flatprops, propsize, kwargs...)
end

"""
    save(file, property)

Save single 3D `property` by wrapping it into a singleton collection.
"""
function save(file::File{format"GSLIB"},
              property::A; kwargs...) where {T<:AbstractFloat,A<:AbstractArray{T,3}}
  save(file, [property]; kwargs...)
end

end
