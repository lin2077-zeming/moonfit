///|
// FIT protocol CRC-16 (CRC-16/ARC: reflected poly 0xA001, init 0, no xorout).
//
// Coverage rules, confirmed against every corpus file's stored checksum:
//   * the trailing file CRC spans bytes [0, len-2), i.e. it INCLUDES the two
//     header-CRC bytes when the header is 14 bytes;
//   * the optional header CRC spans bytes [0, 12).
// The independent check value for "123456789" is 0xBB3D, the standard ARC check.

///|
let crc_table : Array[Int32] = [
  0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401, 0xA001, 0x6C00,
  0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
]

///|
pub fn crc16(view : BytesView) -> Int32 {
  let mut crc = 0
  let n = view.length()
  let mut i = 0
  while i < n {
    let byte = view.at(i).to_int()
    let mut tmp = crc_table[crc & 0xF]
    crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ crc_table[byte & 0xF]
    tmp = crc_table[crc & 0xF]
    crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ crc_table[(byte >> 4) & 0xF]
    i = i + 1
  }
  crc & 0xFFFF
}
