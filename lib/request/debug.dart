
class Debug {
  static const FILE_NAME = "debug";

  static void debugging(String key, String message) async {
    printWrapped("$key:$message");
  }

  static void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }
}
