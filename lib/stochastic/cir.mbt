///|
/// Cox-Ingersoll-Ross (CIR) Square-Root Interest Rate Process.
/// dr_t = a * (b - r_t) * dt + sigma * sqrt(r_t) * dW_t

///|
/// CIR Process Struct.
pub struct CIRProcess {
  r0 : Double
  a : Double // Mean reversion speed
  b : Double // Long-term mean
  sigma : Double // Volatility parameter
}

///|
/// Create a new CIR process.
pub fn CIRProcess::new(
  r0 : Double,
  a : Double,
  b : Double,
  sigma : Double,
) -> CIRProcess {
  { r0, a, b, sigma }
}

///|
/// Compute Feller Ratio 2*a*b / sigma^2. If ratio > 1, process never touches zero.
pub fn CIRProcess::feller_ratio(self : CIRProcess) -> Double {
  2.0 * self.a * self.b / (self.sigma * self.sigma)
}

///|
/// Truncated Euler-Maruyama step discretization for CIR process ensuring non-negativity.
pub fn CIRProcess::step(
  self : CIRProcess,
  current_r : Double,
  dt : Double,
  z : Double,
) -> Double {
  let pos_r = if current_r < 0.0 { 0.0 } else { current_r }
  let drift = self.a * (self.b - pos_r) * dt
  let diffusion = self.sigma * pos_r.sqrt() * dt.sqrt() * z
  let next_r = pos_r + drift + diffusion
  if next_r < 0.0 {
    0.0
  } else {
    next_r
  }
}

///|
/// Generate a short-rate trajectory path.
pub fn CIRProcess::generate_path(
  self : CIRProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> @core.SimPath {
  let num_steps = times.length()
  let values = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return @core.SimPath::new(times, values)
  }
  values[0] = self.r0
  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z, _) = @core.sample_box_muller(rng)
    values[i] = self.step(values[i - 1], dt, z)
    i = i + 1
  }
  @core.SimPath::new(times, values)
}
