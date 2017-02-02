__precompile__(true)

module GslibIO

using FileIO

immutable GslibGRID{T<:AbstractFloat}
  array::AbstractArray{T,3}
  origin::NTuple{3,T}
  spacing::NTuple{3,T}
end

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

  # skip property name
  readline(fs)

  # read property values
  array = reshape(readdlm(fs), nx, ny, nz)

  close(f)

  GslibGRID(array, (ox,oy,oz), (dx,dy,dz))
end

function save{T<:AbstractFloat}(file::File{format"GSLIB"}, array::AbstractArray{T,3};
                                ox=0., oy=0., oz=0., dx=1., dy=1., dz=1.,
                                header="", propname="property")
  open(file, "w") do f
    # write header
    write(f, "# This file was generated with GslibIO.jl\n")
    !isempty(header) && write(f, "#\n# "*header*"\n")

    # write dimensions
    write(f, @sprintf("%i %i %i\n", size(array)...))
    write(f, @sprintf("%f %f %f\n", ox, oy, oz))
    write(f, @sprintf("%f %f %f\n", dx, dy, dz))

    # write property name and values
    write(f, "$propname\n")
    writedlm(stream(f), array[:])
  end
end

end
