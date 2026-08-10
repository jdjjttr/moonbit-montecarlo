///|
/// Geometric Brownian Motion (GBM) Stochastic Process Simulator.
/// S_t = S_0 * exp((mu - 0.5 * sigma^2)*t + sigma * W_t)

///|
/// Geometric Brownian Motion process specification.
pub struct GBMProcess {
  s0 : Double
  mu : Double
  sigma : Double
}

///|
/// Create a new Geometric Brownian Motion process.
pub fn GBMProcess::new(s0 : Double, mu : Double, sigma : Double) -> GBMProcess {
  { s0, mu, sigma }
}

///|
/// Exact analytical step transition solver for GBM.
pub fn GBMProcess::step(
  self : GBMProcess,
  current_s : Double,
  dt : Double,
  z : Double,
) -> Double {
  let drift = (self.mu - 0.5 * self.sigma * self.sigma) * dt
  let diffusion = self.sigma * dt.sqrt() * z
  current_s * @math.exp(drift + diffusion)
}

///|
/// Generate a single sample trajectory path over a given time grid.
pub fn GBMProcess::generate_path(
  self : GBMProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> @core.SimPath {
  let num_steps = times.length()
  let values = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return @core.SimPath::new(times, values)
  }
  values[0] = self.s0
  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z, _) = @core.sample_box_muller(rng)
    values[i] = self.step(values[i - 1], dt, z)
    i = i + 1
  }
  @core.SimPath::new(times, values)
}

///|
/// Generate a PathMatrix for batch simulations.
pub fn GBMProcess::generate_matrix(
  self : GBMProcess,
  num_paths : Int,
  times : Array[Double],
  rng : @core.RngEngine,
) -> @core.PathMatrix {
  let num_steps = times.length()
  let matrix = @core.PathMatrix::new(num_paths, num_steps)
  let mut p = 0
  while p < num_paths {
    matrix.set(p, 0, self.s0)
    let mut i = 1
    while i < num_steps {
      let dt = times[i] - times[i - 1]
      let (z, _) = @core.sample_box_muller(rng)
      let prev = matrix.get(p, i - 1)
      let next_val = self.step(prev, dt, z)
      matrix.set(p, i, next_val)
      i = i + 1
    }
    p = p + 1
  }
  matrix
}
