///|
/// Antithetic Variates Technique for Monte Carlo Variance Reduction.
/// Pairs standard normal innovation Z with -Z to create negative covariance paths.

///|
/// Generate a pair of antithetic trajectory paths for a given Geometric Brownian Motion.
pub fn sample_antithetic_gbm_paths(
  gbm : @stochastic.GBMProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> (@core.SimPath, @core.SimPath) {
  let num_steps = times.length()
  let values_pos = Array::make(num_steps, 0.0)
  let values_neg = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return (
      @core.SimPath::new(times, values_pos),
      @core.SimPath::new(times, values_neg),
    )
  }

  let s0 = gbm.generate_path([0.0], rng).initial_value()
  values_pos[0] = s0
  values_neg[0] = s0

  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z, _) = @core.sample_box_muller(rng)
    values_pos[i] = gbm.step(values_pos[i - 1], dt, z)
    values_neg[i] = gbm.step(values_neg[i - 1], dt, -z)
    i = i + 1
  }

  (@core.SimPath::new(times, values_pos), @core.SimPath::new(times, values_neg))
}
