import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hydrated_rx/src/storage/hydrated_rx_storage.dart';
import 'package:hydrated_rx/src/utils/empty.dart';
import 'package:rxdart/rxdart.dart';

// ignore: implementation_imports
import 'package:rxdart/src/transformers/start_with_error.dart';

typedef HydrateCallback<T> = T Function(String);

class HydratedBehaviorSubject<T> extends Subject<T> implements ValueStream<T> {
  factory HydratedBehaviorSubject({
    required String key,
    HydrateCallback<T>? onHydrate,
    Function()? onHydrateEnd,
    Function()? onListen,
    Function()? onCancel,
    bool sync = false,
  }) {
    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = _Wrapper<T>();

    return HydratedBehaviorSubject<T>._(
      key,
      onHydrate,
      onHydrateEnd,
      wrapper,
      controller,
      Rx.defer<T>(
        _deferStream(
          wrapper,
          controller,
          sync,
        ),
        reusable: true,
      ),
    );
  }

  HydratedBehaviorSubject._(
    this.key,
    this.onHydrate,
    this.onHydrateEnd,
    this._wrapper,
    super.controller,
    super.stream,
  ) {
    _hydrate();
  }

  final String key;
  final _Wrapper<T> _wrapper;
  HydrateCallback<T>? onHydrate;
  Function()? onHydrateEnd;
  late final _storage = HydratedRxStorage(Hive.box(key));

  static Stream<T> Function() _deferStream<T>(
    _Wrapper<T> wrapper,
    StreamController<T> controller,
    bool sync,
  ) =>
      () {
        final errorAndStackTrace = wrapper.errorAndStackTrace;
        if (errorAndStackTrace != null && !wrapper.isValue) {
          return controller.stream.transform(
            StartWithErrorStreamTransformer(
              errorAndStackTrace.error,
              errorAndStackTrace.stackTrace,
            ),
          );
        }

        final value = wrapper.value;
        if (isNotEmpty(value) && wrapper.isValue) {
          return controller.stream
              .transform(StartWithStreamTransformer(value as T));
        }

        return controller.stream;
      };

  Future<void> _hydrate() async {
    final value = await _storage.read(key);
    if (isNotEmpty(value)) {
      _wrapper.setValue(value);
    }
  }

  Future<void> delete() => _storage.delete(key);

  @override
  Stream<T> get stream => this;

  @override
  void onAdd(T event) => _storage.write(key, value);

  @override
  void onAddError(Object error, [StackTrace? stackTrace]) =>
      _wrapper.setError(error, stackTrace);

  @override
  Object get error {
    final errorAndSt = _wrapper.errorAndStackTrace;
    if (errorAndSt != null) {
      return errorAndSt.error;
    }
    throw ValueStreamError.hasNoError();
  }

  @override
  Object? get errorOrNull => _wrapper.errorAndStackTrace?.error;

  @override
  bool get hasError => throw UnimplementedError();

  @override
  bool get hasValue => isNotEmpty(_wrapper.value);

  @override
  StackTrace? get stackTrace => _wrapper.errorAndStackTrace?.stackTrace;

  @override
  T get value {
    final value = _wrapper.value;
    if (isNotEmpty(value)) {
      return value as T;
    }
    throw ValueStreamError.hasNoValue();
  }

  set value(T newValue) => add(newValue);

  @override
  T? get valueOrNull => unbox(_wrapper.value);
}

class _Wrapper<T> {
  _Wrapper() : isValue = false;

  _Wrapper.seeded(this.value) : isValue = true;

  bool isValue;
  Object? value = empty;
  ErrorAndStackTrace? errorAndStackTrace;

  void setValue(T event) {
    value = event;
    isValue = true;
  }

  void setError(Object error, StackTrace? stackTrace) {
    errorAndStackTrace = ErrorAndStackTrace(error, stackTrace);
    isValue = false;
  }
}
