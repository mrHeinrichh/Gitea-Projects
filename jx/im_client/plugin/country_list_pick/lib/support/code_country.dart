
mixin ToAlias {}

@deprecated
class CElement = Country with ToAlias;

/// Country element. This is the element that contains all the information
class Country {
  /// the name of the country
  String? name;
  String? zhName;

  /// the flag of the country
  String? flagUri;

  /// the country code (IT,AF..)
  String? code;

  /// the dial code (+39,+93..)
  String? dialCode;

  String? mobileNumber;

  final bool isMandarin;

  Country({required this.isMandarin, this.name, this.zhName, this.flagUri, this.code, this.dialCode, this.mobileNumber});

  @override
  String toString() => "$dialCode";

  String toLongString() => "$dialCode $name";

  String toCountryStringOnly() =>
      isMandarin
          ? '$zhName'
          : '$name';
}
