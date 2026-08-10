///|
/// Linear, Cubic Spline and Bilinear Surface Interpolation Engines for Yield Curves and Volatility Surfaces.

///|
/// 1D Linear Interpolator.
pub struct LinearInterpolator {
  x : Array[Double]
  y : Array[Double]
}

///|
/// Create a new 1D Linear Interpolator.
pub fn LinearInterpolator::new(
  x : Array[Double],
  y : Array[Double],
) -> LinearInterpolator {
  { x, y }
}

///|
/// Evaluate 1D Linear Interpolation at target point target_x.
pub fn LinearInterpolator::eval(
  self : LinearInterpolator,
  target_x : Double,
) -> Double {
  let len = self.x.length()
  if len == 0 {
    return 0.0
  }
  if len == 1 || target_x <= self.x[0] {
    return self.y[0]
  }
  if target_x >= self.x[len - 1] {
    return self.y[len - 1]
  }

  // Binary search for interval
  let mut low = 0
  let mut high = len - 1
  while high - low > 1 {
    let mid = (low + high) / 2
    if self.x[mid] <= target_x {
      low = mid
    } else {
      high = mid
    }
  }

  let dx = self.x[high] - self.x[low]
  if dx <= 1.0e-15 {
    return self.y[low]
  }
  let t = (target_x - self.x[low]) / dx
  self.y[low] * (1.0 - t) + self.y[high] * t
}

///|
/// Natural Cubic Spline Interpolator.
pub struct CubicSpline {
  x : Array[Double]
  y : Array[Double]
  a : Array[Double]
  b : Array[Double]
  c : Array[Double]
  d : Array[Double]
}

///|
/// Construct Natural Cubic Spline.
pub fn CubicSpline::new(x : Array[Double], y : Array[Double]) -> CubicSpline {
  let n = x.length()
  let a = y.copy()
  let b = Array::make(n, 0.0)
  let c = Array::make(n, 0.0)
  let d = Array::make(n, 0.0)

  if n >= 3 {
    let h = Array::make(n - 1, 0.0)
    let mut i = 0
    while i < n - 1 {
      h[i] = x[i + 1] - x[i]
      i = i + 1
    }

    let alpha = Array::make(n - 1, 0.0)
    let mut i = 1
    while i < n - 1 {
      alpha[i] = 3.0 / h[i] * (a[i + 1] - a[i]) -
        3.0 / h[i - 1] * (a[i] - a[i - 1])
      i = i + 1
    }

    let l = Array::make(n, 1.0)
    let mu = Array::make(n, 0.0)
    let z = Array::make(n, 0.0)

    let mut i = 1
    while i < n - 1 {
      l[i] = 2.0 * (x[i + 1] - x[i - 1]) - h[i - 1] * mu[i - 1]
      let div = if l[i].abs() <= 1.0e-15 { 1.0e-15 } else { l[i] }
      mu[i] = h[i] / div
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / div
      i = i + 1
    }

    let mut j = n - 2
    while j >= 0 {
      c[j] = z[j] - mu[j] * c[j + 1]
      b[j] = (a[j + 1] - a[j]) / h[j] - h[j] * (c[j + 1] + 2.0 * c[j]) / 3.0
      d[j] = (c[j + 1] - c[j]) / (3.0 * h[j])
      j = j - 1
    }
  }

  { x, y, a, b, c, d }
}

///|
/// Evaluate Cubic Spline at target_x.
pub fn CubicSpline::eval(self : CubicSpline, target_x : Double) -> Double {
  let n = self.x.length()
  if n == 0 {
    return 0.0
  }
  if target_x <= self.x[0] {
    return self.y[0]
  }
  if target_x >= self.x[n - 1] {
    return self.y[n - 1]
  }

  let mut idx = 0
  let mut i = 0
  while i < n - 1 {
    if target_x >= self.x[i] && target_x <= self.x[i + 1] {
      idx = i
    }
    i = i + 1
  }

  let dx = target_x - self.x[idx]
  self.a[idx] +
  self.b[idx] * dx +
  self.c[idx] * dx * dx +
  self.d[idx] * dx * dx * dx
}

///|
/// Bilinear Surface Interpolator for Volatility Surfaces S(x, y).
pub struct BilinearSurface {
  x_grid : Array[Double]
  y_grid : Array[Double]
  z_matrix : DenseMatrix
}

///|
/// Create a Bilinear Surface.
pub fn BilinearSurface::new(
  x_grid : Array[Double],
  y_grid : Array[Double],
  z_matrix : DenseMatrix,
) -> BilinearSurface {
  { x_grid, y_grid, z_matrix }
}

///|
/// Evaluate Bilinear Surface at point (target_x, target_y).
pub fn BilinearSurface::eval(
  self : BilinearSurface,
  target_x : Double,
  target_y : Double,
) -> Double {
  let nx = self.x_grid.length()
  let ny = self.y_grid.length()
  if nx == 0 || ny == 0 {
    return 0.0
  }

  let mut ix = 0
  while ix < nx - 1 && target_x > self.x_grid[ix + 1] {
    ix = ix + 1
  }
  let mut iy = 0
  while iy < ny - 1 && target_y > self.y_grid[iy + 1] {
    iy = iy + 1
  }

  let x1 = self.x_grid[ix]
  let x2 = if ix + 1 < nx { self.x_grid[ix + 1] } else { x1 + 1.0 }
  let y1 = self.y_grid[iy]
  let y2 = if iy + 1 < ny { self.y_grid[iy + 1] } else { y1 + 1.0 }

  let z11 = self.z_matrix.get(ix, iy)
  let z12 = if iy + 1 < ny { self.z_matrix.get(ix, iy + 1) } else { z11 }
  let z21 = if ix + 1 < nx { self.z_matrix.get(ix + 1, iy) } else { z11 }
  let z22 = if ix + 1 < nx && iy + 1 < ny {
    self.z_matrix.get(ix + 1, iy + 1)
  } else {
    z11
  }

  let t = if (x2 - x1).abs() <= 1.0e-15 {
    0.0
  } else {
    (target_x - x1) / (x2 - x1)
  }
  let u = if (y2 - y1).abs() <= 1.0e-15 {
    0.0
  } else {
    (target_y - y1) / (y2 - y1)
  }

  (1.0 - t) * (1.0 - u) * z11 +
  t * (1.0 - u) * z21 +
  (1.0 - t) * u * z12 +
  t * u * z22
}
