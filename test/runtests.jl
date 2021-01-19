using FileIO
using GslibIO
using GeoStatsBase
using Pkg, Test, Random

# environment settings
isCI = "CI" ∈ keys(ENV)
islinux = Sys.islinux()
visualtests = !isCI || (isCI && islinux)
if !isCI
  Pkg.add("Gtk")
  using Gtk
end
datadir = joinpath(@__DIR__,"data")

@testset "GslibIO.jl" begin
  @testset "Basic" begin
    fname = tempname()*".gslib"

    props3D = rand(10,10,10), rand(10,10,10)
    props2D = rand(10,10), rand(10,10)

    for (prop1, prop2) in [props2D, props3D]
      FileIO.save(fname, [prop1,prop2])
      grid = FileIO.load(fname)
      @test grid[:prop1] == vec(prop1)
      @test grid[:prop2] == vec(prop2)

      FileIO.save(fname, grid)
      grid = FileIO.load(fname)
      @test grid[:prop1] == vec(prop1)
      @test grid[:prop2] == vec(prop2)

      FileIO.save(fname, prop1)
      grid = FileIO.load(fname)
      @test grid[:prop1] == vec(prop1)
    end

    rm(fname)
  end

  @testset "LegacyGrid" begin
    fname = joinpath(datadir,"legacy_grid.gslib")

    sdata = GslibIO.load_legacy(fname, (2,2,2))
    @test size(domain(sdata)) == (2,2,2)
    @test origin(domain(sdata)) == [0.,0.,0.]
    @test spacing(domain(sdata)) == [1.,1.,1.]
    por = sdata[:Porosity]
    lit = sdata[:Lithology]
    sat = sdata[Symbol("Water Saturation")]
    @test isequal(por, [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8])
    @test isequal(lit, [1,2,3,4,5,6,7,8])
    @test isequal(sat, [0.8,0.7,0.8,0.7,0.8,0.7,0.8,NaN])
  end

  @testset "LegacyPointSet" begin
    fname = joinpath(datadir,"legacy_pset.gslib")

    coordnames = (:East, :North, :Elevation)
    sdata = GslibIO.load_legacy(fname, coordnames)
    cdata = coordinates(sdata)
    @test size(cdata) == (3, 4)
    @test nelms(sdata) == 4
    por = sdata[:Porosity]
    @test isequal(por, [0.1, 0.2, 0.3, 0.4])
    @test isequal(cdata[1, :], [10.0, 20.0, 30.0, 40.0])
    @test isequal(cdata[2, :], [11.0, 21.0, 31.0, 41.0])
    @test isequal(cdata[3, :], [12.0, 22.0, 32.0, 42.0])

    # test when coordnames are not in varnames
    coordnames = (:x, :y, :Elevation)
    @test_throws AssertionError GslibIO.load_legacy(fname, coordnames)
  end

  @testset "LegacyInvalid" begin
    fname = joinpath(datadir,"legacy_invalid.gslib")

    coordnames = (:x, :y, :z)
    @test_throws MethodError GslibIO.load_legacy(fname, coordnames)
  end

end
