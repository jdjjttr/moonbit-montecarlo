///|
test "halton_sequence_reproducibility" {
  let h1 = @qmc.HaltonSequence::new(3, 42UL)
  let h2 = @qmc.HaltonSequence::new(3, 42UL)
  let p1 = h1.next_point()
  let p2 = h2.next_point()
  assert_eq(p1[0], p2[0])
  assert_eq(p1[1], p2[1])
  assert_eq(p1[2], p2[2])
}

///|
test "radical_inverse_base2" {
  assert_eq(@qmc.radical_inverse(1, 2), 0.5)
  assert_eq(@qmc.radical_inverse(2, 2), 0.25)
  assert_eq(@qmc.radical_inverse(3, 2), 0.75)
}

///|
test "sobol_sequence_bounds" {
  let sob = @qmc.SobolSequence::new(4)
  let mut i = 0
  while i < 10 {
    let p = sob.next_point()
    let mut d = 0
    while d < 4 {
      assert_true(p[d] >= 0.0)
      assert_true(p[d] < 1.0)
      d = d + 1
    }
    i = i + 1
  }
}

///|
test "lattice_sequence_points" {
  let lat = @qmc.LatticeSequence::new(1021, 2, 76, 0UL)
  let p0 = lat.point(0)
  assert_eq(p0[0], 0.0)
  assert_eq(p0[1], 0.0)
  let p1 = lat.point(1)
  assert_true(p1[0] > 0.0)
  assert_true(p1[1] > 0.0)
}
