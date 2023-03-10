//
// https://www.mikeash.com/pyblog/friday-qa-2017-07-28-a-binary-coder-for-swift.html
// https://github.com/mikeash/BinaryCoder
//

/// A convenient shortcut for indicating something is both encodable and decodable.
public typealias BinaryCodable = BinaryEncodable & BinaryDecodable
