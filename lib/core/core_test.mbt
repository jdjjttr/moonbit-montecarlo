///|
test "xorshift128plus_reproducibility" {
  let rng1 = @core.Xorshift128Plus::new(12345UL)
  let rng2 = @core.Xorshift128Plus::new(12345UL)
  let v1 = rng1.next_double()
  let v2 = rng2.next_double()
  assert_eq(v1, v2)
}

///|
test "pcg32_reproducibility" {
  let rng1 = @core.PCG32::new(999UL, 1UL)
  let rng2 = @core.PCG32::new(999UL, 1UL)
  assert_eq(rng1.next_u32(), rng2.next_u32())
  assert_eq(rng1.next_double(), rng2.next_double())
}

///|
test "splitmix64_reproducibility" {
  let rng1 = @core.SplitMix64::new(777UL)
  let rng2 = @core.SplitMix64::new(777UL)
  assert_eq(rng1.next_u64(), rng2.next_u64())
}

///|
test "norm_cdf_bounds" {
  let cdf_zero = @core.norm_cdf(0.0)
  let diff_zero = if cdf_zero > 0.5 { cdf_zero - 0.5 } else { 0.5 - cdf_zero }
  assert_true(diff_zero < 1.0e-6)
  let cdf_high = @core.norm_cdf(5.0)
  assert_true(cdf_high > 0.999)
  let cdf_low = @core.norm_cdf(-5.0)
  assert_true(cdf_low < 0.001)
}

///|
test "norm_inv_roundtrip" {
  let p = 0.95
  let z = @core.norm_inv(p)
  let p_reconstructed = @core.norm_cdf(z)
  let diff = if p_reconstructed > p {
    p_reconstructed - p
  } else {
    p - p_reconstructed
  }
  assert_true(diff < 1.0e-4)
}

///|
test "stats_accumulator_welford" {
  let stats = @core.StatsAccumulator::new()
  stats.push(10.0)
  stats.push(20.0)
  stats.push(30.0)
  assert_eq(stats.count(), 3L)
  assert_eq(stats.mean(), 20.0)
  assert_eq(stats.variance(), 100.0)
  assert_eq(stats.stddev(), 10.0)
  assert_eq(stats.min(), 10.0)
  assert_eq(stats.max(), 30.0)
}

///|
test "path_matrix_checksum" {
  let pm1 = @core.PathMatrix::new(2, 3)
  pm1.set(0, 0, 100.0)
  pm1.set(0, 1, 102.5)
  pm1.set(0, 2, 105.0)

  let pm2 = @core.PathMatrix::new(2, 3)
  pm2.set(0, 0, 100.0)
  pm2.set(0, 1, 102.5)
  pm2.set(0, 2, 105.0)

  assert_eq(pm1.compute_checksum(), pm2.compute_checksum())
}

///|
test "dense_matrix_operations" {
  let a = @core.DenseMatrix::identity(2)
  let b = @core.DenseMatrix::new(2, 2)
  b.set(0, 0, 2.0)
  b.set(1, 1, 3.0)
  let c = a.multiply(b)
  assert_eq(c.get(0, 0), 2.0)
  assert_eq(c.get(1, 1), 3.0)
}

///|
test "interpolation_linear_and_spline" {
  let x = [0.0, 1.0, 2.0]
  let y = [0.0, 10.0, 20.0]
  let lin = @core.LinearInterpolator::new(x, y)
  assert_eq(lin.eval(0.5), 5.0)

  let cs = @core.CubicSpline::new(x, y)
  let v = cs.eval(0.5)
  assert_true(v > 4.0 && v < 6.0)
}
