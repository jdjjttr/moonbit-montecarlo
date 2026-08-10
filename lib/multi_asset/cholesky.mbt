///|
/// Dense Matrix and Cholesky Decomposition for Multi-Asset Correlation.

///|
/// Dense 2D Matrix struct.
pub struct Matrix {
  rows : Int
  cols : Int
  data : Array[Double]
}

///|
/// Create a new dense Matrix initialized to zero.
pub fn Matrix::new(rows : Int, cols : Int) -> Matrix {
  let data = Array::make(rows * cols, 0.0)
  { rows, cols, data }
}

///|
/// Get element at row `i` and col `j`.
pub fn Matrix::get(self : Matrix, row : Int, col : Int) -> Double {
  self.data[row * self.cols + col]
}

///|
/// Set element at row `i` and col `j`.
pub fn Matrix::set(self : Matrix, row : Int, col : Int, val : Double) -> Unit {
  self.data[row * self.cols + col] = val
}

///|
/// Matrix row count.
pub fn Matrix::rows(self : Matrix) -> Int {
  self.rows
}

///|
/// Matrix column count.
pub fn Matrix::cols(self : Matrix) -> Int {
  self.cols
}

///|
/// Compute Cholesky Decomposition L of a symmetric positive-definite covariance matrix A = L * L^T.
pub fn cholesky_decompose(mat : Matrix) -> Matrix {
  let n = mat.rows()
  let l = Matrix::new(n, n)
  let mut i = 0
  while i < n {
    let mut j = 0
    while j <= i {
      let mut sum = 0.0
      let mut k = 0
      while k < j {
        sum = sum + l.get(i, k) * l.get(j, k)
        k = k + 1
      }
      if i == j {
        let val = mat.get(i, i) - sum
        let pos_val = if val <= 1.0e-15 { 1.0e-15 } else { val }
        l.set(i, j, pos_val.sqrt())
      } else {
        let l_jj = l.get(j, j)
        let div = if l_jj <= 1.0e-15 { 1.0e-15 } else { l_jj }
        l.set(i, j, (mat.get(i, j) - sum) / div)
      }
      j = j + 1
    }
    i = i + 1
  }
  l
}

///|
/// Multiply lower triangular matrix L by standard normal random vector z.
pub fn multiply_l_vector(l : Matrix, z : Array[Double]) -> Array[Double] {
  let n = l.rows()
  let res = Array::make(n, 0.0)
  let mut i = 0
  while i < n {
    let mut sum = 0.0
    let mut j = 0
    while j <= i {
      sum = sum + l.get(i, j) * z[j]
      j = j + 1
    }
    res[i] = sum
    i = i + 1
  }
  res
}
