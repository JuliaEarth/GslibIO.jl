using GslibIO
using Base.Test

@testset "Basic checks" begin
  fname = tempname()

  A = rand(10,10,10)

  # write to file
  GslibIO.save(fname, A)

  # read from file
  grid = GslibIO.load(fname)

  # query grid object
  B = grid.array

  @test A == B

  rm(filename)
end
