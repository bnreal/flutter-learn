class IPAddress {
  int first;
  int second;
  int third;
  int last;

  IPAddress(this.first, this.second, this.third, this.last);
  @override
  String toString() => "$first.$second.$third.$last";
}

//CIDR地址对象 - IPAddress集合
class IPBox {
  List<IPAddress>? ipList;
  String CIDR;
  IPBox(this.CIDR);

  @override
  String toString() => this.CIDR;
  //斜杠前面的ip地址
  IPAddress get baseIP {
    var ipFields = CIDR.split("/")[0].split(".");
    return IPAddress(int.parse(ipFields[0]), int.parse(ipFields[1]),
        int.parse(ipFields[2]), int.parse(ipFields[3]));
  }

  //斜杠后面的数字
  int get mask => int.parse(CIDR.split("/").last);
  //baseIp转换成二进制，共32位1和0的组合
  String get binaryString {
    String first = baseIP.first.toRadixString(2);
    String second = baseIP.second.toRadixString(2);
    String third = baseIP.third.toRadixString(2);
    String last = baseIP.last.toRadixString(2);
    return to8Digits(first) +
        to8Digits(second) +
        to8Digits(third) +
        to8Digits(last);
  }

  //解析CIDR生成一个IPGenerator
  //基本原理：-- 对照cidr.xyz里的图会比较直观
  //将BaseIP转换成二进制，每个数字8位共32位。根据mask值来确定可变的数字在哪个位置上。
  //如：/24 -- 有3个8位，也就是前三个数字都是不变的，如果是/26,也有3个8，剩余2位在第四个
  //数字上，保持这两位不变，将剩余6位的1全部置0就是网络地址，将剩余6位的0全部置1就是广播
  //地址。其他数字类似，如/11，只有1个8，也就是在第二个数字上开始变化（第二个数字的前3位不变）
  //第三位和第四位都是0-255的。
  IPGenerator? parse() {
    int position = mask ~/ 8; //四个数字中有几个是固定的,如/21 - 前二个数字是固定的
    var adressFixed = ""; //ip address 中确定不变的部分
    String binaryString = ""; //ip address中的某位数字转换成的8位二制字符串
    int beginIndex = mask - 8 * position; //8位二进制字符串中变化部分开始的位置
    switch (position) {
      case 0:
        adressFixed = "";
        binaryString = to8Digits(baseIP.first.toRadixString(2));
        break;

      case 1:
        adressFixed = "${baseIP.first}";
        binaryString = to8Digits(baseIP.second.toRadixString(2));
        break;
      case 2:
        adressFixed = "${baseIP.first}.${baseIP.second}";
        binaryString = to8Digits(baseIP.third.toRadixString(2));
        break;
      case 3:
        adressFixed = "${baseIP.first}.${baseIP.second}.${baseIP.third}";
        //计算主机号-ip中的第四位。
        binaryString = to8Digits(baseIP.last.toRadixString(2));
        break;
    }
    var ipRange = compute(binaryString, beginIndex);
    print(ipRange);
    return ipRange == null ? null : IPGenerator(adressFixed, ipRange, position);
  }

  //计算根据mask计算对应IP位置的数字
  IntegerRange? compute(String binaryString, int beginIndex) {
    if (binaryString.isEmpty || beginIndex == -1) return null;
    String remaining = "0" * (8 - beginIndex);
    String startBinary = binaryString.replaceRange(beginIndex, null, remaining);
    remaining = "1" * (8 - beginIndex);
    int min = int.parse(startBinary, radix: 2);
    String endBinary = binaryString.replaceRange(beginIndex, null, remaining);
    int max = int.parse(endBinary, radix: 2);
    return IntegerRange(min, max);
  }
}

//IP生成器 -- 根据range和该range在IP中的位置计算出ip
class IPGenerator {
  String fixedPart;
  IntegerRange ipNumberRange;
  int position; //ip地址的四个数字中，从左至右0,1,2,3
  int lastIndex; //用于取出ip时跟踪记录在列表中的位置，相当于cursor
  List<String>? ipList;
  IPGenerator(this.fixedPart, this.ipNumberRange, this.position,
      {this.lastIndex = 0});

  void take(int count) {}

  //每次调用都会按列表顺序取出count数量的ip
  Iterable<String> takeIPs(int count) sync* {
    for (int i = 0; lastIndex < ipList!.length && i < count; i++) {
      yield ipList![lastIndex];
      lastIndex++;
    }
  }

  //根据range计算并生成ip address列表
  Future<void> toIPList() async {
    var hosts = <String>[];
    switch (position) {
      case 0:
        for (int first = ipNumberRange.start;
            first <= ipNumberRange.end;
            first++) {
          for (int second = 0; second <= 255; second++) {
            for (int third = 0; third <= 255; third++) {
              for (int last = 0; last <= 255; last++) {
                hosts.add("$first.$second.$third.$last");
              }
            }
          }
        }
        break;
      case 1:
        for (int second = ipNumberRange.start;
            second <= ipNumberRange.end;
            second++) {
          for (int third = 0; third <= 255; third++) {
            for (int last = 0; last <= 255; last++) {
              hosts.add("$fixedPart.$second.$third.$last");
            }
          }
        }
        break;
      case 2:
        for (int third = ipNumberRange.start;
            third <= ipNumberRange.end;
            third++) {
          for (int last = 1; last <= 254; last++) {
            hosts.add("$fixedPart.$third.$last");
          }
        }
        break;
      case 3:

        /// 最后一种情况，最大255和最小(0或其他)分别为（广播地址和网络地址），所以要去掉
        for (int i = ipNumberRange.start + 1; i < ipNumberRange.end; i++) {
          hosts.add("$fixedPart.$i");
        }
        break;
    }
    this.ipList = hosts;
  }
}

//一个int数字Range
class IntegerRange {
  int start;
  int end;
  IntegerRange(this.start, this.end);

  dynamic get value => start == end ? end : this;
  @override
  String toString() => start == end ? "Value:$start" : "Values: $start...$end";
  int get count => start == end ? 1 : end - start;
}

//dart转换二进制后，不够8位的高位补0
String to8Digits(String binaryString) {
  int count = 8 - binaryString.length;
  for (var i = 0; i < count; i++) {
    binaryString = "0" + binaryString;
  }
  return binaryString;
}
