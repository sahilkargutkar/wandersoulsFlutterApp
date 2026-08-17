String convertToMongoObjectId(String input) {
  // If the input is already a valid 24-char hex string, return it as is.
  final hexRegex = RegExp(r'^[0-9a-fA-F]{24}$');
  if (hexRegex.hasMatch(input)) {
    return input.toLowerCase();
  }

  // Convert characters to hex representation
  final sb = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final charCode = input.codeUnitAt(i);
    sb.write(charCode.toRadixString(16));
  }

  String hex = sb.toString().toLowerCase();
  // Filter out any non-hex characters just in case
  hex = hex.replaceAll(RegExp(r'[^0-9a-f]'),'');

  if (hex.length < 24) {
    // Pad with'0'to make it 24 characters
    hex = hex.padRight(24,'0');
  } else if (hex.length > 24) {
    // Truncate to exactly 24 characters
    hex = hex.substring(0, 24);
  }
  return hex;
}
