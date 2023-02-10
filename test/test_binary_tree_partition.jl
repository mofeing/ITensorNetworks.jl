using ITensors
using ITensorNetworks:
  _binary_tree_partition_inds, _mps_partition_inds_order, _mincut_partitions

@testset "test mincut functions on top of MPS" begin
  i = Index(2, "i")
  j = Index(2, "j")
  k = Index(2, "k")
  l = Index(2, "l")
  m = Index(2, "m")
  n = Index(2, "n")
  o = Index(2, "o")
  p = Index(2, "p")

  T = randomITensor(i, j, k, l, m, n, o, p)
  M = MPS(T, (i, j, k, l, m, n, o, p); cutoff=1e-5, maxdim=500)
  tn = ITensorNetwork(M[:])
  out = _binary_tree_partition_inds(
    tn, [i, j, k, l, m, n, o, p]; maximally_unbalanced=false
  )
  @test length(out) == 2
  out = _binary_tree_partition_inds(tn, [i, j, k, l, m, n, o, p]; maximally_unbalanced=true)
  @test length(out) == 2
  out = _mps_partition_inds_order(tn, [o, p, i, j, k, l, m, n])
  @test out in [[i, j, k, l, m, n, o, p], [p, o, n, m, l, k, j, i]]
  p1, p2 = _mincut_partitions(tn, [k, l], [m, n])
  # When MPS bond dimensions are large, the partition will not across internal inds
  @test (length(p1) == 0) || (length(p2) == 0)

  M = MPS(T, (i, j, k, l, m, n, o, p); cutoff=1e-5, maxdim=2)
  tn = ITensorNetwork(M[:])
  p1, p2 = _mincut_partitions(tn, [k, l], [m, n])
  # When MPS bond dimensions are small, the partition will across internal inds
  @test sort(p1) == [1, 2, 3, 4]
  @test sort(p2) == [5, 6, 7, 8]
end

@testset "test _binary_tree_partition_inds of a 2D network" begin
  N = (3, 3, 3)
  linkdim = 2
  network = randomITensorNetwork(IndsNetwork(named_grid(N)); link_space=linkdim)
  tn = Array{ITensor,length(N)}(undef, N...)
  for v in vertices(network)
    tn[v...] = network[v...]
  end
  tn = ITensorNetwork(vec(tn[:, :, 1]))
  out = _binary_tree_partition_inds(
    tn, noncommoninds(Vector{ITensor}(tn)...); maximally_unbalanced=false
  )
  @test length(out) == 2
  out = _binary_tree_partition_inds(
    tn, noncommoninds(Vector{ITensor}(tn)...); maximally_unbalanced=true
  )
  @test length(out) == 2
end

@testset "test binary_tree_partition" begin
  i = Index(2, "i")
  j = Index(2, "j")
  k = Index(2, "k")
  l = Index(2, "l")
  m = Index(2, "m")
  T = randomITensor(i, j, k, l, m)
  M = MPS(T, (i, j, k, l, m); cutoff=1e-5, maxdim=5)
  network = M[:]
  out1 = contract(network...)
  tn = ITensorNetwork(network)
  inds_btree = _binary_tree_partition_inds(tn, [i, j, k, l, m]; maximally_unbalanced=false)
  par = binary_tree_partition(tn, inds_btree)
  networks = [Vector{ITensor}(par[v]) for v in vertices(par)]
  network2 = vcat(networks...)
  out2 = contract(network2...)
  @test isapprox(out1, out2)
end