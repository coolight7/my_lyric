// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';

import 'package:my_lyric/my_lyric.dart';

void main() {
  test_info_ignoreCase();
  test_LyricSrcEntity_c();
  test_parse();
}

void test_info_ignoreCase() {
  test("测试歌词信息[LyricSrcEntity_c.info]忽略大小写", () {
    final lyric = LyricSrcEntity_c();
    lyric.info["HELLO"] = "WORLD";
    lyric.info["wow"] = "value";
    expect(lyric.info["HELLO"], "WORLD");
    expect(lyric.info["hello"], "WORLD");
    expect(lyric.info["WOW"], "value");
    expect(lyric.info["wow"], "value");
  });
}

void test_LyricSrcEntity_c() {
  test("LyricSrcEntity_c", () {
    final lyric = LyricSrcEntity_c();
    expect(lyric.getLrcItemByIndex(0), isNull);
    for (int i = 10; i-- > 0;) {
      lyric.lrc.add(LyricSrcItemEntity_c(time: i.toDouble()));
    }
    expect(lyric.getLrcItemByIndex(0), isNotNull);
    expect(lyric.getLrcItemByIndex(1), isNotNull);
    expect(lyric.getLrcItemByIndex(9), isNotNull);
    expect(lyric.getLrcItemByIndex(-1), isNull);
    expect(lyric.getLrcItemByIndex(10), isNull);
  });
}

void test_parse() {
  test("测试解码空歌词", () {
    expect(MyLyric_c.decodeLrcString(""), isEmpty);
    expect(MyLyric_c.decodeLrcString("      "), isEmpty);
    expect(MyLyric_c.decodeLrcString("\n\n\n"), isEmpty);
    expect(MyLyric_c.decodeLrcString("\r\n\r"), isEmpty);
    expect(MyLyric_c.decodeLrcString("   \r\n\t"), isEmpty);
    expect(MyLyric_c.decodeLrcString(" \n \n \n "), isEmpty);
    expect(MyLyric_c.decodeLrcString("\r \n \r \t \n"), isEmpty);
  });
}
