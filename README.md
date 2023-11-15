<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A Flutter package to encode and decode lrc.

## Features

* You can use it to parse music lyric String (.lrc), lrc look like:
    *   [00.11.22] hello coolight
* And than return a object for reading and writing easily.
* `my_lyric` support so many lrc standard and non-standard format,
* we follow `casually decode` and `strictly encode`
* such as:
* info:
  * [ti:xxx]
  * [ar:xxx]
  * [hello:xxx]
  * ......
* lyric:
  * [minute:second.millisecond] lyricContent 
    * like [01:11.22] hello
  * [minute:second:millisecond] lyricContent 
    * like [01:11:22] hello
  * [minute:second] lyricContent 
    * like [01:11] hello
  * translate: 
    * no time Or same time:
```lrc
[01:11.22] lyricContent1
lyricContent1 translate

[01:33.22] lyricContent2
[01:33.22] lyricContent2 translate
```
  * mulit-time in one line: 
    * [minute:second.millisecond][minute2:second2] lyricContent To:
    * [minute:second.millisecond] lyricContent
    * And [minute2:second2] lyricContent
  * time after lyricContent: 
    * lyricContent [minute:second.millisecond]

## Getting started

* install this package, add this line in your `pubspec.yaml`:
```
my_lyric: 
```
* import when you want to use this package:
```dart
import 'package:my_lyric/MyLyric.dart';
```

## Usage

* parse .lrc String to Objects:
```dart
void test() {
    final lrcStr = """
[ti:天后]
[ar:陈势安]
[00:27.43]终于找到借口
[00:30.33]趁着醉意上心头
[00:33.28]表达我所有感受
""";
    final relist = MyLyric_c.decodeLrcString(
        lrcStr,
    );
}
```
* encode to .lrc:
```dart
void test() async {
    // lrc object list
    final List<LyricSrcItemEntity_c> lrcList = [];
    final lrcStr = MyLyric_c.encodeLrcString(
        lrcList,
    );
    /// write to file:
    final file = File("./test.lrc");
    // create file
    if(false == await file.exists()) {
      await file.create(recursive: true);
    }
    // write
    await refile.writeAsString(lrcStr);
}
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
