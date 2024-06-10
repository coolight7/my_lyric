// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:convert' as convert;

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

  Map<String, dynamic> info;
  List<LyricSrcItemEntity_c> lrc = [];

  LyricSrcEntity_c({
    Map<String, dynamic>? info,
  }) : info = info ?? {};

  // TODO: key不区分大小写
  String? getInfoItemWithString(String key) =>
      (info[key] is String?) ? info[key] : null;

  String? get ti => getInfoItemWithString(KEY_ti);
  String? get ar => getInfoItemWithString(KEY_ar);
  String? get al => getInfoItemWithString(KEY_al);
  String? get by => getInfoItemWithString(KEY_by);

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
    Map<String, dynamic>? info,
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
  String? typeStr;
  _ParseLyricType_e type;
  List<double> timelist;
  String content;

  _ParseLyricObj_c({
    this.typeStr,
    required this.type,
    required this.timelist,
    required this.content,
  });
}

/// TODO: 逐字歌词支持
class MyLyric_c {
  /// 解析单行歌词
  /// * [removeEmptyLine] 是否删除包含歌词时间，但内容却为空的行
  static _ParseLyricObj_c? _decodeLrcStrLine(
    String line, {
    bool removeEmptyLine = true,
  }) {
    /// 匹配信息行
    /// * tr
    /// * ar
    /// * al
    /// * by
    /// * offset
    /// * ...
    /// * 非数字开头
    RegExpMatch? result = RegExp(
      r"^[\s\S]*\[\s*([^\d]*)\s*\:([\s\S]*)\][\s\S]*$",
    ).firstMatch(line);
    if (result != null) {
      return _ParseLyricObj_c(
        typeStr: result[1],
        type: _ParseLyricType_e.Info,
        timelist: [],
        content: result[2] ?? "",
      );
    }

    /// 匹配单个时间戳
    /// * 支持 [mm:ss.ff]
    /// * 支持 [mm:ss]
    /// * 支持 [+-mm:+-ss.+-ff], 如果出现负号，将会将其时间置零
    const lyricTimeItemReg = r"\[[+-]?\d+\:[+-]?\d+([.:][+-]?\d+)?\]\s*";
    const tagTimeItemReg = r"\[([+-]?\d+)\:([+-]?\d+)([.:]([+-]?\d+))?\]";

    /// 匹配歌词行
    result = RegExp(
      r"^[\s\S]*?((" + lyricTimeItemReg + r")+)([\s\S]*)$",
    ).firstMatch(line);
    if (result != null) {
      final String? tags = result[1];
      var content = result[4] ?? "";
      if (removeEmptyLine && content.isEmpty) {
        content =
            line.substring(0, line.length - (tags?.length ?? line.length));
        if (content.isEmpty) {
          // 移除内容为空的歌词行
          return null;
        }
      }
      // 提取时间
      final timelist = <double>[];
      if (null != tags) {
        final relist = RegExp(
          r"(" + tagTimeItemReg + r"){1}?",
        ).allMatches(tags);
        for (final item in relist) {
          var mm = int.tryParse(item[2] ?? "") ?? 0;
          var ss = int.tryParse(item[3] ?? "") ?? 0;
          final ff_str = item[5] ?? "";
          double ff = int.tryParse(ff_str)?.toDouble() ?? 0;
          if (mm < 0 || ss < 0 || ff < 0) {
            // 有一个值为负，则全部置零
            mm = 0;
            ss = 0;
            ff = 0;
          }
          // 将ff计算回真实毫秒值
          // TODO：取整个文件里最长的 [ff_str.length] 作为全局计算长度，
          // 因为可能编码时未考虑补充前导零，导致出现：[01:22.33]、[01:22.7]、[01:22.123]
          if (ff_str.length == 2) {
            ff = ff / 100;
          } else if (ff_str.length == 3) {
            ff = ff / 1000;
          }
          timelist.add((mm * 60) + ss + ff);
        }
      }
      return _ParseLyricObj_c(
        type: _ParseLyricType_e.Lrc,
        timelist: timelist,
        content: content,
      );
    } else {
      // 无时间歌词
      final reLine = removeBetweenSpace(line);
      if (removeEmptyLine && reLine.isEmpty) {
        return null;
      }
      return _ParseLyricObj_c(
        type: _ParseLyricType_e.Lrc,
        timelist: [],
        content: reLine,
      );
    }
  }

  /// 移除[str]两边的（空格|制表符\t）
  static String removeBetweenSpace(String str) {
    if (str.isEmpty) {
      return str;
    }
    int left = 0, right = str.length - 1;
    for (; right >= left; --right) {
      if (str[right] != ' ' && str[right] != '\t') {
        break;
      }
    }
    for (; left <= right; ++left) {
      if (str[left] != ' ' && str[left] != '\t') {
        break;
      }
    }
    if (left <= right) {
      return str.substring(left, right + 1);
    } else {
      return "";
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
      final line = _decodeLrcStrLine(
        lrcArr[i],
        removeEmptyLine: removeEmptyLine,
      );
      if (null == line) {
        continue;
      }
      switch (line.type) {
        case _ParseLyricType_e.Lrc:
          if (line.timelist.isNotEmpty) {
            for (int i = 0; i < line.timelist.length; ++i) {
              lrcObj.lrc.add(LyricSrcItemEntity_c(
                time: line.timelist[i],
                content: line.content,
              ));
            }
          } else {
            lrcObj.lrc.add(LyricSrcItemEntity_c(
              time: -1,
              content: line.content,
            ));
          }
          break;
        case _ParseLyricType_e.Info:
          if (true == line.typeStr?.isNotEmpty &&
              line.typeStr != "lrc" &&
              false != limitInfoType?.call(line.typeStr!)) {
            lrcObj.info[line.typeStr!] = line.content;
          }
          break;
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
