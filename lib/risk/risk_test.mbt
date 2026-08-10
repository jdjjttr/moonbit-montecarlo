///|
test "parametric_var_normal" {
  let res = compute_parametric_var(0.95, 0.05, 0.2)
  assert_eq(res.confidence_level, 0.95)
  assert_true(res.var_value > 0.0)
}

///|
test "historical_var_percentile" {
  let returns = [-0.05, -0.02, 0.01, 0.03, 0.04]
  let res = compute_historical_var(0.80, returns)
  assert_true(res.var_value >= 0.02)
}

///|
test "cvar_expected_shortfall" {
  let losses = [0.10, 0.05, 0.02, -0.01, -0.03]
  let res = compute_expected_shortfall(0.80, losses)
  assert_true(res.cvar_value >= res.var_value)
}

///|
test "stress_testing_scenarios" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let scenarios = [
    StressScenario::new("Market Crash", -0.3, 2.0),
    StressScenario::new("Rate Hike", 0.02, 1.2),
  ]
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(42UL)
  let results = run_stress_test_suite(gbm, scenarios, times, 100, rng)
  assert_eq(results.length(), 2)
}

///|
test "kupiec_backtesting_var" {
  let returns = [-0.01, -0.02, 0.01, -0.04, 0.02, -0.01]
  let bt = backtest_var(0.95, 0.03, returns)
  assert_eq(bt.var_breaches, 1)
  assert_true(bt.total_observations == 6)
}

///|
test "merton_credit_risk" {
  let res = compute_merton_default_probability(
    100.0, 80.0, 0.05, 0.2, 1.0, 0.03,
  )
  assert_true(res.distance_to_default > 1.0)
  assert_true(res.default_probability < 0.2)
}
