// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walkHistoryListNotifierHash() =>
    r'53d7bd1573e146be75024c0b9867283ce110967c';

/// See also [WalkHistoryListNotifier].
@ProviderFor(WalkHistoryListNotifier)
final walkHistoryListNotifierProvider =
    AsyncNotifierProvider<
      WalkHistoryListNotifier,
      List<WalkHistoryItem>
    >.internal(
      WalkHistoryListNotifier.new,
      name: r'walkHistoryListNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$walkHistoryListNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WalkHistoryListNotifier = AsyncNotifier<List<WalkHistoryItem>>;
String _$walkHistoryRouteNotifierHash() =>
    r'77a9d539484eeee3cc523061a64c0cf802c1a6f8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$WalkHistoryRouteNotifier
    extends BuildlessAsyncNotifier<List<LatLng>> {
  late final String walkId;

  FutureOr<List<LatLng>> build(String walkId);
}

/// See also [WalkHistoryRouteNotifier].
@ProviderFor(WalkHistoryRouteNotifier)
const walkHistoryRouteNotifierProvider = WalkHistoryRouteNotifierFamily();

/// See also [WalkHistoryRouteNotifier].
class WalkHistoryRouteNotifierFamily extends Family<AsyncValue<List<LatLng>>> {
  /// See also [WalkHistoryRouteNotifier].
  const WalkHistoryRouteNotifierFamily();

  /// See also [WalkHistoryRouteNotifier].
  WalkHistoryRouteNotifierProvider call(String walkId) {
    return WalkHistoryRouteNotifierProvider(walkId);
  }

  @override
  WalkHistoryRouteNotifierProvider getProviderOverride(
    covariant WalkHistoryRouteNotifierProvider provider,
  ) {
    return call(provider.walkId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'walkHistoryRouteNotifierProvider';
}

/// See also [WalkHistoryRouteNotifier].
class WalkHistoryRouteNotifierProvider
    extends AsyncNotifierProviderImpl<WalkHistoryRouteNotifier, List<LatLng>> {
  /// See also [WalkHistoryRouteNotifier].
  WalkHistoryRouteNotifierProvider(String walkId)
    : this._internal(
        () => WalkHistoryRouteNotifier()..walkId = walkId,
        from: walkHistoryRouteNotifierProvider,
        name: r'walkHistoryRouteNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$walkHistoryRouteNotifierHash,
        dependencies: WalkHistoryRouteNotifierFamily._dependencies,
        allTransitiveDependencies:
            WalkHistoryRouteNotifierFamily._allTransitiveDependencies,
        walkId: walkId,
      );

  WalkHistoryRouteNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.walkId,
  }) : super.internal();

  final String walkId;

  @override
  FutureOr<List<LatLng>> runNotifierBuild(
    covariant WalkHistoryRouteNotifier notifier,
  ) {
    return notifier.build(walkId);
  }

  @override
  Override overrideWith(WalkHistoryRouteNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WalkHistoryRouteNotifierProvider._internal(
        () => create()..walkId = walkId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        walkId: walkId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<WalkHistoryRouteNotifier, List<LatLng>>
  createElement() {
    return _WalkHistoryRouteNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalkHistoryRouteNotifierProvider && other.walkId == walkId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, walkId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WalkHistoryRouteNotifierRef on AsyncNotifierProviderRef<List<LatLng>> {
  /// The parameter `walkId` of this provider.
  String get walkId;
}

class _WalkHistoryRouteNotifierProviderElement
    extends AsyncNotifierProviderElement<WalkHistoryRouteNotifier, List<LatLng>>
    with WalkHistoryRouteNotifierRef {
  _WalkHistoryRouteNotifierProviderElement(super.provider);

  @override
  String get walkId => (origin as WalkHistoryRouteNotifierProvider).walkId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
