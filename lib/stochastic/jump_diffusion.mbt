///|
/// Merton Jump Diffusion Process Simulator.
/// Combines continuous Geometric Brownian Motion with discrete Poisson jump events.

///|
/// Jump Diffusion Process Struct.
pub struct JumpDiffusionProcess {
  s0 : Double
  mu : Double // Drift rate
  sigma : Double // Diffusion volatility
  lambda_jump : Double // Poisson intensity (expected jumps per unit time)
  mu_jump : Double // Mean of log jump size N(mu_J, sigma_J^2)
  sigma_jump : Double // Volatility of log jump size
}

///|
/// Create a new Merton Jump Diffusion process.
pub fn JumpDiffusionProcess::new(
  s0 : Double,
  mu : Double,
  sigma : Double,
  lambda_jump : Double,
  mu_jump : Double,
  sigma_jump : Double,
) -> JumpDiffusionProcess {
  { s0, mu, sigma, lambda_jump, mu_jump, sigma_jump }
}

///|
/// Expected jump multiplier k = E[Y - 1] = exp(mu_J + 0.5 * sigma_J^2) - 1.
pub fn JumpDiffusionProcess::expected_jump_multiplier(
  self : JumpDiffusionProcess,
) -> Double {
  @math.exp(self.mu_jump + 0.5 * self.sigma_jump * self.sigma_jump) - 1.0
}

///|
/// Step transition solver under Merton Jump Diffusion model.
pub fn JumpDiffusionProcess::step(
  self : JumpDiffusionProcess,
  current_s : Double,
  dt : Double,
  rng : @core.RngEngine,
) -> Double {
  let k = self.expected_jump_multiplier()
  // Compensated drift
  let drift = (self.mu - 0.5 * self.sigma * self.sigma - self.lambda_jump * k) *
    dt
  let (z, _) = @core.sample_box_muller(rng)
  let diffusion = self.sigma * dt.sqrt() * z

  // Sample number of Poisson jumps in dt
  let p_dist = @core.PoissonDist::new(self.lambda_jump * dt)
  let num_jumps = p_dist.sample(rng)

  let mut total_jump_factor = 0.0
  let mut j = 0
  while j < num_jumps {
    let (zj, _) = @core.sample_box_muller(rng)
    let log_jump = self.mu_jump + self.sigma_jump * zj
    total_jump_factor = total_jump_factor + log_jump
    j = j + 1
  }

  current_s * @math.exp(drift + diffusion + total_jump_factor)
}

///|
/// Generate a jump diffusion asset path.
pub fn JumpDiffusionProcess::generate_path(
  self : JumpDiffusionProcess,
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
    values[i] = self.step(values[i - 1], dt, rng)
    i = i + 1
  }
  @core.SimPath::new(times, values)
}
