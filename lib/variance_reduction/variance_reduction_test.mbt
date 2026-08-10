///|
test "antithetic_path_pairing" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(123UL)
  let (p1, p2) = @variance_reduction.sample_antithetic_gbm_paths(
    gbm, times, rng,
  )
  assert_eq(p1.initial_value(), 100.0)
  assert_eq(p2.initial_value(), 100.0)
  assert_true(p1.terminal_value() > 0.0)
  assert_true(p2.terminal_value() > 0.0)
}

///|
test "control_variates_variance_reduction" {
  let payoffs = [10.0, 12.0, 15.0, 9.0, 11.0]
  let controls = [9.5, 11.8, 14.9, 8.8, 10.9]
  let res = @variance_reduction.apply_control_variate(payoffs, controls, 11.0)
  assert_true(res.variance_reduction_ratio < 0.2) // High correlation reduces variance by > 80%
}

///|
test "importance_sampling_weight" {
  let rng = @core.RngEngine::default(777UL)
  let sample = @variance_reduction.sample_importance_normal(2.0, rng)
  assert_true(sample.likelihood_ratio > 0.0)
}

///|
test "stratified_sampling_coverage" {
  let rng = @core.RngEngine::default(42UL)
  let strata = @variance_reduction.sample_stratified_uniform(10, rng)
  assert_eq(strata.length(), 10)
  let mut i = 0
  while i < 10 {
    assert_true(strata[i] >= i.to_double() / 10.0)
    assert_true(strata[i] < (i + 1).to_double() / 10.0)
    i = i + 1
  }
}
