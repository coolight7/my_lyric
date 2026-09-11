// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:collection';
import 'dart:convert' as convert;
import 'dart:math' as math;
import 'package:html_unescape_xx/html_unescape.dart';
import 'package:string_util_xx/string_util_xx.dart';
import 'package:util_xx/util_xx.dart';

enum LyricTimeType_e {
  Unknown,
  Verbatim,
  Line,
}

class LyricTimeType_c {
  static int toInt(LyricTimeType_e type) {
    switch (type) {
      case LyricTimeType_e.Unknown:
        return 0;
      case LyricTimeType_e.Verbatim:
        return 1;
      case LyricTimeType_e.Line:
        return 2;
    }
  }

  static LyricTimeType_e? toEnum(int? type) {
    switch (type) {
      case 0:
        return LyricTimeType_e.Unknown;
      case 1:
        return LyricTimeType_e.Verbatim;
      case 2:
        return LyricTimeType_e.Line;
    }
    return null;
  }
}

class LyricSrcTime_c {
  double time;
  int index;

  /// 将时间格式化为标准 lrc 格式的时间
  String get timeStr => Lyricxx_c.formatLyricTimeStr(time);

  LyricSrcTime_c({
    required this.time,
    required this.index,
  });

  factory LyricSrcTime_c.fromJson(Map json) {
    final json_time = json["time"];
    double time = 0;
    if (json_time is double) {
      time = json_time;
    } else if (json_time is int) {
      time = json_time.toDouble();
    }
    return LyricSrcTime_c(
      time: time,
      index: json["index"] ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "time": time,
      "index": index,
    };
  }

  @override
  bool operator ==(Object other) {
    return (other is LyricSrcTime_c &&
        other.index == index &&
        other.time == time);
  }

  @override
  int get hashCode => (index.hashCode + time.hashCode);

  LyricSrcTime_c copyWith({double? time, int? index}) {
    return LyricSrcTime_c(
      time: time ?? this.time,
      index: index ?? this.index,
    );
  }
}

class LyricSrcItemEntity_c {
  /// * 歌词时间戳，单位：秒
  /// * 如果是翻译，该值为负
  double time = 0;

  /// 歌词内容
  String content = "";

  /// 逐字时间戳
  /// 如果 length >= 2，即为逐字效果
  List<LyricSrcTime_c> timelist;

  List<LyricSrcTime_c>? get maySimulateTimelist {
    if (timelist.length >= 2) {
      return timelist;
    } else if (canSimulateVerbatimTime) {
      final useTime = simulateStart ?? time;
      return (content.length > 2)
          ? [
              LyricSrcTime_c(time: useTime, index: 0),
              // 与下一行的时间留出间隔
              LyricSrcTime_c(
                  time: simulateEnd! -
                      math.min((simulateEnd! - useTime) * 0.1, 0.7),
                  index: content.length),
            ]
          : [
              LyricSrcTime_c(time: useTime, index: 0),
              LyricSrcTime_c(time: simulateEnd!, index: content.length),
            ];
    }
    return null;
  }

  /// 可用于模拟逐字歌词
  /// - 不存储 toJson
  /// - [simulateStart] 当 time < 0 时，翻译需要取上一行的时间，因此可以预设到 simulateStart
  double? simulateStart, simulateEnd;

  bool get canSimulateVerbatimTime =>
      ((null != simulateStart || time >= 0) && null != simulateEnd);

  bool get isRealVerbatimTime => (timelist.length >= 2);

  /// 这一行是否为逐字歌词
  bool get isVerbatimTime => (isRealVerbatimTime || canSimulateVerbatimTime);

  /// 这一行是否为逐行歌词
  bool get isLineTime => (false == isVerbatimTime);

  LyricSrcItemEntity_c({
    this.time = 0,
    this.content = "",
    this.simulateStart,
    this.simulateEnd,
    List<LyricSrcTime_c>? timelist,
  }) : timelist = timelist ?? [];

  /// 将时间格式化为标准 lrc 格式的时间
  String get timeStr => Lyricxx_c.formatLyricTimeStr(time);

