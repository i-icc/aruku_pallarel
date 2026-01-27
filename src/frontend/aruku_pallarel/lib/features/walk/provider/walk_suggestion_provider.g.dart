// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walkSuggestListHash() => r'7506be6b42264bb125527ed77eedaa42b923e6fa';

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

/// See also [walkSuggestList].
@ProviderFor(walkSuggestList)
const walkSuggestListProvider = WalkSuggestListFamily();

/// See also [walkSuggestList].
class WalkSuggestListFamily extends Family<AsyncValue<List<WalkSuggest>>> {
  /// See also [walkSuggestList].
  const WalkSuggestListFamily();

  /// See also [walkSuggestList].
  WalkSuggestListProvider call(String walkId) {
    return WalkSuggestListProvider(walkId);
  }

  @override
  WalkSuggestListProvider getProviderOverride(
    covariant WalkSuggestListProvider provider,
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
  String? get name => r'walkSuggestListProvider';
}

/// See also [walkSuggestList].
class WalkSuggestListProvider extends StreamProvider<List<WalkSuggest>> {
  /// See also [walkSuggestList].
  WalkSuggestListProvider(String walkId)
    : this._internal(
        (ref) => walkSuggestList(ref as WalkSuggestListRef, walkId),
        from: walkSuggestListProvider,
        name: r'walkSuggestListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$walkSuggestListHash,
        dependencies: WalkSuggestListFamily._dependencies,
        allTransitiveDependencies:
            WalkSuggestListFamily._allTransitiveDependencies,
        walkId: walkId,
      );

  WalkSuggestListProvider._internal(
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
  Override overrideWith(
    Stream<List<WalkSuggest>> Function(WalkSuggestListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WalkSuggestListProvider._internal(
        (ref) => create(ref as WalkSuggestListRef),
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
  StreamProviderElement<List<WalkSuggest>> createElement() {
    return _WalkSuggestListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalkSuggestListProvider && other.walkId == walkId;
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
mixin WalkSuggestListRef on StreamProviderRef<List<WalkSuggest>> {
  /// The parameter `walkId` of this provider.
  String get walkId;
}

class _WalkSuggestListProviderElement
    extends StreamProviderElement<List<WalkSuggest>>
    with WalkSuggestListRef {
  _WalkSuggestListProviderElement(super.provider);

  @override
  String get walkId => (origin as WalkSuggestListProvider).walkId;
}

String _$selectedSuggestNotifierHash() =>
    r'54e749213aed081d7e9a1e259ddd4f4f9e73e906';

/// See also [SelectedSuggestNotifier].
@ProviderFor(SelectedSuggestNotifier)
final selectedSuggestNotifierProvider =
    NotifierProvider<SelectedSuggestNotifier, SelectedSuggestState>.internal(
      SelectedSuggestNotifier.new,
      name: r'selectedSuggestNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedSuggestNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedSuggestNotifier = Notifier<SelectedSuggestState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
