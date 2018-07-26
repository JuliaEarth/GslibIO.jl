using FileIO
using Test

@testset "Basic checks" begin
  fname = tempname()*".gslib"

  prop1 = rand(10,10,10)
  prop2 = rand(10,10,10)

  # write to file
  save(fname, [prop1,prop2])

  # read from file
  grid = load(fname)

  # query grid object
  props = grid.properties

  @test props == [prop1,prop2]

  # test version with single array
  save(fname, prop1)
  grid = load(fname)
  props = grid.properties
  @test props[1] == prop1

  rm(fname)
end