  factory LyricSrcItemEntity_c.fromJson(Map json) {
    final json_time = json["time"];
    double time = 0;
    if (json_time is double) {
      time = json_time;
    } else if (json_time is int) {
      time = json_time.toDouble();
    }
    final json_simulateStart = json["simulateStart"];
    double? simulateStart;
    if (null != json_simulateStart) {
      if (json_simulateStart is double) {
        simulateStart = json_simulateStart;
      } else if (json_simulateStart is int) {
        simulateStart = json_simulateStart.toDouble();
      }
    }
    final json_simulateEnd = json["simulateEnd"];
    double? simulateEnd;
    if (null != json_simulateEnd) {
      if (json_simulateEnd is double) {
        simulateEnd = json_simulateEnd;
      } else if (json_simulateEnd is int) {
        simulateEnd = json_simulateEnd.toDouble();
      }
    }
    final result = LyricSrcItemEntity_c(
      time: time,
      simulateStart: simulateStart,
      simulateEnd: simulateEnd,
      content: json["content"] ?? "",
    );
    final list = json["timelist"];
    if (list is List && list.isNotEmpty) {
      for (final item in list) {
        // 兼容两种形式：JSON 解析出的 Map，以及旧数据中直接存放的对象
        if (item is Map) {
          result.timelist.add(LyricSrcTime_c.fromJson(item));
        } else if (item is LyricSrcTime_c) {
          result.timelist.add(item.copyWith());
        }
      }
    }
    return result;
  }

  /// [toJson] 返回的必须是可 JSON 化的数据（不能直接放入实体对象），
  /// 否则 [fromJson] 无法解析 `toJson()` 的直接结果
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "time": time,
      "content": content,
      if (timelist.isNotEmpty)
        "timelist": List.generate(timelist.length, (i) => timelist[i].toJson()),
    };
  }

  Map<String, dynamic> toJsonAppendSimulateTime() {
    return <String, dynamic>{
      "time": time,
      "content": content,
      if (timelist.isNotEmpty)
        "timelist": List.generate(timelist.length, (i) => timelist[i].toJson()),
      if (null != simulateStart) "simulateStart": simulateStart,
      if (null != simulateEnd) "simulateEnd": simulateEnd,
    };
  }

  LyricSrcItemEntity_c copyWith({
    double? time,
    String? content,
    List<LyricSrcTime_c>? timelist,
  }) {
    final list = timelist ?? this.timelist;
    final uselist = List.generate(list.length, (i) {
      return list[i].copyWith();
    });
    return LyricSrcItemEntity_c(
      time: time ?? this.time,
      content: content ?? this.content,
      timelist: uselist,
    );
  }
}

class LyricSrcEntity_c {
  static const String KEY_al = "al";
  static const String KEY_ar = "ar";
  static const String KEY_by = "by";
  static const String KEY_offset = "offset";
  static const String KEY_ti = "ti";
  // 创建此LRC文件的播放器或编辑器
  static const String KEY_re = "re";
  // 程序的版本
  static const String KEY_ve = "ve";

  /// 歌词信息
  /// * 可使用[s_createInfo]构造，让map的key忽略大小写
  HashMap<String, dynamic> info;

  /// 歌词内容
  List<LyricSrcItemEntity_c> lrc;

  LyricTimeType_e timeType;

  /// ## 是否 信息[info] 和 歌词[lrc] 都为空
  bool get isEmpty => (info.isEmpty && lrc.isEmpty);

  /// ## 是否 信息[info] 和 歌词[lrc] 中至少一方非空
  bool get isNotEmpty => (info.isNotEmpty || lrc.isNotEmpty);

  /// ## 粗略计算 [lrc] 编码为 增强型 lrc 后的字符串总长度
  int get lrcStdFormatLen {
    int len = 0;
    for (final item in lrc) {
      // content.len + [mm:ss.ff] 默认长度 10 + 换行符 1
      len += item.content.length + item.timelist.length * 10 + 1;
    }
    return len;
  }

  LyricSrcEntity_c({
    HashMap<String, dynamic>? info,
    List<LyricSrcItemEntity_c>? lrc,
    this.timeType = LyricTimeType_e.Unknown,
  })  : info = info ?? s_createInfo(),
        lrc = lrc ?? [];

  static HashMap<String, dynamic> s_createInfo() {
    return HashMap<String, dynamic>(
      equals: (p0, p1) {
        return StringUtilxx_c.isIgnoreCaseEqual(p0, p1);
      },
      hashCode: (p0) {
        return p0.toLowerCase().hashCode;
      },
      isValidKey: (p0) {
        return (p0 is String);
      },
    );
  }

  /// 歌曲标题
  String? get info_ti => getInfoItemWithString(KEY_ti);

  /// 歌手
  String? get info_ar => getInfoItemWithString(KEY_ar);

  /// 专辑名称
  String? get info_al => getInfoItemWithString(KEY_al);

  /// LRC作者，指制作该LRC歌词的人
  String? get info_by => getInfoItemWithString(KEY_by);

  /// 针对整体歌词时间的偏移量，单位毫秒ms
  double? get info_offset {
    final result = getInfoItemWithString(KEY_offset);
    if (null == result) {
      return null;
    }
    return double.tryParse(result);
  }

