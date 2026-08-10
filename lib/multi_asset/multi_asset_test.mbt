///|
test "cholesky_decomposition_2x2" {
  let mat = @multi_asset.Matrix::new(2, 2)
  mat.set(0, 0, 1.0)
  mat.set(0, 1, 0.6)
  mat.set(1, 0, 0.6)
  mat.set(1, 1, 1.0)
  let l = @multi_asset.cholesky_decompose(mat)
  assert_eq(l.get(0, 0), 1.0)
  assert_eq(l.get(0, 1), 0.0)
  assert_eq(l.get(1, 0), 0.6)
  let l11 = l.get(1, 1)
  let diff = if l11 > 0.8 { l11 - 0.8 } else { 0.8 - l11 }
  assert_true(diff < 1.0e-5) // sqrt(1 - 0.36) = 0.8
}

///|
test "gaussian_copula_sampling" {
  let mat = @multi_asset.Matrix::new(2, 2)
  mat.set(0, 0, 1.0)
  mat.set(0, 1, 0.5)
  mat.set(1, 0, 0.5)
  mat.set(1, 1, 1.0)
  let l = @multi_asset.cholesky_decompose(mat)
  let rng = @core.RngEngine::default(42UL)
  let z = @multi_asset.sample_gaussian_copula(l, rng)
  assert_eq(z.length(), 2)
}

///|
test "multi_asset_correlated_paths" {
  let mat = @multi_asset.Matrix::new(2, 2)
  mat.set(0, 0, 1.0)
  mat.set(0, 1, 0.5)
  mat.set(1, 0, 0.5)
  mat.set(1, 1, 1.0)
  let l = @multi_asset.cholesky_decompose(mat)
  let ma_gbm = @multi_asset.MultiAssetGBM::new(
    [100.0, 50.0],
    [0.05, 0.03],
    [0.2, 0.25],
    l,
  )
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(999UL)
  let paths = ma_gbm.generate_paths(times, rng)
  assert_eq(paths.length(), 2)
  assert_eq(paths[0].initial_value(), 100.0)
  assert_eq(paths[1].initial_value(), 50.0)
}
