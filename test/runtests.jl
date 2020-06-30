using FileIO
using GslibIO
using GeoStatsBase
using Test

# environment settings
islinux = Sys.islinux()
istravis = "TRAVIS" ∈ keys(ENV)
datadir = joinpath(@__DIR__,"data")

@testset "GslibIO.jl" begin
  @testset "Basic" begin
    fname = tempname()*".gslib"

    props3D = rand(10,10,10), rand(10,10,10)
    props2D = rand(10,10), rand(10,10)

    for (prop1, prop2) in [props2D, props3D]
      save(fname, [prop1,prop2])
      grid = load(fname)
      @test grid[:prop1] == vec(prop1)
      @test grid[:prop2] == vec(prop2)

      save(fname, grid)
      grid = load(fname)
      @test grid[:prop1] == vec(prop1)
      @test grid[:prop2] == vec(prop2)

      save(fname, prop1)
      grid = load(fname)
      @test grid[:prop1] == vec(prop1)
    end

    rm(fname)
  end

  @testset "Legacy" begin
    fname = joinpath(datadir,"legacy.gslib")

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
end
