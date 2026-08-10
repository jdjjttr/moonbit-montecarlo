test "gbm_path_reproducibility" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.25, 0.5, 0.75, 1.0]
  let rng1 = @core.RngEngine::default(42UL)
  let rng2 = @core.RngEngine::default(42UL)
  let p1 = gbm.generate_path(times, rng1)
  let p2 = gbm.generate_path(times, rng2)
  assert_eq(p1.terminal_value(), p2.terminal_value())
  assert_eq(p1.max_value(), p2.max_value())
}

test "vasicek_bond_price" {
  let v = @stochastic.VasicekProcess::new(0.03, 0.15, 0.05, 0.01)
  let price = v.zero_coupon_bond_price(1.0)
  assert_true(price > 0.90)
  assert_true(price < 1.0)
}

test "cir_feller_ratio" {
  let cir = @stochastic.CIRProcess::new(0.04, 0.2, 0.05, 0.1)
  let ratio = cir.feller_ratio()
  assert_true(ratio > 1.0)
}

test "ou_stationary_variance" {
  let ou = @stochastic.OUProcess::new(0.0, 1.0, 0.0, 0.2)
  let diff = ou.stationary_variance() - 0.02
  let abs_diff = if diff < 0.0 { -diff } else { diff }
  assert_true(abs_diff < 1.0e-9)
}

test "jump_diffusion_positive_prices" {
  let jd = @stochastic.JumpDiffusionProcess::new(100.0, 0.05, 0.2, 2.0, -0.1, 0.15)
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(999UL)
  let path = jd.generate_path(times, rng)
  assert_true(path.terminal_value() > 0.0)
}
