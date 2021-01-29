extension GetNativeAddress on String {
  ///Method for getting URL's addr id
  String get address {
    List<String> list = split('?').last.split('&').where((element) => element.contains('addr')).toList();
    if (list.length == 0) {
      return null;
    } else {
      return list.first.split('=').last;
    }
  }

  ///Method for getting route path
  String get path {
    List<String> list = split('?');
    if (list.length == 1) {
      return null;
    } else {
      return list.sublist(0, list.length - 1).join("?");
    }
  }
}
