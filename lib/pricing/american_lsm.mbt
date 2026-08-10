///|
/// American Option Pricing Engine using Longstaff-Schwartz Least Squares Monte Carlo (LSM) Algorithm.

///|
/// Solve 3x3 linear system A * beta = Y using Gaussian elimination with partial pivoting.
pub fn solve_ols_3x3(
  a : Array[Array[Double]],
  y : Array[Double],
) -> Array[Double] {
  let beta = Array::make(3, 0.0)
  let aug = Array::make(3, Array::make(4, 0.0))
  let mut i = 0
  while i < 3 {
    aug[i] = Array::make(4, 0.0)
    let mut j = 0
    while j < 3 {
      aug[i][j] = a[i][j]
      j = j + 1
    }
    aug[i][3] = y[i]
    i = i + 1
  }

  // Forward elimination
  let mut k = 0
  while k < 3 {
    let mut max_row = k
    let mut i = k + 1
    while i < 3 {
      let v1 = if aug[i][k] < 0.0 { -aug[i][k] } else { aug[i][k] }
      let v2 = if aug[max_row][k] < 0.0 {
        -aug[max_row][k]
      } else {
        aug[max_row][k]
      }
      if v1 > v2 {
        max_row = i
      }
      i = i + 1
    }
    let tmp = aug[k]
    aug[k] = aug[max_row]
    aug[max_row] = tmp

    if aug[k][k].abs() > 1.0e-15 {
      let mut i = k + 1
      while i < 3 {
        let factor = aug[i][k] / aug[k][k]
        let mut j = k
        while j < 4 {
          aug[i][j] = aug[i][j] - factor * aug[k][j]
          j = j + 1
        }
        i = i + 1
      }
    }
    k = k + 1
  }

  // Back substitution
  let mut i = 2
  while i >= 0 {
    let mut sum = aug[i][3]
    let mut j = i + 1
    while j < 3 {
      sum = sum - aug[i][j] * beta[j]
      j = j + 1
    }
    let div = if aug[i][i].abs() <= 1.0e-15 { 1.0e-15 } else { aug[i][i] }
    beta[i] = sum / div
    i = i - 1
  }
  beta
}

///|
/// Price American Option using Longstaff-Schwartz LSM Algorithm.
pub fn price_american_option_lsm(
  option_type : OptionType,
  gbm : @stochastic.GBMProcess,
  strike : Double,
  r : Double,
  times : Array[Double],
  num_paths : Int,
  rng : @core.RngEngine,
) -> OptionPriceResult {
  let num_steps = times.length()
  if num_steps <= 1 {
    return { price: 0.0, standard_error: 0.0, ci_lower: 0.0, ci_upper: 0.0 }
  }

  let matrix = gbm.generate_matrix(num_paths, times, rng)
  let cash_flows = Array::make(num_paths, 0.0)
  let exercise_step = Array::make(num_paths, num_steps - 1)

  // Initialize cash flows at maturity step T
  let mut p = 0
  while p < num_paths {
    let s_t = matrix.get(p, num_steps - 1)
    let payoff = match option_type {
      Call => if s_t > strike { s_t - strike } else { 0.0 }
      Put => if strike > s_t { strike - s_t } else { 0.0 }
    }
    cash_flows[p] = payoff
    p = p + 1
  }

  // Backward induction loop from t = T - 1 down to 1
  let mut step = num_steps - 2
  while step >= 1 {
    let dt = times[step + 1] - times[step]
    let df = @math.exp(-r * dt)

    // Discount future cash flows one step back
    let mut p = 0
    while p < num_paths {
      cash_flows[p] = cash_flows[p] * df
      p = p + 1
    }

    // Collect in-the-money paths
    let itm_indices = Array::make(num_paths, 0)
    let mut num_itm = 0
    let mut p = 0
    while p < num_paths {
      let s = matrix.get(p, step)
      let intrinsic = match option_type {
        Call => if s > strike { s - strike } else { 0.0 }
        Put => if strike > s { strike - s } else { 0.0 }
      }
      if intrinsic > 0.0 {
        itm_indices[num_itm] = p
        num_itm = num_itm + 1
      }
      p = p + 1
    }

    if num_itm >= 3 {
      // Fit basis functions: 1, S, S^2
      let a_mat = Array::make(3, Array::make(3, 0.0))
      let mut i = 0
      while i < 3 {
        a_mat[i] = Array::make(3, 0.0)
        i = i + 1
      }
      let y_vec = Array::make(3, 0.0)

      let mut idx = 0
      while idx < num_itm {
        let p_idx = itm_indices[idx]
        let s = matrix.get(p_idx, step)
        let y = cash_flows[p_idx]
        let b0 = 1.0
        let b1 = s
        let b2 = s * s

        a_mat[0][0] = a_mat[0][0] + b0 * b0
        a_mat[0][1] = a_mat[0][1] + b0 * b1
        a_mat[0][2] = a_mat[0][2] + b0 * b2

        a_mat[1][0] = a_mat[1][0] + b1 * b0
        a_mat[1][1] = a_mat[1][1] + b1 * b1
        a_mat[1][2] = a_mat[1][2] + b1 * b2

        a_mat[2][0] = a_mat[2][0] + b2 * b0
        a_mat[2][1] = a_mat[2][1] + b2 * b1
        a_mat[2][2] = a_mat[2][2] + b2 * b2

        y_vec[0] = y_vec[0] + b0 * y
        y_vec[1] = y_vec[1] + b1 * y
        y_vec[2] = y_vec[2] + b2 * y
        idx = idx + 1
      }

      let beta = solve_ols_3x3(a_mat, y_vec)

      // Compare immediate exercise vs continuation value
      let mut idx = 0
      while idx < num_itm {
        let p_idx = itm_indices[idx]
        let s = matrix.get(p_idx, step)
        let intrinsic = match option_type {
          Call => s - strike
          Put => strike - s
        }
        let continuation = beta[0] + beta[1] * s + beta[2] * s * s
        if intrinsic > continuation {
          cash_flows[p_idx] = intrinsic
          exercise_step[p_idx] = step
        }
        idx = idx + 1
      }
    }

    step = step - 1
  }

  // Final discount to t = 0
  let stats = @core.StatsAccumulator::new()
  let mut p = 0
  while p < num_paths {
    let t_ex = times[exercise_step[p]]
    let discount = @math.exp(-r * t_ex)
    stats.push(cash_flows[p] * discount)
    p = p + 1
  }

  let (ci_l, ci_u) = stats.confidence_interval(0.95)
  {
    price: stats.mean(),
    standard_error: stats.standard_error(),
    ci_lower: ci_l,
    ci_upper: ci_u,
  }
}