  /// 创建此LRC文件的播放器或编辑器
  String? get info_re => getInfoItemWithString(KEY_re);

  /// 程序的版本
  String? get info_ve => getInfoItemWithString(KEY_ve);

  String? get info_title_Artist {
    String? infoName = StringUtilxx_c.removeBetweenSpaceMayNull(
      info_ti,
    );
    if (null != infoName) {
      if (infoName.isEmpty) {
        infoName = null;
      } else {
        final infoAritist = StringUtilxx_c.removeBetweenSpaceMayNull(
          info_ar,
        );
        if (null != infoAritist && infoAritist.isNotEmpty) {
          infoName = "$infoName - $infoAritist";
        }
      }
    }
    return infoName;
  }

  /// ## 根据 [key] 查找对应的信息
  /// * 不存在或非 [String] 类型时返回 [Null]
  String? getInfoItemWithString(String key) {
    final result = info[key];
    return (result is String) ? result : null;
  }

  /// ## 根据 [index] 获取lrc单项
  /// * 当 [index] 越界时返回 [Null]
  LyricSrcItemEntity_c? getLrcItemByIndex(int index) {
    if (index < 0 || index >= lrc.length) {
      return null;
    }
    return lrc[index];
  }

  /// - 根据 [lrc] 更新 [timeType]
  void updateTimeType() {
    timeType = LyricTimeType_e.Unknown;
    for (final item in lrc) {
      if (item.isVerbatimTime) {
        timeType = LyricTimeType_e.Verbatim;
        break;
      } else if (item.time > 0) {
        timeType = LyricTimeType_e.Line;
      }
    }
  }

  void simulateVerbatim() {
    // if (timeType != LyricTimeType_e.Verbatim) {}
    // 倒序处理，取下一行的开始时间作为上一行的结束时间
    double? nextLineTime = lrc.lastOrNull?.time;
    for (int i = lrc.length - 1; i >= 0; --i) {
      final prevLrc = (i > 0) ? lrc[i - 1] : null;
      final time = lrc[i].time;
      if (false == lrc[i].isRealVerbatimTime) {
        lrc[i].simulateStart = (time >= 0)
            ? time
            // 翻译，时间等同上一行
            : prevLrc?.time;

        // 如果上一行是逐字歌词，且当前行是翻译歌词，则优先取翻译原文行(上一行)结束时间，
        // 否则取下一行的起始时间
        if ((time < 0 || time == prevLrc?.time) &&
            true == prevLrc?.isRealVerbatimTime) {
          // 当前行是翻译歌词，且上一行是逐字歌词
          lrc[i].simulateEnd = prevLrc?.timelist.lastOrNull?.time;
        }
        lrc[i].simulateEnd ??= nextLineTime;
      }
      if (time >= 0 && time != prevLrc?.time) {
        // 绕过翻译原文行，把真正下一行的时间带到上一行的循环中
        nextLineTime = time;
      }
    }
  }

  /// ## 判断 [index] 指定的 [lrc] 是否为翻译歌词的原文
  bool isTranslate_original(int index) {
    return ((index + 1) < lrc.length &&
        (lrc[index].time >= 0) &&
        (lrc[index + 1].time < 0 || (lrc[index + 1].time == lrc[index].time)));
  }

  /// ## 判断 [index] 指定的 [lrc] 是否为翻译歌词的译文
  /// * [isTr_original] 前置判断 [index] 指向的不是原文，显式传入可减少判断，不指定时
  /// 会调用 [isTranslate_original] 判断
  bool isTranslate(
    int index, {
    bool? isTr_original,
  }) {
    return (false == (isTr_original ?? isTranslate_original(index)) &&
        ((index - 1) >= 0 &&
            (lrc[index - 1].time >= 0) &&
            (lrc[index].time < 0 || (lrc[index].time == lrc[index - 1].time))));
  }

  /// ## 判断 [index] 指向的位置是否是应当高亮显示的翻译歌词原文
  /// * [index] 待判断的歌词下标
  /// * [selectIndex] 应当高亮的歌词下标
  /// * [isTr_original] 是否 [index] 是翻译歌词原文，传入可减少判断，不指定是会
  /// 调用 [isTranslate_original] 判断
  bool isSelectTranslate_original(
    int index,
    int selectIndex, {
    bool? isTr_original,
  }) {
    return (isTr_original ?? isTranslate_original(index)) &&
        (selectIndex - index == 1);
  }

  /// ## 判断 [index] 指向的歌词是否应当高亮显示
  bool isSelectTranslate(int index, int selectIndex) {
    return (index == selectIndex);
  }

