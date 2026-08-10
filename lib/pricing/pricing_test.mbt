///|
test "european_black_scholes_analytical_vs_mc" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let bs_price = @pricing.black_scholes_price(
    @pricing.Call,
    100.0,
    100.0,
    0.05,
    0.2,
    1.0,
  )
  assert_true(bs_price > 10.0)
  assert_true(bs_price < 11.0)

  let rng = @core.RngEngine::default(42UL)
  let mc_res = @pricing.price_european_option_mc(
    @pricing.Call,
    gbm,
    100.0,
    0.05,
    1.0,
    1000,
    rng,
  )
  let diff = if mc_res.price > bs_price {
    mc_res.price - bs_price
  } else {
    bs_price - mc_res.price
  }
  assert_true(diff < 1.0)
}

///|
test "black_scholes_greeks" {
  let delta = @pricing.black_scholes_delta(
    @pricing.Call,
    100.0,
    100.0,
    0.05,
    0.2,
    1.0,
  )
  assert_true(delta > 0.5)
  assert_true(delta < 0.7)

  let gamma = @pricing.black_scholes_gamma(100.0, 100.0, 0.05, 0.2, 1.0)
  assert_true(gamma > 0.01)
}

///|
test "asian_option_mc" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.25, 0.5, 0.75, 1.0]
  let rng = @core.RngEngine::default(999UL)
  let res = @pricing.price_asian_option_mc(
    @pricing.Call,
    @pricing.Arithmetic,
    gbm,
    100.0,
    0.05,
    times,
    500,
    rng,
  )
  assert_true(res.price > 0.0)
  assert_true(res.price < 10.0)
}

///|
test "barrier_option_mc" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.25, 0.5, 0.75, 1.0]
  let rng = @core.RngEngine::default(12345UL)
  let res = @pricing.price_barrier_option_mc(
    @pricing.Call,
    @pricing.DownAndOut,
    gbm,
    100.0,
    90.0,
    0.05,
    times,
    500,
    rng,
  )
  assert_true(res.price >= 0.0)
}

///|
test "american_lsm_premium" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.25, 0.5, 0.75, 1.0]
  let rng1 = @core.RngEngine::default(777UL)
  let rng2 = @core.RngEngine::default(777UL)
  let eur = @pricing.price_european_option_mc(
    @pricing.Put,
    gbm,
    100.0,
    0.05,
    1.0,
    500,
    rng1,
  )
  let amer = @pricing.price_american_option_lsm(
    @pricing.Put,
    gbm,
    100.0,
    0.05,
    times,
    500,
    rng2,
  )
  assert_true(amer.price >= eur.price - 0.5)
}

///|
test "cliquet_option_mc" {
  let gbm = @stochastic.GBMProcess::new(100.0, 0.05, 0.2)
  let times = [0.0, 0.25, 0.5, 0.75, 1.0]
  let rng = @core.RngEngine::default(42UL)
  let res = @pricing.price_cliquet_option_mc(
    gbm, 0.05, times, 0.05, -0.05, 0.15, 0.0, 500, rng,
  )
  assert_true(res.price >= 0.0)
}

///|
test "rainbow_max_of_two_mc" {
  let mat = @multi_asset.Matrix::new(2, 2)
  mat.set(0, 0, 1.0)
  mat.set(0, 1, 0.5)
  mat.set(1, 0, 0.5)
  mat.set(1, 1, 1.0)
  let l = @multi_asset.cholesky_decompose(mat)
  let ma_gbm = @multi_asset.MultiAssetGBM::new(
    [100.0, 100.0],
    [0.05, 0.05],
    [0.2, 0.2],
    l,
  )
  let times = [0.0, 0.5, 1.0]
  let rng = @core.RngEngine::default(777UL)
  let res = @pricing.price_rainbow_option_mc(
    @pricing.MaxOfTwo,
    ma_gbm,
    100.0,
    0.05,
    times,
    500,
    rng,
  )
  assert_true(res.price > 0.0)
}
