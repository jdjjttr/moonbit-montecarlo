///|
/// Stratified Sampling and Latin Hypercube Sampling (LHS) Engine.

///|
/// Generate stratified uniform samples across `n_strata` equal probability bins.
pub fn sample_stratified_uniform(
  n_strata : Int,
  rng : @core.RngEngine,
) -> Array[Double] {
  let res = Array::make(n_strata, 0.0)
  let n = n_strata.to_double()
  let mut i = 0
  while i < n_strata {
    let u = rng.next_double()
    res[i] = (i.to_double() + u) / n
    i = i + 1
  }
  res
}

///|
/// Generate Stratified Standard Normal Samples via Quantile mapping.
pub fn sample_stratified_normal(
  n_strata : Int,
  rng : @core.RngEngine,
) -> Array[Double] {
  let u = sample_stratified_uniform(n_strata, rng)
  let res = Array::make(n_strata, 0.0)
  let mut i = 0
  while i < n_strata {
    let clamped_u = if u[i] < 1.0e-12 {
      1.0e-12
    } else if u[i] > 1.0 - 1.0e-12 {
      1.0 - 1.0e-12
    } else {
      u[i]
    }
    res[i] = @core.norm_inv(clamped_u)
    i = i + 1
  }
  res
}

///|
/// Latin Hypercube Sampling (LHS) matrix generator for D dimensions.
pub fn sample_lhs_matrix(
  n_samples : Int,
  n_dims : Int,
  rng : @core.RngEngine,
) -> Array[Array[Double]] {
  let matrix = Array::make(n_samples, Array::make(n_dims, 0.0))
  // Initialize matrix with row instances
  let mut i = 0
  while i < n_samples {
    matrix[i] = Array::make(n_dims, 0.0)
    i = i + 1
  }

  let mut d = 0
  while d < n_dims {
    let col = sample_stratified_uniform(n_samples, rng)
    // Permute column for hypercube balance (Fisher-Yates shuffle)
    let mut i = n_samples - 1
    while i > 0 {
      let j = (rng.next_double() * (i + 1).to_double()).to_int()
      let tmp = col[i]
      col[i] = col[j]
      col[j] = tmp
      i = i - 1
    }
    let mut i = 0
    while i < n_samples {
      matrix[i][d] = col[i]
      i = i + 1
    }
    d = d + 1
  }
  matrix
}