  /// ## 判断 [index] 指向的歌词是否应当高亮显示
  bool isSelectLrc(
    int index,
    int selectIndex, {
    bool? isTr_original,
  }) {
    return (isSelectTranslate(index, selectIndex) ||
        isSelectTranslate_original(
          index,
          selectIndex,
          isTr_original: isTr_original,
        ));
  }

  factory LyricSrcEntity_c.fromJson(Map json) {
    if (json.isEmpty) {
      return LyricSrcEntity_c();
    }
    final resrc = LyricSrcEntity_c(
      timeType:
          LyricTimeType_c.toEnum(json["timeType"]) ?? LyricTimeType_e.Unknown,
    );
    // lrc
    final lrc = json["lrc"];
    List? list;
    if (lrc is List) {
      list = lrc;
    } else if (lrc is String) {
      if (lrc.isNotEmpty) {
        list = convert.jsonDecode(lrc);
      } else {
        list = [];
      }
    }
    if (null != list) {
      for (int i = 0; i < list.length; ++i) {
        final item = list[i];
        // 兼容两种形式：JSON 解析出的 Map，以及直接由 toJson() 得到的实体对象
        if (item is Map) {
          resrc.lrc.add(LyricSrcItemEntity_c.fromJson(item));
        } else if (item is LyricSrcItemEntity_c) {
          resrc.lrc.add(item.copyWith());
        }
      }
    }
    // info
    json.forEach((key, value) {
      if (key != "lrc") {
        resrc.info[key] = value;
      }
    });
    return resrc;
  }

  Map<String, dynamic> toJson({
    bool appendSimulateTime = false,
  }) {
    final remap = <String, dynamic>{};
    // 将 [info] 和 [lrc] 合并到一个map中
    info.forEach((key, value) {
      if (key != "lrc") {
        remap[key] = value;
      }
    });
    if (appendSimulateTime) {
      remap["lrc"] = List.generate(lrc.length, (i) {
        return lrc[i].toJsonAppendSimulateTime();
      });
    } else {
      remap["lrc"] = List.generate(lrc.length, (i) => lrc[i].toJson());
    }
    remap["timeType"] = LyricTimeType_c.toInt(timeType);
    return remap;
  }

  LyricSrcEntity_c copyWith({
    LyricTimeType_e? timeType,
    HashMap<String, dynamic>? info,
    List<LyricSrcItemEntity_c>? lrc,
  }) {
    final reSrc = LyricSrcEntity_c(
      info: info ?? this.info,
      timeType: timeType ?? this.timeType,
    );
    if (null != lrc) {
      reSrc.lrc = lrc;
      if (null == timeType) {
        reSrc.updateTimeType();
      }
    } else {
      for (int i = 0, len = this.lrc.length; i < len; ++i) {
        reSrc.lrc.add(this.lrc[i].copyWith());
      }
    }
    return reSrc;
  }
}

enum _ParseLyricType_e {
  Lrc,
  Info,
}

/// 解析歌词行使用的结构体
class _ParseLyricObj_c {
  final _ParseLyricType_e type;
  final String? infoKey;
  final double? time;
  String content;
  List<LyricSrcTime_c> timelist;

  _ParseLyricObj_c({
    this.infoKey,
    required this.type,
    required this.content,
    this.time,
    List<LyricSrcTime_c>? timelist,
  }) : timelist = timelist ?? [];
}

class _ParseLyricTagItem_c {
  final int start, length;
  final RegExpMatch? timeTag;
  final String? content;

  _ParseLyricTagItem_c({
    required this.start,
    required this.length,
    required this.timeTag,
    required this.content,
  });
}

class Lyricxx_c {
  static final defLimitContentSet = <String>{
    "//",
    "/",
    "null",
  };

  Lyricxx_c._();

  static bool defLimitContent(String content) {
    return false == defLimitContentSet.contains(content);
  }

  /// 移除字符串两边的空白符号，两边各保留一个
  static String removeBetweenSpaceSaveOne(
    String str, {
    bool removeLine = true,
  }) {
    if (str.isEmpty) {
      return str;
    }
    int left = 0, right = str.length - 1;
    for (; right >= left; --right) {
      if (str[right] != ' ' &&
          str[right] != '\t' &&
          (false == removeLine || (str[right] != '\r' && str[right] != '\n'))) {
        break;
      }
    }
    for (; left <= right; ++left) {
      if (str[left] != ' ' &&
          str[left] != '\t' &&
          (false == removeLine || (str[left] != '\r' && str[left] != '\n'))) {
        break;
      }
    }
    bool leftSpace = (left != 0), rightSpace = (right != (str.length - 1));
    if (left <= right) {
      return (leftSpace ? ' ' : '') +
          str.substring(left, right + 1) +
          (rightSpace ? ' ' : '');
    } else {
      // 移除后是空字符串
      if (leftSpace || rightSpace) {
        // 左右原本有空白符，保留一个
        return " ";
      }
      return "";
    }
  }

