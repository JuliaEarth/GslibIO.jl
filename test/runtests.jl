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

    prop1 = rand(10,10,10)
    prop2 = rand(10,10,10)

    save(fname, [prop1,prop2])
    grid = load(fname)
    @test grid[:prop1] == prop1
    @test grid[:prop2] == prop2

    save(fname, grid)
    grid = load(fname)
    @test grid[:prop1] == prop1
    @test grid[:prop2] == prop2

    save(fname, prop1)
    grid = load(fname)
    @test grid[:prop1] == prop1

    rm(fname)
  end

  @testset "Legacy" begin
    fname = joinpath(datadir,"legacy.gslib")

    grid = GslibIO.load_legacy(fname, (2,2,2))
    @test size(grid) == (2,2,2)
    @test origin(grid) == [0.,0.,0.]
    @test spacing(grid) == [1.,1.,1.]
    @test vec(grid[:Porosity]) == [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8]
    @test vec(grid[:Lithology]) == [1,2,3,4,5,6,7,8]
    @test vec(grid[Symbol("Water Saturation")]) == [0.8,0.7,0.8,0.7,0.8,0.7,0.8,0.7]
  end
end
