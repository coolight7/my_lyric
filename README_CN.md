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

LRC歌词格式的编解码包

## 功能

* 你可以用这个包来解析、编码lrc歌词。lrc格式的歌词看起来像这样:
    * [00.11.22] hello coolight
    * [时间] 歌词内容
* 这个包可以帮助你简便地将lrc格式的 歌词字符串`String` 解析成一个 歌词结构体数组 `List<LyricObject>` 方便你的程序读写。
* `my_lyric` 插件支持了许多标准和非标准的lrc格式, 
* 我们的编解码遵循着 `宽入窄出` 的原则：
  * 解析时容错拉满，尽量提供对各种格式的兼容
  * 编码时只遵循标准格式，以确保其他程序能够正常解析
## 来看看我们支持的格式
### info 歌词信息
* 歌词信息部分，这部分往往是标注了歌词的作者、歌曲名、艺术家等信息，当然也可以是自定义信息。
* 格式为 [key:value]
  * [ti:xxx]
  * [ar:xxx]
  * [hello:xxx]
* 支持单行多个时间标签，自动忽略信息标签外的无用信息
* ......

### lyric 歌词内容
* 歌词内容部分，lrc格式其实已经有一段历史了，网上的lrc歌词格式也有不少是非标准格式的，但别担心，我们已经兼容了绝大部分格式。
* [分:秒.(毫秒 / 10)] 歌词内容 
  * 这种格式看起来像 [01:11.22] hello
* [分:秒:(毫秒 / 10)] 歌词内容 
  * 这种格式看起来像 [01:11:22] hello
  * 它和上一种的区别在于秒和毫秒之间的分割符号不同
* 毫秒部分我们支持 (ms)、(ms / 10)、(ms / 100) 三种，也就是允许毫秒部分为 1位数、两位数、三位数。
* [分:秒] 歌词内容 
  * 这种格式看起来像 [01:11] hello
* 另外这些分、秒、毫秒的数值都支持前置正负号，当出现负值时，最终会将该值置零。

* 支持翻译歌词: 
  * 翻译歌词常见的是格式是该行没有时间，或者是和上一句歌词原文的时间相同:
```lrc
[01:11.22] 歌词内容
歌词翻译

[01:33.22] 歌词内容2
[01:33.22] 歌词翻译2
```

* 一行歌词包含了多个时间:
  * [分:秒.毫秒][分2:秒2] 歌词内容
  * 将被解析为下面两行:
  1. [分:秒.毫秒]歌词内容
  2. [分2:秒2]歌词内容

* 一行包含多个时间，并且时间不连续：
  * [分:秒.毫秒][分2:秒2] 歌词内容1 [分3:秒3] [分4:秒4]歌词内容2
  * 将被解析为一下四行：
  1. [分:秒.毫秒]歌词内容1
  2. [分2:秒2]歌词内容1
  3. [分3:秒3]
  4. [分4:秒4]歌词内容2

* 时间在歌词后面:
  * 歌词内容 [分:秒.毫秒][分1:秒1]

* 上面这些举例基本已经涵盖了常见的标准和非标准lrc格式，如果您有补充，请提issue或PR!

### 转义字符
* 另外，解码info/lyric时都支持`html转义字符`，例如：
```dart
final lyric = MyLyric_c.decodeLrcString(
  "[00:27.000]洛天依&#60;&quot;&#62;",  // [00:27.000]洛天依<">
  parseHtmlEscape: true,               // 启用转换html转义
);
print(lyric.info_ti); // 洛天依<">
```

## 开始使用

* 安装这个包, 请在 `pubspec.yaml` 文件内添加这一行:
```yaml
my_lyric: 
```
* 在你想使用这个包的dart文件内，导入:
```dart
import 'package:my_lyric/MyLyric.dart';
```

## 示例

* 将 lrc 字符串解析为 歌词结构体数组:
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
* 将 上面得到的歌词结构体数组编码回 .lrc 字符串，你还可以将得到的字符串写入文件，并取名后缀.lrc，作为外置歌词文件:
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