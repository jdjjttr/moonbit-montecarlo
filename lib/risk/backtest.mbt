///|
/// Value at Risk (VaR) Backtesting Engine and Model Validation.
/// Implements Kupiec Proportion of Failures (POF) Likelihood Ratio test and Basel Traffic Light System.

///|
/// Basel Traffic Light Zone Enum.
pub(all) enum TrafficLightZone {
  Green
  Yellow
  Red
}

///|
/// VaR Backtest Result Output Struct.
pub struct BacktestResult {
  total_observations : Int
  var_breaches : Int
  expected_breaches : Double
  breach_ratio : Double
  kupiec_lr_stat : Double
  p_value_approx : Double
  traffic_light : TrafficLightZone
}

///|
/// Perform Kupiec POF VaR Backtest against historical daily PnL returns.
pub fn backtest_var(
  confidence_level : Double,
  var_threshold : Double,
  pnl_returns : Array[Double],
) -> BacktestResult {
  let n = pnl_returns.length()
  if n == 0 {
    return {
      total_observations: 0,
      var_breaches: 0,
      expected_breaches: 0.0,
      breach_ratio: 0.0,
      kupiec_lr_stat: 0.0,
      p_value_approx: 1.0,
      traffic_light: Green,
    }
  }

  let alpha = 1.0 - confidence_level
  let mut x = 0
  let mut i = 0
  while i < n {
    let loss = -pnl_returns[i]
    if loss > var_threshold {
      x = x + 1
    }
    i = i + 1
  }

  let n_d = n.to_double()
  let x_d = x.to_double()
  let p_hat = x_d / n_d
  let exp_breaches = n_d * alpha

  let lr_stat = if x == 0 {
    -2.0 * @math.ln(1.0 - alpha) * n_d
  } else {
    let part1 = (n_d - x_d) * @math.ln((1.0 - alpha) / (1.0 - p_hat))
    let part2 = x_d * @math.ln(alpha / p_hat)
    -2.0 * (part1 + part2)
  }
  let pos_lr = if lr_stat < 0.0 { 0.0 } else { lr_stat }

  let traffic = if x <= 4 { Green } else if x <= 9 { Yellow } else { Red }

  {
    total_observations: n,
    var_breaches: x,
    expected_breaches: exp_breaches,
    breach_ratio: p_hat,
    kupiec_lr_stat: pos_lr,
    p_value_approx: @core.norm_cdf(-pos_lr.sqrt()),
    traffic_light: traffic,
  }
}
