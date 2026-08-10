///|
/// Multi-Asset Correlated GBM Path Generator.

///|
/// Multi-Asset correlated GBM parameter specifications.
pub struct MultiAssetGBM {
  num_assets : Int
  s0 : Array[Double]
  mu : Array[Double]
  sigma : Array[Double]
  cholesky_l : Matrix
}

///|
/// Create a new MultiAssetGBM process given asset parameters and lower triangular Cholesky matrix.
pub fn MultiAssetGBM::new(
  s0 : Array[Double],
  mu : Array[Double],
  sigma : Array[Double],
  cholesky_l : Matrix,
) -> MultiAssetGBM {
  let num_assets = s0.length()
  { num_assets, s0, mu, sigma, cholesky_l }
}

///|
/// Generate correlated trajectories for all N assets over specified time grid.
/// Returns an Array of SimPath, one per asset.
pub fn MultiAssetGBM::generate_paths(
  self : MultiAssetGBM,
  times : Array[Double],
  rng : @core.RngEngine,
) -> Array[@core.SimPath] {
  let num_steps = times.length()
  let paths = Array::make(self.num_assets, Array::make(num_steps, 0.0))
  let mut a = 0
  while a < self.num_assets {
    paths[a] = Array::make(num_steps, 0.0)
    paths[a][0] = self.s0[a]
    a = a + 1
  }

  let mut step_idx = 1
  while step_idx < num_steps {
    let dt = times[step_idx] - times[step_idx - 1]
    let corr_z = sample_gaussian_copula(self.cholesky_l, rng)
    let mut a = 0
    while a < self.num_assets {
      let drift = (self.mu[a] - 0.5 * self.sigma[a] * self.sigma[a]) * dt
      let diffusion = self.sigma[a] * dt.sqrt() * corr_z[a]
      let prev_s = paths[a][step_idx - 1]
      paths[a][step_idx] = prev_s * @math.exp(drift + diffusion)
      a = a + 1
    }
    step_idx = step_idx + 1
  }

  let result = Array::make(self.num_assets, @core.SimPath::new(times, []))
  let mut a = 0
  while a < self.num_assets {
    result[a] = @core.SimPath::new(times, paths[a])
    a = a + 1
  }
  result
}
