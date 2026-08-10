///|
/// General Linear Algebra Matrix Operations and Vector Utilities.

///|
/// Dense Matrix struct representation.
pub struct DenseMatrix {
  rows : Int
  cols : Int
  data : Array[Double]
}

///|
/// Create a new zero-initialized DenseMatrix.
pub fn DenseMatrix::new(rows : Int, cols : Int) -> DenseMatrix {
  let data = Array::make(rows * cols, 0.0)
  { rows, cols, data }
}

///|
/// Create an identity matrix of size N x N.
pub fn DenseMatrix::identity(n : Int) -> DenseMatrix {
  let mat = DenseMatrix::new(n, n)
  let mut i = 0
  while i < n {
    mat.set(i, i, 1.0)
    i = i + 1
  }
  mat
}

///|
/// Row count.
pub fn DenseMatrix::rows(self : DenseMatrix) -> Int {
  self.rows
}

///|
/// Column count.
pub fn DenseMatrix::cols(self : DenseMatrix) -> Int {
  self.cols
}

///|
/// Get element at (row, col).
pub fn DenseMatrix::get(self : DenseMatrix, row : Int, col : Int) -> Double {
  self.data[row * self.cols + col]
}

///|
/// Set element at (row, col).
pub fn DenseMatrix::set(
  self : DenseMatrix,
  row : Int,
  col : Int,
  val : Double,
) -> Unit {
  self.data[row * self.cols + col] = val
}

///|
/// Copy dense matrix.
pub fn DenseMatrix::copy(self : DenseMatrix) -> DenseMatrix {
  let m = DenseMatrix::new(self.rows, self.cols)
  let len = self.data.length()
  let mut i = 0
  while i < len {
    m.data[i] = self.data[i]
    i = i + 1
  }
  m
}

///|
/// Transpose matrix A^T.
pub fn DenseMatrix::transpose(self : DenseMatrix) -> DenseMatrix {
  let res = DenseMatrix::new(self.cols, self.rows)
  let mut r = 0
  while r < self.rows {
    let mut c = 0
    while c < self.cols {
      res.set(c, r, self.get(r, c))
      c = c + 1
    }
    r = r + 1
  }
  res
}

///|
/// Matrix addition C = A + B.
pub fn DenseMatrix::add(self : DenseMatrix, other : DenseMatrix) -> DenseMatrix {
  let res = DenseMatrix::new(self.rows, self.cols)
  let len = self.data.length()
  let mut i = 0
  while i < len {
    res.data[i] = self.data[i] + other.data[i]
    i = i + 1
  }
  res
}

///|
/// Matrix subtraction C = A - B.
pub fn DenseMatrix::sub(self : DenseMatrix, other : DenseMatrix) -> DenseMatrix {
  let res = DenseMatrix::new(self.rows, self.cols)
  let len = self.data.length()
  let mut i = 0
  while i < len {
    res.data[i] = self.data[i] - other.data[i]
    i = i + 1
  }
  res
}

///|
/// Matrix multiplication C = A * B.
pub fn DenseMatrix::multiply(
  self : DenseMatrix,
  other : DenseMatrix,
) -> DenseMatrix {
  let res = DenseMatrix::new(self.rows, other.cols)
  let mut r = 0
  while r < self.rows {
    let mut c = 0
    while c < other.cols {
      let mut sum = 0.0
      let mut k = 0
      while k < self.cols {
        sum = sum + self.get(r, k) * other.get(k, c)
        k = k + 1
      }
      res.set(r, c, sum)
      c = c + 1
    }
    r = r + 1
  }
  res
}

///|
/// Scalar multiplication C = alpha * A.
pub fn DenseMatrix::scale(self : DenseMatrix, alpha : Double) -> DenseMatrix {
  let res = DenseMatrix::new(self.rows, self.cols)
  let len = self.data.length()
  let mut i = 0
  while i < len {
    res.data[i] = self.data[i] * alpha
    i = i + 1
  }
  res
}

///|
/// Compute Frobenius Norm of Matrix.
pub fn DenseMatrix::frobenius_norm(self : DenseMatrix) -> Double {
  let mut sum_sq = 0.0
  let len = self.data.length()
  let mut i = 0
  while i < len {
    sum_sq = sum_sq + self.data[i] * self.data[i]
    i = i + 1
  }
  sum_sq.sqrt()
}

///|
/// Vector dot product.
pub fn dot_product(v1 : Array[Double], v2 : Array[Double]) -> Double {
  let len = if v1.length() < v2.length() { v1.length() } else { v2.length() }
  let mut sum = 0.0
  let mut i = 0
  while i < len {
    sum = sum + v1[i] * v2[i]
    i = i + 1
  }
  sum
}

///|
/// Vector Euclidean norm (L2 norm).
pub fn vector_norm(v : Array[Double]) -> Double {
  dot_product(v, v).sqrt()
}
