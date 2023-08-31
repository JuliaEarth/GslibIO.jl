using GslibIO
using Meshes
using Test

# environment settings
datadir = joinpath(@__DIR__, "data")
savedir = mktempdir()

@testset "GslibIO.jl" begin
  @testset "ExtendedGrid" begin
    fname = joinpath(datadir, "extended_grid.gslib")
    sdata = GslibIO.load(fname)

    sdomain = domain(sdata)
    @test size(sdomain) == (2, 2, 2)
    @test minimum(sdomain) == Point(0.0, 0.0, 0.0)
    @test spacing(sdomain) == (1.0, 1.0, 1.0)

    @test sdata.Porosity == [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
    @test sdata.Lithology == [1, 2, 3, 4, 5, 6, 7, 8]
    @test isequal(sdata."Water Saturation", [0.8, 0.7, 0.8, 0.7, 0.8, 0.7, 0.8, NaN])

    # test if storing/loading recovers data
    fname = joinpath(savedir, "extended_grid.gslib")
    GslibIO.save(fname, sdata)
    ndata = GslibIO.load(fname)
    @test ndata == sdata

    rm(fname)
  end

  @testset "ExtendedPointSet" begin
    fname = joinpath(datadir, "extended_pset.gslib")
    sdata = GslibIO.load(fname)

    sdomain = domain(sdata)
    @test embeddim(sdomain) == 3
    @test nelements(sdomain) == 4

    @test sdomain[1] == Point(10.0, 11.0, 12.0)
    @test sdomain[2] == Point(20.0, 21.0, 22.0)
    @test sdomain[3] == Point(30.0, 31.0, 32.0)
    @test sdomain[4] == Point(40.0, 41.0, 42.0)
    @test sdata.Porosity == [0.1, 0.2, 0.3, 0.4]

    # test if storing/loading recovers data
    fname = joinpath(savedir, "extended_pset.gslib")
    GslibIO.save(fname, sdata)
    ndata = GslibIO.load(fname)
    @test sdata == ndata

    rm(fname)
  end

  @testset "LegacyParser" begin
    fname = joinpath(datadir, "legacy_grid.gslib")

    spec = GslibIO.parse_legacy(fname)

    @test isequal(spec.data[:, 1], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
    @test isequal(spec.data[:, 2], [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
    @test isequal(spec.data[:, 3], [0.8, 0.7, 0.8, 0.7, 0.8, 0.7, 0.8, -999.0])

    @test spec.varnames == [:Porosity, :Lithology, Symbol("Water Saturation")]

    fname = joinpath(datadir, "legacy_pset.gslib")

    spec = GslibIO.parse_legacy(fname)

    @test spec.varnames == [:East, :North, :Elevation, :Porosity]

    @test isequal(spec.data[:, 1], [10.0, 20.0, 30.0, 40.0])
    @test isequal(spec.data[:, 2], [11.0, 21.0, 31.0, 41.0])
    @test isequal(spec.data[:, 3], [12.0, 22.0, 32.0, 42.0])
    @test isequal(spec.data[:, 4], [0.1, 0.2, 0.3, 0.4])
  end

  @testset "LegacyGrid" begin
    fname = joinpath(datadir, "legacy_grid.gslib")

    sdata = GslibIO.load_legacy(fname, (2, 2, 2))

    @test size(domain(sdata)) == (2, 2, 2)
    @test minimum(domain(sdata)) == Point(0.0, 0.0, 0.0)
    @test spacing(domain(sdata)) == (1.0, 1.0, 1.0)

    por = sdata.Porosity
    lit = sdata.Lithology
    sat = sdata."Water Saturation"
    @test isequal(por, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8])
    @test isequal(lit, [1, 2, 3, 4, 5, 6, 7, 8])
    @test isequal(sat, [0.8, 0.7, 0.8, 0.7, 0.8, 0.7, 0.8, NaN])

    # test if storing/loading recovers data
    fname = tempname() * ".gslib"
    GslibIO.save_legacy(fname, sdata, na=-999)
    ndata = GslibIO.load_legacy(fname, (2, 2, 2), na=-999)
    @test isequal(domain(sdata), domain(ndata))
    @test isequal(values(sdata), values(ndata))

    rm(fname)
  end

  @testset "LegacyPointSet" begin
    fname = joinpath(datadir, "legacy_pset.gslib")

    sdata = GslibIO.load_legacy(fname, (:East, :North, :Elevation))

    sdomain = domain(sdata)
    @test embeddim(sdomain) == 3
    @test nelements(sdomain) == 4

    por = sdata.Porosity
    @test centroid(sdomain, 1) == Point(10.0, 11.0, 12.0)
    @test centroid(sdomain, 2) == Point(20.0, 21.0, 22.0)
    @test centroid(sdomain, 3) == Point(30.0, 31.0, 32.0)
    @test centroid(sdomain, 4) == Point(40.0, 41.0, 42.0)
    @test isequal(por, [0.1, 0.2, 0.3, 0.4])

    # test when coordnames are not in varnames
    @test_throws AssertionError GslibIO.load_legacy(fname, (:x, :y, :Elevation))

    # test if storing/loading recovers data
    fname = tempname() * ".gslib"
    GslibIO.save_legacy(fname, sdata, coordnames=(:x, :y, :Elevation))
    ndata = GslibIO.load_legacy(fname, (:x, :y, :Elevation))
    @test sdata == ndata

    rm(fname)
  end

  @testset "LegacyInvalid" begin
    fname = joinpath(datadir, "legacy_invalid.gslib")

    @test_throws MethodError GslibIO.load_legacy(fname, (:x, :y, :z))
  end
end
