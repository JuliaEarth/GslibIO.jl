using FileIO
using GslibIO
using GeoStatsBase
using Test

# environment settings
islinux = Sys.islinux()
istravis = "TRAVIS" ∈ keys(ENV)
datadir = joinpath(@__DIR__, "data")

@testset "GslibIO.jl" begin
  @testset "Basic" begin
    fname = tempname()*".gslib"

    props3D = rand(10, 10, 10), rand(10, 10, 10)
    props2D = rand(10, 10), rand(10, 10)

    for (prop1, prop2) in [props2D, props3D]
      save(fname, [prop1, prop2])
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
    fname = joinpath(datadir, "legacy_grid.gslib")

    sdata_grid = GslibIO.load_legacy(fname, (2, 2, 2))
    @test size(domain(sdata_grid)) == (2, 2, 2)
    @test origin(domain(sdata_grid)) == [0., 0., 0.]
    @test spacing(domain(sdata_grid)) == [1., 1., 1.]
    por = sdata_grid[:Porosity]
    lit = sdata_grid[:Lithology]
    sat = sdata_grid[Symbol("Water Saturation")]
    @test isequal(por, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
    @test isequal(lit, [1, 2, 3, 4, 5, 6, 7, 8])
    @test isequal(sat, [0.8, 0.7, 0.8, 0.7, 0.8, 0.7, 0.8, NaN])

    fname = joinpath(datadir,"legacy_scatter.gslib")

    sdata_scattered = GslibIO.load_legacy(fname, (:East, :North, :Elevation))
    cdata = coordinates(sdata_scattered)
    @test nelms(sdata_scattered) == 3
    por = sdata_scattered[:Porosity]
    @test isequal(por, [0.1, 0.2, 0.3])
    @test isequal(cdata[1, :], [10.0, 20.0, 30.0])
    @test isequal(cdata[2, :], [11.0, 21.0, 31.0])
    @test isequal(cdata[3, :], [12.0, 22.0, 32.0])

    # save/load them back
    fname = tempname()*".gslib"

    GslibIO.save_legacy(fname, sdata_grid)
    grid  = GslibIO.load_legacy(fname, (2, 2, 2))

    @test size(domain(sdata_grid)) == size(domain(grid))
    @test origin(domain(sdata_grid)) == origin(domain(grid))
    @test spacing(domain(sdata_grid)) == spacing(domain(grid))
    @test isequal(sdata_grid[:Porosity], grid[:Porosity])
    @test isequal(sdata_grid[:Lithology], grid[:Lithology])
    @test isequal(sdata_grid[Symbol("Water Saturation")], grid[Symbol("Water Saturation")])

    GslibIO.save_legacy(fname, sdata_scattered)
    scattered = GslibIO.load_legacy(fname, (:x, :y, :z))

    @test isequal(coordinates(sdata_scattered), coordinates(scattered))
    @test isequal(sdata_scattered[:Porosity], scattered[:Porosity])

    # save/load using different coordinate names
    GslibIO.save_legacy(fname, sdata_scattered, coordnames = ("east", "north", "elevation"))
    scattered = GslibIO.load_legacy(fname, (:east, :north, :elevation))
    @test isequal(coordinates(sdata_scattered), coordinates(scattered))
    @test isequal(sdata_scattered[:Porosity], scattered[:Porosity])

  end
end
