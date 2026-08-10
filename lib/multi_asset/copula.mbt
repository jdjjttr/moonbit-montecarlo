///|
/// Copula Engine for Correlated Random Vector Generation.

///|
/// Sample N-dimensional correlated normal random vector using Gaussian Copula and Cholesky matrix L.
pub fn sample_gaussian_copula(
  cholesky_l : Matrix,
  rng : @core.RngEngine,
) -> Array[Double] {
  let dim = cholesky_l.rows()
  let uncorr_z = Array::make(dim, 0.0)
  let mut i = 0
  while i < dim {
    let (z, _) = @core.sample_box_muller(rng)
    uncorr_z[i] = z
    i = i + 1
  }
  multiply_l_vector(cholesky_l, uncorr_z)
}

///|
/// Sample N-dimensional correlated Student-t Copula random vector.
pub fn sample_t_copula(
  cholesky_l : Matrix,
  df : Double,
  rng : @core.RngEngine,
) -> Array[Double] {
  let corr_z = sample_gaussian_copula(cholesky_l, rng)
  let dim = cholesky_l.rows()
  let t_dist = @core.StudentTDist::new(df)
  let w = t_dist.sample(rng)
  let scale = if w <= 1.0e-15 { 1.0 } else { (df / w).sqrt() }
  let res = Array::make(dim, 0.0)
  let mut i = 0
  while i < dim {
    res[i] = corr_z[i] * scale
    i = i + 1
  }
  res
}