  /// ## 解析单行歌词
  /// - [removeEmptyLine] 是否删除包含歌词时间，但内容却为空的行
  /// - [parseHtmlEscape] 转换html的转义字符
  /// - [tryAutoDistinguishByWord] :
  ///     - true 如果单行歌词中包含了多个不连续的时间戳，尝试自动
  /// 根据单词长度区分为逐字歌词时间戳还是逐行歌词时间戳并自动换行
  ///     - false 对于不连续的时间戳统一认为是逐字歌词时间戳
  /// - [tryAutoDistinguishLength] 根据单词长度区分
  static List<_ParseLyricObj_c>? _decodeLrcStrLine(
    String line, {
    bool removeEmptyLine = true,
    bool parseHtmlEscape = true,
    bool tryAutoDistinguishByWord = true,
    int tryAutoDistinguishLength = 5,
  }) {
    if (parseHtmlEscape) {
      // 转义部分html字符
      try {
        line = HtmlUnescapeSmall().convert(line);
      } catch (e) {
        print(e);
      }
    }

    /// 匹配信息标签，支持单行多标签和忽略信息标签外的值
    /// * tr
    /// * ar
    /// * al
    /// * by
    /// * offset
    /// * ...
    /// * 非数字开头
    final result_info = RegExp(
      r"\[([^\d\:]*)\:([^\]]*)\]",
    ).allMatches(line);
    if (result_info.isNotEmpty) {
      final relist = <_ParseLyricObj_c>[];
      for (final item in result_info) {
        final key = item[1];
        if (null != key) {
          relist.add(_ParseLyricObj_c(
            infoKey: StringUtilxx_c.removeBetweenSpace(key),
            type: _ParseLyricType_e.Info,
            content: StringUtilxx_c.removeBetweenSpace(item[2] ?? ""),
          ));
        }
      }
      return relist;
    }

    /// 匹配单个时间戳
    /// * 支持 [mm:ss]
    /// * 支持 [mm:ss:ff]
    /// * 支持 [mm:ss.ff]
    /// * 支持指定数值正负号+-，但出现负号时，将会将其时间置零
    /// * ff 为 1~3 位小数（按位数分别除以 10/100/1000），超出 3 位视为异常并置0
    /// * 注意：不支持 [hh:mm:ss]，`[01:02:03]` 会被解析为 1分2秒03毫秒
    const tagTimeItemReg =
        r"[\[\<]([+-]?\d+)\:([+-]?\d+)([.:]([+-]?\d+))?[\]\>]";

    /// 匹配歌词时间戳
    final result = RegExp(tagTimeItemReg).allMatches(line);
    if (result.isNotEmpty) {
      // 将被返回的歌词数组
      final relist = <_ParseLyricObj_c>[];
      // 记录最近的一行歌词项，用于附加逐字歌词
      _ParseLyricObj_c? lastLrcItem;
      // 记录上一次操作的尾部坐标
      int lastIndex = 0;
      // 将[line]按`时间戳`、`内容`分段保持顺序存入[resultList]
      final resultList = <_ParseLyricTagItem_c>[];
      // 单行包含多个时间且不连续时，可能是`逐字歌词`或是`不换行歌词`
      bool maybeHasWordTime = false;
      for (final item in result) {
        final start = item.start;
        final end = item.end;
        if (start > lastIndex) {
          if (lastIndex != 0) {
            maybeHasWordTime = (result.length > 1);
          }
          // [item]之前有[content]
          // 截取[content]加入分段列表
          final content = removeBetweenSpaceSaveOne(line.substring(
            lastIndex,
            start,
          ));
          // 逐字歌词保留空字符串，确保时间对应的[content]正确，比如：
          // [00:37][000:47.11]abc [000:50.11] [00:57:33]cool
          // 应保留[000:50.11]对应一个空字符串，否则会被误认为和后面的[00:57:33]cool是一起的
          resultList.add(_ParseLyricTagItem_c(
            start: start,
            length: start - lastIndex,
            timeTag: null,
            content: content,
          ));
        }
        // 添加[item]
        resultList.add(_ParseLyricTagItem_c(
          start: start,
          length: end - start,
          timeTag: item,
          content: null,
        ));
        lastIndex = end;
      }
      if (lastIndex < line.length) {
        // 最后一段字符串作为[content]
        resultList.add(_ParseLyricTagItem_c(
          start: lastIndex,
          length: line.length - lastIndex,
          timeTag: null,
          content: removeBetweenSpaceSaveOne(line.substring(
            lastIndex,
          )),
        ));
      }

      // 遍历 [resultList] 解析歌词行
      // 记录过往最近的一个[content]，辅助后置时间戳使用
      String? last_content;
      // 记录当前时间戳是否是连续时间戳的开头或中间
      bool currentIsContinuousTimeTagSM = false;
      //  记录当前时间戳是否是连续时间戳的结尾
      // ignore: unused_local_variable
      bool currentIsContinuousTimeTagEnd = false;
      for (int i = 0; i < resultList.length; ++i) {
        final item = resultList[i];
        if (null != item.timeTag) {
          // 是时间戳 [timeTag]
          String? content;
          bool isWordTime = maybeHasWordTime;
          // 先从[item]的位置向右寻找第一个歌词内容，如果没有则从[item]的位置向左寻找
          for (int j = i + 1; j < resultList.length; ++j) {
            final current = resultList[j];
            if (null != current.content) {
              // 找到最近的歌词内容
              if (i + 1 != j) {
                // 歌词时间和内容不相邻
                currentIsContinuousTimeTagSM = true;
                currentIsContinuousTimeTagEnd = false;
                // isWordTime = false;
              } else if (currentIsContinuousTimeTagSM) {
                // 当前时间戳和内容是相邻，但时间戳和之前的时间戳是连续
                currentIsContinuousTimeTagSM = false;
                currentIsContinuousTimeTagEnd = true;
                // isWordTime = false;
              } else {
                currentIsContinuousTimeTagSM = false;
                currentIsContinuousTimeTagEnd = false;
              }
              content = current.content;
              break;
            }
          }
          bool allowRemove = true;
          if (null == content) {
            if (null != lastLrcItem && lastLrcItem.timelist.isNotEmpty) {
              // 是一行逐字歌词的结尾时间点
              content = "";
              isWordTime = true;
              allowRemove = false;
            } else {
              // 被作为后置时间戳时不认为是逐字歌词
              content = last_content ?? "";
              isWordTime = false;
            }
          }
          if (isWordTime && tryAutoDistinguishByWord) {
            // 再次判断，尝试自动区分逐字歌词和逐行歌词
            isWordTime = (content.length <= tryAutoDistinguishLength);
          }
          if (isWordTime) {
            if (currentIsContinuousTimeTagSM) {
              // 逐字歌词不允许连续时间戳
              continue;
            }
          } else {
            // 逐行歌词不要保留两边的空白符号，再次削减两边的空白符号
            content = StringUtilxx_c.removeBetweenSpace(content);
          }
          if (allowRemove && removeEmptyLine && content.isEmpty) {
            // 移除内容为空的歌词行
            continue;
          }
          // 非空行，添加
          final timeTag = item.timeTag!;
          var mm = int.tryParse(timeTag[1] ?? "") ?? 0;
          var ss = int.tryParse(timeTag[2] ?? "") ?? 0;
          final ff_str = timeTag[4] ?? "";
          double ff = int.tryParse(ff_str)?.toDouble() ?? 0;
          if (mm < 0 || ss < 0 || ff < 0) {
            // 有一个值为负，则全部置零
            mm = 0;
            ss = 0;
            ff = 0;
          }
          if (ff > 0) {
            // 将ff计算回真实毫秒值
            if (ff_str.length == 1) {
              ff = ff / 10;
            } else if (ff_str.length == 2) {
              ff = ff / 100;
            } else if (ff_str.length == 3) {
              ff = ff / 1000;
            } else if (ff_str.length > 3) {
              // 异常，毫秒部分长度不应多于三位数，置零
              ff = 0;
            }
          }
          final time = (mm * 60) + ss + ff;
          // 是逐字歌词，添加记录、合并内容
          if (isWordTime) {
            if (null == lastLrcItem) {
              // 逐字歌词的开头
              if (content.isNotEmpty) {
                // 移除开头空白符号
                content = StringUtilxx_c.removeBetweenSpaceMayNull(
                  content,
                  subRight: false,
                );
                if (null == content) {
                  continue;
                }
              }
              lastLrcItem = _ParseLyricObj_c(
                  type: _ParseLyricType_e.Lrc,
                  content: content,
                  time: time,
                  timelist: [
                    LyricSrcTime_c(
                      time: time,
                      index: 0,
                    )
                  ]);
              relist.add(lastLrcItem);
            } else {
              // 附加内容到前面的逐字歌词中, 并记录起始时间
              if (content.isNotEmpty &&
                  (resultList.length - 3) == i &&
                  null != resultList.last.timeTag) {
                // 如果这是最后一个 content，则移除末尾空白符号
                content = StringUtilxx_c.removeBetweenSpaceMayNull(
                      content,
                      subLeft: false,
                    ) ??
                    ' ';
              }
              lastLrcItem.timelist.add(LyricSrcTime_c(
                time: time,
                index: lastLrcItem.content.length,
              ));
              lastLrcItem.content += content;
            }
          } else {
            lastLrcItem = null;
            relist.add(_ParseLyricObj_c(
              type: _ParseLyricType_e.Lrc,
              content: content,
              time: time,
            ));
          }
        } else {
          currentIsContinuousTimeTagSM = false;
          currentIsContinuousTimeTagEnd = false;
          // 是歌词内容 [content]
          last_content = (null != item.content)
              ? StringUtilxx_c.removeBetweenSpaceMayNull(item.content!)
              : null;
        }
      }
      bool avail = false;
      for (final item in relist) {
        if (item.content.isNotEmpty && item.content != ' ') {
          avail = true;
        }
      }
      // 整行内容都为空时，默认丢弃该行；
      // 但 [removeEmptyLine] = false 表示调用方希望保留空内容行，此时应尊重该参数
      if (avail || false == removeEmptyLine) {
        return relist;
      }
    } else {
      // 无时间歌词
      final content = StringUtilxx_c.removeBetweenSpace(line);
      if (removeEmptyLine && content.isEmpty) {
        return null;
      }
      return [
        _ParseLyricObj_c(
          type: _ParseLyricType_e.Lrc,
          content: content,
        )
      ];
    }
    return null;
  }

