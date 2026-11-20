///|
pub(all) suberror FitError {
  Truncated(String)
  BadSignature
  BadHeaderSize(Int32)
  HeaderCrcMismatch(Int32, Int32)
  FileSizeMismatch(Int64, Int64)
  UnknownBaseType(Int32)
  NoDefinition(Int32)
  BaseValueMismatch(String)
}
