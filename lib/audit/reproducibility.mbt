///|
/// Bit-Exact Reproducibility Audit Trail Engine.

///|
/// Audit Trail Metadata Struct.
pub struct AuditTrail {
  pub seed : UInt64
  pub num_paths : Int
  pub num_steps : Int
  pub path_checksum : UInt64
  pub parameter_hash : UInt64
}

///|
/// Create a new AuditTrail.
pub fn AuditTrail::new(
  seed : UInt64,
  num_paths : Int,
  num_steps : Int,
  matrix : @core.PathMatrix,
) -> AuditTrail {
  let checksum = matrix.compute_checksum()
  let mut param_hash : UInt64 = seed ^
    (num_paths.to_int64().reinterpret_as_uint64() << 16)
  param_hash = param_hash ^ num_steps.to_int64().reinterpret_as_uint64()
  {
    seed,
    num_paths,
    num_steps,
    path_checksum: checksum,
    parameter_hash: param_hash,
  }
}

///|
/// Verify bit-exact reproducibility between two simulation runs.
pub fn AuditTrail::verify(a : AuditTrail, b : AuditTrail) -> Bool {
  a.seed == b.seed &&
  a.num_paths == b.num_paths &&
  a.num_steps == b.num_steps &&
  a.path_checksum == b.path_checksum
}

///|
/// Format AuditTrail into JSON string representation.
pub fn AuditTrail::to_json(self : AuditTrail) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  sb.write_string("  \"seed\": " + self.seed.to_string() + ",\n")
  sb.write_string("  \"num_paths\": " + self.num_paths.to_string() + ",\n")
  sb.write_string("  \"num_steps\": " + self.num_steps.to_string() + ",\n")
  sb.write_string(
    "  \"path_checksum\": \"" + self.path_checksum.to_string() + "\",\n",
  )
  sb.write_string(
    "  \"parameter_hash\": \"" + self.parameter_hash.to_string() + "\"\n",
  )
  sb.write_string("}")
  sb.to_string()
}
