///|
/// Value at Risk (VaR) Engine (Historical, Parametric, Monte Carlo).

///|
/// Struct holding Value at Risk output metrics.
pub struct VaRResult {
  confidence_level : Double
  var_value : Double
  method_name : String
}

///|
/// Compute Parametric Value at Risk under Normal Assumption.
pub fn compute_parametric_var(
  confidence_level : Double,
  mean : Double,
  stddev : Double,
) -> VaRResult {
  let z = @core.norm_inv(confidence_level)
  let var_val = -(mean - z * stddev)
  {
    confidence_level,
    var_value: if var_val < 0.0 {
      0.0
    } else {
      var_val
    },
    method_name: "Parametric Normal",
  }
}

///|
/// Compute Historical / Non-parametric Value at Risk from profit-and-loss array.
pub fn compute_historical_var(
  confidence_level : Double,
  returns_or_pnl : Array[Double],
) -> VaRResult {
  let losses = Array::make(returns_or_pnl.length(), 0.0)
  let mut i = 0
  while i < returns_or_pnl.length() {
    losses[i] = -returns_or_pnl[i]
    i = i + 1
  }
  let var_val = @core.percentile(losses, confidence_level)
  {
    confidence_level,
    var_value: var_val,
    method_name: "Historical PnL Percentile",
  }
}

///|
/// Compute Monte Carlo Value at Risk from simulated terminal portfolio values.
pub fn compute_monte_carlo_var(
  confidence_level : Double,
  initial_value : Double,
  simulated_terminal_values : Array[Double],
) -> VaRResult {
  let pnl = Array::make(simulated_terminal_values.length(), 0.0)
  let mut i = 0
  while i < simulated_terminal_values.length() {
    pnl[i] = simulated_terminal_values[i] - initial_value
    i = i + 1
  }
  compute_historical_var(confidence_level, pnl)
}

///|
/// Monte Carlo Value at Risk for a GBM process.
pub fn compute_gbm_monte_carlo_var(
  confidence_level : Double,
  gbm : @stochastic.GBMProcess,
  times : Array[Double],
  num_paths : Int,
  rng : @core.RngEngine,
) -> VaRResult {
  let matrix = gbm.generate_matrix(num_paths, times, rng)
  let terminal_step = times.length() - 1
  let s0 = matrix.get(0, 0)
  let terminals = Array::make(num_paths, 0.0)
  let mut p = 0
  while p < num_paths {
    terminals[p] = matrix.get(p, terminal_step)
    p = p + 1
  }
  compute_monte_carlo_var(confidence_level, s0, terminals)
}
