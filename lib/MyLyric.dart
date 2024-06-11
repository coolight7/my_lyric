// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:collection';
import 'dart:convert' as convert;

import 'package:my_string_util/MyStringUtil.dart';
import 'package:my_util/MyUtil.dart';

class LyricSrcItemEntity_c {
  /// * 歌词时间戳，单位：秒
  /// * 如果是翻译，该值为负
  double time = 0;

  /// 歌词内容
  String content = "";

  LyricSrcItemEntity_c({
    this.time = 0,
    this.content = "",
  });

  /// 是否为翻译
  bool get isTranslate => (time < 0);

  /// 将时间格式化为标准 lrc 格式的时间
  String get timeStr => MyLyric_c.formatLyricTimeStr(time);

  factory LyricSrcItemEntity_c.fromJson(Map<String, dynamic> json) {
    final json_time = json["time"];
    double time = 0;
    if (json_time is double) {
      time = json_time;
    } else if (json_time is int) {
      time = json_time.toDouble();
    }
    return LyricSrcItemEntity_c(
      time: time,
      content: json["content"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    final remap = <String, dynamic>{};
    remap["time"] = time;
    remap["content"] = content;
    return remap;
  }

  LyricSrcItemEntity_c copyWith({double? time, String? content}) {
    return LyricSrcItemEntity_c(
      time: time ?? this.time,
      content: content ?? this.content,
    );
  }
}

class LyricSrcEntity_c {
  static const String KEY_ti = "ti";
  static const String KEY_ar = "ar";
  static const String KEY_al = "al";
  static const String KEY_by = "by";
  static const String KEY_offset = "offset";

  /// 歌词信息
  /// * 可使用[s_createInfo]构造，让map的key忽略大小写
  HashMap<String, dynamic> info;

  /// 歌词内容
  List<LyricSrcItemEntity_c> lrc;

  LyricSrcEntity_c({
    HashMap<String, dynamic>? info,
    List<LyricSrcItemEntity_c>? lrc,
  })  : info = info ?? s_createInfo(),
        lrc = lrc ?? [];

  static HashMap<String, dynamic> s_createInfo() {
    return HashMap<String, dynamic>(
      equals: (p0, p1) {
        return MyStringUtil_c.isIgnoreCaseEqual(p0, p1);
      },
      hashCode: (p0) {
        return p0.toLowerCase().hashCode;
      },
      isValidKey: (p0) {
        return (p0 is String);
      },
    );
  }

  bool get isEmpty => (info.isEmpty && lrc.isEmpty);
  bool get isNotEmpty => (info.isNotEmpty || lrc.isNotEmpty);

  /// 歌曲标题
  String? get info_ti => getInfoItemWithString(KEY_ti);

  /// 艺术家
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

  String? getInfoItemWithString(String key) {
    final result = info[key];
    return (result is String) ? result : null;
  }

  LyricSrcItemEntity_c? getLrcItemByIndex(int index) {
    if (index < 0 || index >= lrc.length) {
      return null;
    }
    return lrc[index];
  }

  factory LyricSrcEntity_c.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return LyricSrcEntity_c();
    }
    final resrc = LyricSrcEntity_c();
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
        resrc.lrc.add(LyricSrcItemEntity_c.fromJson(list[i]));
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

  Map<String, dynamic> toJson() {
    final remap = <String, dynamic>{};
    // 将 [info] 和 [lrc]合并到一个map中
    info.forEach((key, value) {
      if (key != "lrc") {
        remap[key] = value;
      }
    });
    remap["lrc"] = lrc;
    return remap;
  }

  LyricSrcEntity_c copyWith({
    HashMap<String, dynamic>? info,
    List<LyricSrcItemEntity_c>? lrc,
  }) {
    final reSrc = LyricSrcEntity_c(
      info: info ?? this.info,
    );
    if (null != lrc) {
      reSrc.lrc = lrc;
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
  final String content;

  _ParseLyricObj_c({
    this.infoKey,
    required this.type,
    required this.content,
    this.time,
  });
}

class _ParseLyricTimeItem_c {
  final int start, length;
  final RegExpMatch? timeTag;
  final String? content;

  _ParseLyricTimeItem_c({
    required this.start,
    required this.length,
    required this.timeTag,
    required this.content,
  });
}

/// TODO: 逐字歌词支持
class MyLyric_c {
  /// 解析单行歌词
  /// * [removeEmptyLine] 是否删除包含歌词时间，但内容却为空的行
  static List<_ParseLyricObj_c>? _decodeLrcStrLine(
    String line, {
    bool removeEmptyLine = true,
  }) {
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
            infoKey: MyStringUtil_c.removeBetweenSpace(key),
            type: _ParseLyricType_e.Info,
            content: MyStringUtil_c.removeBetweenSpace(item[2] ?? ""),
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
    /// * 其中ff ~ (-100, +1000)，超出范围将被置0
    const tagTimeItemReg = r"\[([+-]?\d+)\:([+-]?\d+)([.:]([+-]?\d+))?\]";

    /// 匹配歌词时间戳
    final result = RegExp(tagTimeItemReg).allMatches(line);
    if (result.isNotEmpty) {
      // 将被返回的歌词数组
      final relist = <_ParseLyricObj_c>[];
      // 将[line]分段存入[resultList]
      final resultList = <_ParseLyricTimeItem_c>[];
      // 记录上一次操作的尾部坐标
      int lastIndex = 0;
      for (final item in result) {
        final start = item.start;
        final end = item.end;
        if (start > lastIndex) {
          // [item]之前有[content]
          // 截取[content]加入分段列表
          final content = MyStringUtil_c.removeBetweenSpace(line.substring(
            lastIndex,
            start,
          ));
          // 保留空字符串，确保时间对应的[content]正确，比如：
          // [00:37][000:47.11]abc [000:50.11] [00:57:33]cool
          // 应保留[000:50.11]对应一个空字符串，否则会被误认为和后面的[00:57:33]cool是一起的
          resultList.add(_ParseLyricTimeItem_c(
            start: start,
            length: start - lastIndex,
            timeTag: null,
            content: content,
          ));
        }
        // 添加[item]
        resultList.add(_ParseLyricTimeItem_c(
          start: start,
          length: end - start,
          timeTag: item,
          content: null,
        ));
        lastIndex = end;
      }
      if (lastIndex < line.length) {
        // 最后一段字符串作为[content]
        resultList.add(_ParseLyricTimeItem_c(
          start: lastIndex,
          length: line.length - lastIndex,
          timeTag: null,
          content: MyStringUtil_c.removeBetweenSpace(line.substring(
            lastIndex,
          )),
        ));
      }
      // 记录过往最近的一个[content]
      String? last_content;
      for (int i = 0; i < resultList.length; ++i) {
        final item = resultList[i];
        if (null != item.timeTag) {
          // 是时间戳 [timeTag]
          // 先从[item]的位置向右寻找第一个歌词内容，如果没有则从[item]的位置向左寻找
          String? content;
          for (int j = i + 1; j < resultList.length; ++j) {
            final current = resultList[j];
            if (null != current.content) {
              // 找到
              content = current.content;
              break;
            }
          }
          content ??= last_content ?? "";
          if (removeEmptyLine && content.isEmpty) {
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
          relist.add(_ParseLyricObj_c(
            type: _ParseLyricType_e.Lrc,
            content: content,
            time: time,
          ));
        } else {
          // 是歌词内容 [content]
          last_content = item.content;
        }
      }
      return relist;
    } else {
      // 无时间歌词
      final content = MyStringUtil_c.removeBetweenSpace(line);
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
  }

  /// * 解析歌词文件 .lrc
  /// * [removeEmptyLine] 是否删除包含歌词时间，但内容却为空的行
  /// * [limitInfoType] 限制需要的 info 类型，默认不传入则接收所有的 info
  static LyricSrcEntity_c decodeLrcString(
    String lrcStr, {
    bool removeEmptyLine = true,
    bool Function(String typeStr)? limitInfoType,
  }) {
    final lrcObj = LyricSrcEntity_c();
    // 按行切割
    var lrcArr = lrcStr.split(RegExp(r"\n|\r"));
    for (int i = 0; i < lrcArr.length; ++i) {
      // 去掉空白符
      lrcArr[i].replaceAll(RegExp(r"\s+"), '');
      if (lrcArr[i].isEmpty) {
        // 如果是空行则丢弃这一行
        continue;
      }
      // 逐行解析
      final relist = _decodeLrcStrLine(
        lrcArr[i],
        removeEmptyLine: removeEmptyLine,
      );
      if (null == relist) {
        continue;
      }
      for (final line in relist) {
        switch (line.type) {
          case _ParseLyricType_e.Lrc:
            lrcObj.lrc.add(LyricSrcItemEntity_c(
              time: line.time ?? -1,
              content: line.content,
            ));
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
    final relist = MyUtil_c.mergeSort<MapEntry<double, LyricSrcItemEntity_c>>(
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
  static String encodeLrcString(List<LyricSrcItemEntity_c> lrclist) {
    var data = "";
    for (int i = 0, len = lrclist.length; i < len; ++i) {
      data += "[${lrclist[i].timeStr}]${lrclist[i].content}\n";
    }
    return data;
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
      String restr = "";
      if (minute < 10) {
        restr += "0";
      }
      restr += "$minute:";
      if (second < 10) {
        restr += "0";
      }
      restr += "$second.";
      if (msecond < 10) {
        restr += "0";
      }
      restr += msecond.toString();
      return restr;
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
      if (lrclist[i].time > 0) {
        lrclist[i].time += offset;
      }
    }
  }
}
