class _Empty {
  const _Empty();

  @override
  String toString() => '<<EMPTY>>';
}
// ignore: constant_identifier_names
// ignore:, unnecessary_nullable_for_final_variable_declarations
const Object? empty = _Empty();

T? unbox<T>(Object? o) => identical(o, empty) ? null : o as T;

bool isNotEmpty(Object? o) => !identical(o, empty);