  /// ## 解析歌词文件 .lrc
  /// - [removeEmptyLine] 是否删除包含歌词时间，但内容却为空的行
  /// - [limitInfoType] 限制需要的 info 类型，默认不传入则接收所有的 info
  /// - 如果一行包含多个时间戳：
  ///   - 如果每个字或词语携带了多个时间，则认为是多次逐行歌词的时间戳
  ///   - 如果总行数 <= [3]：
  ///     - 单行内的一个时间携带的内容长度 < [5]，则认为是逐字歌词时间戳，保持在同一行
  ///     - 否则认为是逐行歌词时间戳，并在该位置自动换行
  ///   - 如果总行数 >  [3]，则认为所有单行内的单个时间戳都表示逐字歌词时间戳，保持在同一行
  static LyricSrcEntity_c decodeLrcString(
    String lrcStr, {
    bool removeEmptyLine = true,
    bool parseHtmlEscape = true,
    bool Function(String typeStr)? limitInfoType,
    bool Function(String content)? limitContent = defLimitContent,
  }) {
    final lrcObj = LyricSrcEntity_c();
    // 按行切割
    final lrcList = lrcStr.split(RegExp(r"\n|\r"));
    for (int i = 0; i < lrcList.length; ++i) {
      // 去掉空白符
      StringUtilxx_c.removeAllSpace(lrcList[i]);
      if (lrcList[i].isEmpty) {
        // 如果是空行则丢弃这一行
        continue;
      }
      // 逐行解析
      final relist = _decodeLrcStrLine(
        lrcList[i],
        removeEmptyLine: removeEmptyLine,
        parseHtmlEscape: parseHtmlEscape,
        tryAutoDistinguishByWord: (lrcList.length <= 3),
        tryAutoDistinguishLength: 5,
      );
      if (null == relist) {
        continue;
      }
      for (final line in relist) {
        switch (line.type) {
          case _ParseLyricType_e.Lrc:
            if (limitContent?.call(line.content) == false) {
              // 排除部分无效行
              continue;
            }
            final item = LyricSrcItemEntity_c(
              time: line.time ?? -1,
              content: line.content,
              timelist: line.timelist,
            );
            lrcObj.lrc.add(item);
            // 确定时间戳类型
            if (item.isVerbatimTime) {
              lrcObj.timeType = LyricTimeType_e.Verbatim;
            } else if (item.time > 0 &&
                lrcObj.timeType == LyricTimeType_e.Unknown) {
              lrcObj.timeType = LyricTimeType_e.Line;
            }
            break;
          case _ParseLyricType_e.Info:
            if (true == line.infoKey?.isNotEmpty &&
                line.infoKey != "lrc" &&
                false != limitInfoType?.call(line.infoKey!)) {
              lrcObj.info[line.infoKey!] = line.content;
            }
            break;
        }
      }
    }
    // 排序
    // <time, index>
    final templist = <MapEntry<double, LyricSrcItemEntity_c>>[];
    // 保存最近一次时间为正的值
    double lastAvailTime = 0;
    // *  将待排序歌词行进行临时时间转换，
    // 以保持没有指定时间的歌词行仍然可以跟随在正确的歌词行后面
    // 确保app显示解析的正确。
    for (int i = 0; i < lrcObj.lrc.length; ++i) {
      final item = lrcObj.lrc[i];
      if (item.time >= 0) {
        // 时间为正，取其时间
        lastAvailTime = item.time;
        templist.add(MapEntry(item.time, item));
      } else {
        // 没有指定时间，则回退取最近一行歌词的正的时间
        templist.add(MapEntry(lastAvailTime, item));
      }
    }
    // 进行稳定排序
    final relist = Utilxx_c.mergeSort<MapEntry<double, LyricSrcItemEntity_c>>(
      templist,
      (left, right) => ((left.key - right.key) * 1000).toInt(),
    );
    lrcObj.lrc = [];
    for (int i = 0; i < relist.length; ++i) {
      lrcObj.lrc.add(relist[i].value);
    }
    return lrcObj;
  }

