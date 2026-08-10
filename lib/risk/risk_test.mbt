///|
test "parametric_var_normal" {
  let res = @risk.compute_parametric_var(0.95, 0.05, 0.2)
  assert_eq(res.confidence_level, 0.95)
  assert_true(res.var_value > 0.0)
}

///|
test "historical_var_percentile" {
  let returns = [-0.05, -0.02, 0.01, 0.03, 0.04]
  let res = @risk.compute_historical_var(0.80, returns)
  assert_true(res.var_value >= 0.02)
}

///|
test "cvar_expected_shortfall" {
  let losses = [0.10, 0.05, 0.02, -0.01, -0.03]
  let res = @risk.compute_expected_shortfall(0.80, losses)
  assert_true(res.cvar_value >= res.var_value)
}

///|
test "stress_testing_scenarios" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let scenarios = [
    @risk.StressScenario::new("Market Crash", -0.3, 2.0),
    @risk.StressScenario::new("Rate Hike", 0.02, 1.2),
  ]
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(42UL)
  let results = @risk.run_stress_test_suite(gbm, scenarios, times, 100, rng)
  assert_eq(results.length(), 2)
}
