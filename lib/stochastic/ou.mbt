///|
/// Ornstein-Uhlenbeck (OU) Mean-Reverting Process Simulator.
/// dX_t = theta * (mu - X_t) * dt + sigma * dW_t

///|
/// OU Process Struct.
pub struct OUProcess {
  x0 : Double
  theta : Double // Mean reversion speed
  mu : Double // Long-term equilibrium level
  sigma : Double // Volatility
}

///|
/// Create a new Ornstein-Uhlenbeck process.
pub fn OUProcess::new(
  x0 : Double,
  theta : Double,
  mu : Double,
  sigma : Double,
) -> OUProcess {
  { x0, theta, mu, sigma }
}

///|
/// Stationary variance Var(X_inf) = sigma^2 / (2 * theta).
pub fn OUProcess::stationary_variance(self : OUProcess) -> Double {
  self.sigma * self.sigma / (2.0 * self.theta)
}

///|
/// Exact Gaussian step transition solver for OU process.
pub fn OUProcess::step(
  self : OUProcess,
  current_x : Double,
  dt : Double,
  z : Double,
) -> Double {
  let exp_tdt = @math.exp(-self.theta * dt)
  let mean = current_x * exp_tdt + self.mu * (1.0 - exp_tdt)
  let stddev = self.sigma *
    ((1.0 - @math.exp(-2.0 * self.theta * dt)) / (2.0 * self.theta)).sqrt()
  mean + stddev * z
}

///|
/// Generate a path over given time grid.
pub fn OUProcess::generate_path(
  self : OUProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> @core.SimPath {
  let num_steps = times.length()
  let values = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return @core.SimPath::new(times, values)
  }
  values[0] = self.x0
  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z, _) = @core.sample_box_muller(rng)
    values[i] = self.step(values[i - 1], dt, z)
    i = i + 1
  }
  @core.SimPath::new(times, values)
}