  /// 将 [lrclist] 编码为 lrc 规范的字符串，以便保存回 .lrc 文件
  /// [enableTime] 是否携带时间戳，如果为 [false] 则编码为无时间戳的文本歌词格式
  /// [enableWordTime] 需要 [enableTime] 为 [true] 才有效；如果是逐字歌词，是否编码为增强型LRC歌词
  /// [enableWordTimeSimulate] 是否允许引用模拟生成的逐字时间戳
  static String encodeLrcString(
    List<LyricSrcItemEntity_c> lrclist, {
    Map<String, dynamic>? info,
    bool enableTime = true,
    bool enableWordTime = false,
    bool enableWordTimeSimulate = false,
  }) {
    var data = StringBuffer();

    if (null != info) {
      for (final item in info.entries) {
        final key = StringUtilxx_c.removeBetweenSpaceMayNull(
          item.key.replaceAll(RegExp(r'\r|\n|:|\[|\]'), ''),
        );
        final value = StringUtilxx_c.removeBetweenSpaceMayNull(
          item.value.toString().replaceAll(RegExp(r'\r|\n|:|\[|\]'), ''),
        );
        if (key != null && value != null) {
          data.write("[$key:$value]\n");
        }
      }
    }

    for (int i = 0, len = lrclist.length; i < len; ++i) {
      final item = lrclist[i];

      if (enableTime) {
        final timelist =
            enableWordTimeSimulate ? item.maySimulateTimelist : item.timelist;
        if (enableWordTime &&
            null != timelist &&
            (timelist.length >= 3 ||
                (timelist.length >= 2 &&
                    timelist.last.index == item.content.length))) {
          // 按逐字歌词编码
          data.write("[${item.timeStr}]<${timelist.first.timeStr}>");
          for (int i = 1; i < timelist.length; ++i) {
            final time = timelist[i];
            if (time.index <= item.content.length) {
              data.write(item.content.substring(
                timelist[i - 1].index,
                time.index,
              ));
            }
            data.write("<${time.timeStr}>");
            if (time.index >= item.content.length) {
              break;
            }
          }
          data.write("\n");
        } else {
          data.write("[${item.timeStr}]${item.content}\n");
        }
      } else {
        data.write("${item.content}\n");
      }
    }

    return data.toString();
  }

