///|
/// General Stochastic Differential Equation (SDE) Numerical Solvers.
/// Solves SDEs of the form dX_t = a(t, X_t) dt + b(t, X_t) dW_t

///|
/// SDE Drift Function Signature: (t: Double, x: Double) -> Double.
/// SDE Diffusion Function Signature: (t: Double, x: Double) -> Double.
/// SDE Diffusion Derivative Signature db/dx: (t: Double, x: Double) -> Double.

///|
/// Solves SDE using 1st-Order Milstein Scheme:
/// X_{t+dt} = X_t + a(t,X) dt + b(t,X) dW + 0.5 * b(t,X) * b'(t,X) * (dW^2 - dt)
pub fn solve_milstein_step(
  x : Double,
  t : Double,
  dt : Double,
  z : Double,
  drift_fn : (Double, Double) -> Double,
  diff_fn : (Double, Double) -> Double,
  diff_deriv_fn : (Double, Double) -> Double,
) -> Double {
  let a = drift_fn(t, x)
  let b = diff_fn(t, x)
  let b_prime = diff_deriv_fn(t, x)
  let sqrt_dt = dt.sqrt()
  let dw = sqrt_dt * z

  let euler_part = a * dt + b * dw
  let milstein_correction = 0.5 * b * b_prime * (dw * dw - dt)
  x + euler_part + milstein_correction
}

///|
/// Solves SDE trajectory over time grid using Milstein Scheme.
pub fn solve_milstein_path(
  x0 : Double,
  times : Array[Double],
  drift_fn : (Double, Double) -> Double,
  diff_fn : (Double, Double) -> Double,
  diff_deriv_fn : (Double, Double) -> Double,
  rng : @core.RngEngine,
) -> @core.SimPath {
  let len = times.length()
  let values = Array::make(len, 0.0)
  if len == 0 {
    return @core.SimPath::new(times, values)
  }

  values[0] = x0
  let mut i = 1
  while i < len {
    let t = times[i - 1]
    let dt = times[i] - t
    let (z, _) = @core.sample_box_muller(rng)
    values[i] = solve_milstein_step(
      values[i - 1],
      t,
      dt,
      z,
      drift_fn,
      diff_fn,
      diff_deriv_fn,
    )
    i = i + 1
  }

  @core.SimPath::new(times, values)
}
