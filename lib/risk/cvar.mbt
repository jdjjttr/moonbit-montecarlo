///|
/// Conditional Value at Risk (CVaR) / Expected Shortfall (ES) Engine.
/// Measures expected loss given that loss exceeds the VaR threshold.

///|
/// CVaR / Expected Shortfall Result Struct.
pub struct CVaRResult {
  confidence_level : Double
  var_value : Double
  cvar_value : Double
}

///|
/// Compute Expected Shortfall (CVaR) from simulated loss distribution array.
pub fn compute_expected_shortfall(
  confidence_level : Double,
  losses : Array[Double],
) -> CVaRResult {
  let len = losses.length()
  if len == 0 {
    return { confidence_level, var_value: 0.0, cvar_value: 0.0 }
  }
  let var_res = compute_historical_var(confidence_level, losses)
  let var_val = var_res.var_value

  let mut tail_sum = 0.0
  let mut tail_count = 0L
  let mut i = 0
  while i < len {
    let loss = -losses[i]
    if loss >= var_val {
      tail_sum = tail_sum + loss
      tail_count = tail_count + 1L
    }
    i = i + 1
  }

  let cvar_val = if tail_count == 0L {
    var_val
  } else {
    tail_sum / tail_count.to_double()
  }
  { confidence_level, var_value: var_val, cvar_value: cvar_val }
}