  /// * 将 [in_second] 转为 [HH:]MM:SS.(MS/10) 时间格式字符串
  /// * [in_second] 的单位：秒 s
  /// * 注意：
  ///   * 毫秒部分会除以10显示
  static String formatLyricTimeStr(double in_second) {
    if (in_second > 0) {
      var minute = in_second ~/ 60;
      var second = in_second.toInt() % 60;
      var msecond = in_second * 1000 % 1000 ~/ 10;
      final restr = StringBuffer();
      if (minute < 10) {
        restr.write("0");
      }
      restr.write("$minute:");
      if (second < 10) {
        restr.write("0");
      }
      restr.write("$second.");
      if (msecond < 10) {
        restr.write("0");
      }
      restr.write(msecond.toString());
      return restr.toString();
    } else {
      return "00:00.00";
    }
  }

  /// 将 [lrclist] 整体时间都偏移 [offset]
  static void offsetTime(List<LyricSrcItemEntity_c> lrclist, double offset) {
    if (offset == 0) {
      return;
    }
    for (int i = 0; i < lrclist.length; ++i) {
      final line = lrclist[i];
      if (line.time >= 0) {
        final temp = line.time + offset;
        if (temp >= 0) {
          line.time = temp;
        } else {
          line.time = 0;
        }
        for (final word in line.timelist) {
          if (word.time >= 0) {
            final t = word.time + offset;
            if (t >= 0) {
              word.time = t;
            } else {
              word.time = 0;
            }
          } else {
            break;
          }
        }
      }
    }
  }
}
