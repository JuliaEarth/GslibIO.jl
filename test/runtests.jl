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

  @testset "GSLIBParser" begin
    fname = joinpath(datadir, "legacy_grid.gslib")

    X, metadata = GslibIO.parse_gslib(fname)

    @test isequal(X[:, 1], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
    @test isequal(X[:, 2], [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
    @test isequal(X[:, 3], [0.8, 0.7, 0.8, 0.7, 0.8, 0.7, 0.8, -999.0])

    @test metadata.nvars == 3
    @test metadata.varnames == ["Porosity", "Lithology", "Water Saturation"]
    @test metadata.extrainfo == "2  2  2 0.5 0.5 0.5 1.0 1.0 1.0"

    fname = joinpath(datadir, "legacy_scatter.gslib")

    X, metadata = GslibIO.parse_gslib(fname)

    @test metadata.nvars == 4
    @test metadata.varnames == ["East", "North", "Elevation", "Porosity"]
    @test metadata.extrainfo == ""

    @test isequal(X[:, 1], [10.0, 20.0, 30.0])
    @test isequal(X[:, 2], [11.0, 21.0, 31.0])
    @test isequal(X[:, 3], [12.0, 22.0, 32.0])
    @test isequal(X[:, 4], [0.1, 0.2, 0.3])

  end  

  @testset "Legacy" begin
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

end
