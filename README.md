cidr_parser： dart 练习项目，功能：解析cidr地址，生成ip地址列表（生成器），生成器可按指定数量yield ip地址。
example:
void main(List<String> args) async {
  var box = IPBox("10.88.135.144/6");
  var g = box.parse();
  if (g != null) {
    print("computing...");
    await g.toIPList();
    g.takeIPs(10).forEach((print));
 }
}