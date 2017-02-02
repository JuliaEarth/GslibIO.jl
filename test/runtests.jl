using GslibIO
using Base.Test

@testset "Basic checks" begin
  fname = tempname()

  A = rand(10,10,10)

  # write to file
  save(fname, A)

  # read from file
  grid = load(fname)

  # query grid object
  B = grid.array

  @test A == B

  rm(filename)
end
