// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walkChatMessagesHash() => r'013de74715d617e8d453a3cb15ea11daa78ffa05';

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

/// See also [walkChatMessages].
@ProviderFor(walkChatMessages)
const walkChatMessagesProvider = WalkChatMessagesFamily();

/// See also [walkChatMessages].
class WalkChatMessagesFamily extends Family<AsyncValue<List<WalkChatMessage>>> {
  /// See also [walkChatMessages].
  const WalkChatMessagesFamily();

  /// See also [walkChatMessages].
  WalkChatMessagesProvider call(String walkId) {
    return WalkChatMessagesProvider(walkId);
  }

  @override
  WalkChatMessagesProvider getProviderOverride(
    covariant WalkChatMessagesProvider provider,
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
  String? get name => r'walkChatMessagesProvider';
}

/// See also [walkChatMessages].
class WalkChatMessagesProvider extends StreamProvider<List<WalkChatMessage>> {
  /// See also [walkChatMessages].
  WalkChatMessagesProvider(String walkId)
    : this._internal(
        (ref) => walkChatMessages(ref as WalkChatMessagesRef, walkId),
        from: walkChatMessagesProvider,
        name: r'walkChatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$walkChatMessagesHash,
        dependencies: WalkChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            WalkChatMessagesFamily._allTransitiveDependencies,
        walkId: walkId,
      );

  WalkChatMessagesProvider._internal(
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
    Stream<List<WalkChatMessage>> Function(WalkChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WalkChatMessagesProvider._internal(
        (ref) => create(ref as WalkChatMessagesRef),
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
  StreamProviderElement<List<WalkChatMessage>> createElement() {
    return _WalkChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalkChatMessagesProvider && other.walkId == walkId;
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
mixin WalkChatMessagesRef on StreamProviderRef<List<WalkChatMessage>> {
  /// The parameter `walkId` of this provider.
  String get walkId;
}

class _WalkChatMessagesProviderElement
    extends StreamProviderElement<List<WalkChatMessage>>
    with WalkChatMessagesRef {
  _WalkChatMessagesProviderElement(super.provider);

  @override
  String get walkId => (origin as WalkChatMessagesProvider).walkId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
