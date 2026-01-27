import 'package:any_link_preview/any_link_preview.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/walk/models/walk_chat_message.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/walk_chat_provider.dart';
import '../../features/walk/provider/walk_suggestion_provider.dart';
import '../../theme/app_styles.dart';
import '../../widgets/app_background.dart';

@RoutePage()
class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  static final _urlRegex = RegExp(
    r'https?://[^\s<>\[\]{}|\\^`"]+',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final shouldAutoScroll = useRef(true);
    final previousMessageCount = useRef(0);
    final messageKeys = useRef<Map<String, GlobalKey>>({});

    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final walkId = activeWalk?.walkId ?? '';
    final messagesAsync = walkId.isEmpty
        ? const AsyncValue.data(<WalkChatMessage>[])
        : ref.watch(walkChatMessagesProvider(walkId));
    final selectedState = ref.watch(selectedSuggestNotifierProvider);
    final selectedSuggestId =
        selectedState.walkId == walkId ? selectedState.suggestId : null;

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) {
          return;
        }
        const threshold = 120.0;
        shouldAutoScroll.value =
            scrollController.position.pixels < threshold;
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    useEffect(() {
      messagesAsync.whenData((messages) {
        final currentCount = messages.length;
        final previousCount = previousMessageCount.value;
        if (currentCount > previousCount && shouldAutoScroll.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!scrollController.hasClients) {
              return;
            }
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
            );
          });
        }
        previousMessageCount.value = currentCount;
      });
      return null;
    }, [messagesAsync]);

    useEffect(() {
      final targetId = selectedSuggestId;
      if (targetId == null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = messageKeys.value[targetId];
        final targetContext = key?.currentContext;
        if (targetContext == null) {
          return;
        }
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      });
      return null;
    }, [selectedSuggestId, messagesAsync]);

    GlobalKey keyForMessage(WalkChatMessage message) {
      final keyId = message.suggestId ?? message.chatId;
      return messageKeys.value.putIfAbsent(keyId, GlobalKey.new);
    }

    String? extractUrl(String text) {
      final match = _urlRegex.firstMatch(text);
      return match?.group(0);
    }

    Widget buildEmptyState({required String title, String? subtitle}) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: AppColors.inkMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: AppBackground(
        safeAreaTop: false,
        child: Column(
          children: [
            Expanded(
              child: walkId.isEmpty
                  ? buildEmptyState(
                      title: 'No active walk',
                      subtitle: 'Start a walk to receive suggestions.',
                    )
                  : messagesAsync.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return buildEmptyState(
                            title: 'No suggestions yet',
                            subtitle: 'Keep walking to receive new ideas.',
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final messageIndex = messages.length - 1 - index;
                            final message = messages[messageIndex];
                            final isSelected = message.suggestId != null &&
                                message.suggestId == selectedSuggestId;
                            final previewUrl = message.url ??
                                extractUrl(message.message);
                            final hasPreview = previewUrl != null &&
                                AnyLinkPreview.isValidLink(previewUrl);

                            return _ChatMessageBubble(
                              key: keyForMessage(message),
                              message: message,
                              isSelected: isSelected,
                              onTap: message.suggestId == null
                                  ? null
                                  : () {
                                      ref
                                          .read(selectedSuggestNotifierProvider
                                              .notifier)
                                          .select(walkId, message.suggestId!);
                                    },
                              previewUrl: hasPreview ? previewUrl : null,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Failed to load chat: $error'),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(
                                walkChatMessagesProvider(walkId),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            _ChatFooter(
              text: walkId.isEmpty
                  ? 'Suggestions appear after you start a walk.'
                  : 'Suggestions will appear automatically while you walk.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    super.key,
    required this.message,
    required this.isSelected,
    this.onTap,
    this.previewUrl,
  });

  final WalkChatMessage message;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? previewUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = isSelected
        ? AppColors.accentWarm.withValues(alpha: 0.12)
        : AppColors.surface;
    final borderColor =
        isSelected ? AppColors.accentWarm : AppColors.border;
    final timeLabel = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SystemAvatar(isHighlighted: isSelected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          message.isSystem ? 'Suggestion' : message.senderType,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.accentCool,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(AppRadii.medium),
                        border: Border.all(color: borderColor),
                        boxShadow: AppShadows.tight,
                      ),
                      child: Text(
                        message.message,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (previewUrl != null) ...[
                      const SizedBox(height: 10),
                      _LinkPreviewCard(url: previewUrl!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final local = value.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}

class _SystemAvatar extends StatelessWidget {
  const _SystemAvatar({required this.isHighlighted});

  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHighlighted
            ? AppColors.accentWarm
            : AppColors.accentCool,
        boxShadow: AppShadows.soft,
      ),
      child: Center(
        child: Text(
          'AI',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

class _ChatFooter extends StatelessWidget {
  const _ChatFooter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.send,
                color: AppColors.inkMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPreviewCard extends StatelessWidget {
  const _LinkPreviewCard({required this.url});

  final String url;

  Future<void> _openLink() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Metadata?>(
      future: AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(days: 7),
      ),
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        final title = metadata?.title;
        final image = metadata?.image;
        final host = Uri.tryParse(url)?.host ?? url;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LinkSkeleton();
        }

        return GestureDetector(
          onTap: _openLink,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.medium),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.tight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null && image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 160,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title?.isNotEmpty == true ? title! : host,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          host,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinkSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
