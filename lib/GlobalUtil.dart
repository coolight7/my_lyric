// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

class GlobalUtil_c {
  /// 二路归并
  /// * [fun] 返回 > 0 则代表 [left] 和 [right] 应当交换位置
  /// * 即 最终结果的数组中，(An - An-1) >= 0; (An-1 - An-2) >= 0; ...; A1 - A0 >= 0
  static List<T> mergeSort<T>(List<T> list, int Function(T left, T right) fun) {
    if (list.length < 2) {
      return list;
    } else if (list.length == 2) {
      final result = fun(list.first, list.last);
      if (result > 0) {
        final temp = list.first;
        list.first = list.last;
        list.last = temp;
      }
      return list;
    } else {
      final relist1 = mergeSort(list.sublist(0, list.length ~/ 2), fun);
      final relist2 = mergeSort(list.sublist(list.length ~/ 2), fun);
      final relist = <T>[];
      for (int i = 0, j = 0;;) {
        if (i < relist1.length && j < relist2.length) {
          if (fun(relist1[i], relist2[j]) <= 0) {
            relist.add(relist1[i]);
            ++i;
          } else {
            relist.add(relist2[j]);
            ++j;
          }
        } else if (i < relist1.length) {
          relist.addAll(relist1.sublist(i));
          break;
        } else if (j < relist2.length) {
          relist.addAll(relist2.sublist(j));
          break;
        } else {
          break;
        }
      }
      return relist;
    }
  }

  /// 移除字符串两端的 空格[ ] 和 制表符 [\t]
  static String stringRemoveBetweenSpace(String str) {
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
}
