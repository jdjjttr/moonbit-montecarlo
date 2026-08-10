///|
/// CSV Trajectory Path Exporter.

///|
/// Format a single SimPath into CSV string representation (Step, Time, Price).
pub fn export_path_csv(path : @core.SimPath) -> String {
  let sb = StringBuilder::new()
  sb.write_string("Step,Time,Price\n")
  let times = path.times()
  let values = path.values()
  let mut i = 0
  while i < values.length() {
    let t_str = if i < times.length() {
      times[i].to_string()
    } else {
      i.to_string()
    }
    sb.write_string(
      i.to_string() + "," + t_str + "," + values[i].to_string() + "\n",
    )
    i = i + 1
  }
  sb.to_string()
}

///|
/// Format a PathMatrix into CSV string representation (PathID, Step0, Step1, ...).
pub fn export_matrix_csv(
  matrix : @core.PathMatrix,
  times : Array[Double],
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("PathID")
  let num_steps = matrix.num_steps()
  let mut s = 0
  while s < num_steps {
    let t_str = if s < times.length() {
      times[s].to_string()
    } else {
      s.to_string()
    }
    sb.write_string(",t_" + t_str)
    s = s + 1
  }
  sb.write_string("\n")

  let num_paths = matrix.num_paths()
  let mut p = 0
  while p < num_paths {
    sb.write_string(p.to_string())
    let mut s = 0
    while s < num_steps {
      sb.write_string("," + matrix.get(p, s).to_string())
      s = s + 1
    }
    sb.write_string("\n")
    p = p + 1
  }
  sb.to_string()
}
