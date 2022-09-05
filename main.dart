import 'cidr_parser.dart';

void main(List<String> args) async {
  var box = IPBox("10.88.135.144/6");
  var g = box.parse();
  // if (g != null) {
  //   print("computing...");
  //   await g.toIPList();
  //   g.takeIPs(10).forEach((print));
  // }
}
