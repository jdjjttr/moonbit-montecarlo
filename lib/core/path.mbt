///|
/// Simulation Trajectory Path representation and Audit Logging.

///|
/// Representation of a single simulated asset price path across discrete time grid.
pub struct SimPath {
  times : Array[Double]
  values : Array[Double]
}

///|
/// Create a new simulation trajectory path.
pub fn SimPath::new(times : Array[Double], values : Array[Double]) -> SimPath {
  { times, values }
}

///|
/// Length of time steps in path.
pub fn SimPath::length(self : SimPath) -> Int {
  self.values.length()
}

///|
/// Time vector reference.
pub fn SimPath::times(self : SimPath) -> Array[Double] {
  self.times
}

///|
/// Values vector reference.
pub fn SimPath::values(self : SimPath) -> Array[Double] {
  self.values
}

///|
/// Get asset price value at step index `i`.
pub fn SimPath::get(self : SimPath, index : Int) -> Double {
  self.values[index]
}

///|
/// Initial asset price (S_0).
pub fn SimPath::initial_value(self : SimPath) -> Double {
  if self.values.length() == 0 {
    0.0
  } else {
    self.values[0]
  }
}

///|
/// Terminal asset price (S_T).
pub fn SimPath::terminal_value(self : SimPath) -> Double {
  let len = self.values.length()
  if len == 0 {
    0.0
  } else {
    self.values[len - 1]
  }
}

///|
/// Maximum asset price reached along path.
pub fn SimPath::max_value(self : SimPath) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mut m = self.values[0]
  let mut i = 1
  while i < self.values.length() {
    if self.values[i] > m {
      m = self.values[i]
    }
    i = i + 1
  }
  m
}

///|
/// Minimum asset price reached along path.
pub fn SimPath::min_value(self : SimPath) -> Double {
  if self.values.length() == 0 {
    return 0.0
  }
  let mut m = self.values[0]
  let mut i = 1
  while i < self.values.length() {
    if self.values[i] < m {
      m = self.values[i]
    }
    i = i + 1
  }
  m
}

///|
/// Arithmetic average asset price along path.
pub fn SimPath::arithmetic_mean(self : SimPath) -> Double {
  let len = self.values.length()
  if len == 0 {
    return 0.0
  }
  let mut sum = 0.0
  let mut i = 0
  while i < len {
    sum = sum + self.values[i]
    i = i + 1
  }
  sum / len.to_double()
}

///|
/// Geometric average asset price along path.
pub fn SimPath::geometric_mean(self : SimPath) -> Double {
  let len = self.values.length()
  if len == 0 {
    return 0.0
  }
  let mut log_sum = 0.0
  let mut i = 0
  while i < len {
    if self.values[i] > 0.0 {
      log_sum = log_sum + @math.ln(self.values[i])
    }
    i = i + 1
  }
  @math.exp(log_sum / len.to_double())
}

///|
/// Trajectory path matrix for multi-asset or batch simulations.
pub struct PathMatrix {
  num_paths : Int
  num_steps : Int
  // Flat 1D array storing paths in row-major layout: data[path_idx * num_steps + step_idx]
  data : Array[Double]
}

///|
/// Create a new PathMatrix.
pub fn PathMatrix::new(num_paths : Int, num_steps : Int) -> PathMatrix {
  let data = Array::make(num_paths * num_steps, 0.0)
  { num_paths, num_steps, data }
}

///|
/// Set value at specific path and step index.
pub fn PathMatrix::set(
  self : PathMatrix,
  path_idx : Int,
  step_idx : Int,
  val : Double,
) -> Unit {
  self.data[path_idx * self.num_steps + step_idx] = val
}

///|
/// Get value at specific path and step index.
pub fn PathMatrix::get(
  self : PathMatrix,
  path_idx : Int,
  step_idx : Int,
) -> Double {
  self.data[path_idx * self.num_steps + step_idx]
}

///|
/// Number of simulated paths.
pub fn PathMatrix::num_paths(self : PathMatrix) -> Int {
  self.num_paths
}

///|
/// Number of time steps.
pub fn PathMatrix::num_steps(self : PathMatrix) -> Int {
  self.num_steps
}

///|
/// Extract a single path as a SimPath given a time grid array.
pub fn PathMatrix::get_path(
  self : PathMatrix,
  path_idx : Int,
  times : Array[Double],
) -> SimPath {
  let values = Array::make(self.num_steps, 0.0)
  let start = path_idx * self.num_steps
  let mut i = 0
  while i < self.num_steps {
    values[i] = self.data[start + i]
    i = i + 1
  }
  SimPath::new(times, values)
}

///|
/// Calculate FNV-1a 64-bit checksum hash over path matrix values for bit-exact audit.
pub fn PathMatrix::compute_checksum(self : PathMatrix) -> UInt64 {
  let mut hash : UInt64 = 0xcbf29ce484222325UL
  let fnv_prime : UInt64 = 0x100000001b3UL
  let len = self.data.length()
  let mut i = 0
  while i < len {
    let double_bits = self.data[i].reinterpret_as_uint64()
    let mut b = 0
    let mut current_bits = double_bits
    while b < 8 {
      let byte_val = (current_bits & 0xffUL).to_uint()
      hash = hash ^ byte_val.to_uint64()
      hash = hash * fnv_prime
      current_bits = current_bits >> 8
      b = b + 1
    }
    i = i + 1
  }
  hash
}
