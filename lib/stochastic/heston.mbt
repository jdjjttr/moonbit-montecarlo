///|
/// Heston Stochastic Volatility Model Simulator.
/// dS_t = mu * S_t * dt + sqrt(v_t) * S_t * dW_1,t
/// dv_t = kappa * (theta - v_t) * dt + xi * sqrt(v_t) * dW_2,t
/// Correlated Brownian motions E[dW_1 dW_2] = rho dt

///|
/// Heston Model Parameter Specification Struct.
pub struct HestonProcess {
  s0 : Double // Initial asset price
  v0 : Double // Initial variance
  mu : Double // Asset drift
  kappa : Double // Variance mean reversion speed
  theta : Double // Long-term variance mean
  xi : Double // Volatility of volatility (vol-of-vol)
  rho : Double // Correlation between asset and variance noise
}

///|
/// Create a new Heston Process.
pub fn HestonProcess::new(
  s0 : Double,
  v0 : Double,
  mu : Double,
  kappa : Double,
  theta : Double,
  xi : Double,
  rho : Double,
) -> HestonProcess {
  { s0, v0, mu, kappa, theta, xi, rho }
}

///|
/// Feller Condition check for Heston model: 2 * kappa * theta > xi^2.
pub fn HestonProcess::feller_condition(self : HestonProcess) -> Bool {
  2.0 * self.kappa * self.theta > self.xi * self.xi
}

///|
/// Step transition solver using Full Truncation Euler-Maruyama scheme.
pub fn HestonProcess::step(
  self : HestonProcess,
  current_s : Double,
  current_v : Double,
  dt : Double,
  z1 : Double,
  z2 : Double,
) -> (Double, Double) {
  let pos_v = if current_v < 0.0 { 0.0 } else { current_v }
  let sqrt_v = pos_v.sqrt()
  let sqrt_dt = dt.sqrt()

  // Correlated Brownian motion for variance z_v = rho * z1 + sqrt(1 - rho^2) * z2
  let rho_comp = (1.0 - self.rho * self.rho).sqrt()
  let zv = self.rho * z1 + rho_comp * z2

  // Asset price update
  let drift_s = (self.mu - 0.5 * pos_v) * dt
  let diff_s = sqrt_v * sqrt_dt * z1
  let next_s = current_s * @math.exp(drift_s + diff_s)

  // Variance update with full truncation
  let drift_v = self.kappa * (self.theta - pos_v) * dt
  let diff_v = self.xi * sqrt_v * sqrt_dt * zv
  let raw_v = current_v + drift_v + diff_v
  let next_v = if raw_v < 0.0 { 0.0 } else { raw_v }

  (next_s, next_v)
}

///|
/// Generate asset and variance paths for Heston model over time grid.
pub fn HestonProcess::generate_path(
  self : HestonProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> (@core.SimPath, @core.SimPath) {
  let num_steps = times.length()
  let s_vals = Array::make(num_steps, 0.0)
  let v_vals = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return (
      @core.SimPath::new(times, s_vals),
      @core.SimPath::new(times, v_vals),
    )
  }

  s_vals[0] = self.s0
  v_vals[0] = self.v0

  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z1, _) = @core.sample_box_muller(rng)
    let (z2, _) = @core.sample_box_muller(rng)
    let (next_s, next_v) = self.step(s_vals[i - 1], v_vals[i - 1], dt, z1, z2)
    s_vals[i] = next_s
    v_vals[i] = next_v
    i = i + 1
  }

  (@core.SimPath::new(times, s_vals), @core.SimPath::new(times, v_vals))
}
