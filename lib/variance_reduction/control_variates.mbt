///|
/// Control Variates Variance Reduction Engine.
/// X_cv = X - beta * (Y - E[Y])

///|
/// Result struct holding control variates estimator metrics.
pub struct ControlVariateResult {
  adjusted_mean : Double
  unadjusted_mean : Double
  beta_star : Double
  variance_reduction_ratio : Double
}

///|
/// Compute optimal beta and control-variates adjusted estimator.
pub fn apply_control_variate(
  payoffs : Array[Double],
  controls : Array[Double],
  expected_control : Double,
) -> ControlVariateResult {
  let n = payoffs.length()
  if n == 0 || n != controls.length() {
    return {
      adjusted_mean: 0.0,
      unadjusted_mean: 0.0,
      beta_star: 0.0,
      variance_reduction_ratio: 0.0,
    }
  }

  let n_d = n.to_double()
  let mut mean_x = 0.0
  let mut mean_y = 0.0
  let mut i = 0
  while i < n {
    mean_x = mean_x + payoffs[i]
    mean_y = mean_y + controls[i]
    i = i + 1
  }
  mean_x = mean_x / n_d
  mean_y = mean_y / n_d

  let mut cov_xy = 0.0
  let mut var_y = 0.0
  let mut var_x = 0.0
  let mut i = 0
  while i < n {
    let dx = payoffs[i] - mean_x
    let dy = controls[i] - mean_y
    cov_xy = cov_xy + dx * dy
    var_y = var_y + dy * dy
    var_x = var_x + dx * dx
    i = i + 1
  }

  let beta_star = if var_y <= 1.0e-15 { 0.0 } else { cov_xy / var_y }
  let adjusted_mean = mean_x - beta_star * (mean_y - expected_control)

  let corr = if var_x * var_y <= 1.0e-15 {
    0.0
  } else {
    cov_xy / (var_x.sqrt() * var_y.sqrt())
  }
  let var_red_ratio = 1.0 - corr * corr

  {
    adjusted_mean,
    unadjusted_mean: mean_x,
    beta_star,
    variance_reduction_ratio: var_red_ratio,
  }
}
