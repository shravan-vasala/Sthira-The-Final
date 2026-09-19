import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_providers.dart';
import '../../services/social_sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import '../../widgets/primary_button.dart';
import 'widgets/social_sign_in_prompt.dart';
import 'widgets/friend_details_sheet.dart';

/// Accept the exact invitation this app shares as well as a plain friend ID.
String friendIdFromInput(String input) {
  final value = input.trim();
  const prefix = 'Connect with me on Sthira! My friend ID is:';
  return value.startsWith(prefix)
      ? value.substring(prefix.length).trim()
      : value;
}

class ConnectScreen extends ConsumerWidget {
  const ConnectScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generation = ref.watch(accountGenerationProvider);
    final auth = ref.watch(authServiceProvider);
    final transitioning =
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);
    final signedIn =
        auth.isSignedIn &&
        auth.uid != null &&
        auth.currentUser?.isAnonymous != true;
    return DefaultTabController(
      key: ValueKey(generation),
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connect with friends'),
          bottom: signedIn && !transitioning
              ? const TabBar(
                  tabs: [
                    Tab(text: 'My ID'),
                    Tab(text: 'Enter ID'),
                  ],
                )
              : null,
        ),
        body: transitioning
            ? const Center(child: CircularProgressIndicator())
            : !signedIn
            ? const SocialSignInPrompt()
            : const TabBarView(children: [_MyIdTab(), _EnterIdTab()]),
      ),
    );
  }
}

class _MyIdTab extends ConsumerStatefulWidget {
  const _MyIdTab();
  @override
  ConsumerState<_MyIdTab> createState() => _MyIdTabState();
}

class _MyIdTabState extends ConsumerState<_MyIdTab> {
  bool _copied = false;
  bool _sharing = false;
  Timer? _copyTimer;
  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  bool _current(int generation, String uid) =>
      mounted &&
      ref.read(accountGenerationProvider) == generation &&
      ref.read(authServiceProvider).uid == uid &&
      !ref.read(accountTransitionProvider);
  Future<void> _copy(String uid) async {
    final generation = ref.read(accountGenerationProvider);
    try {
      await Clipboard.setData(ClipboardData(text: uid));
      if (!_current(generation, uid)) return;
      _copyTimer?.cancel();
      setState(() => _copied = true);
      _copyTimer = Timer(const Duration(seconds: 2), () {
        if (_current(generation, uid)) setState(() => _copied = false);
      });
    } catch (_) {
      if (mounted && _current(generation, uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not copy the ID. Try again.')),
        );
      }
    }
  }

  Future<void> _share(String uid) async {
    if (_sharing) return;
    final generation = ref.read(accountGenerationProvider);
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        'Connect with me on Sthira! My friend ID is: $uid',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted && _current(generation, uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open sharing. You can copy your ID instead.',
            ),
          ),
        );
      }
    } finally {
      if (_current(generation, uid)) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authServiceProvider).uid ?? '';
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.screen,
        Spacing.major,
        Spacing.screen,
        shellScrollBottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('YOUR FRIEND ID', style: context.text.eyebrow),
          const SizedBox(height: Spacing.stack),
          Container(
            padding: const EdgeInsets.all(Spacing.cardPad),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Column(
              children: [
                SelectableText(
                  uid,
                  textAlign: TextAlign.center,
                  style: context.text.bodyStrong,
                ),
                const SizedBox(height: Spacing.stack),
                TextButton.icon(
                  onPressed: () => _copy(uid),
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                  ),
                  label: Text(_copied ? 'Copied' : 'Copy ID'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          Text(
            'Share this ID with someone you know. You choose whether to accept their request.',
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
          const SizedBox(height: Spacing.section),
          PrimaryButton(
            label: 'Share invitation',
            icon: Icons.share_rounded,
            isLoading: _sharing,
            onPressed: () => _share(uid),
          ),
        ],
      ),
    );
  }
}

class _EnterIdTab extends ConsumerStatefulWidget {
  const _EnterIdTab();
  @override
  ConsumerState<_EnterIdTab> createState() => _EnterIdTabState();
}

class _EnterIdTabState extends ConsumerState<_EnterIdTab> {
  final _controller = TextEditingController();
  bool _processing = false;
  String? _error;
  String? _sentId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final generation = ref.read(accountGenerationProvider);
    final before = _controller.text;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted ||
          generation != ref.read(accountGenerationProvider) ||
          ref.read(accountTransitionProvider) ||
          _processing ||
          _controller.text != before)
        return;
      final value = friendIdFromInput(data?.text ?? '');
      setState(() {
        if (value.isEmpty) {
          _error = 'Copy your friend’s ID first.';
        } else {
          _controller.text = value;
          _error = null;
        }
      });
    } catch (_) {
      if (mounted && generation == ref.read(accountGenerationProvider)) {
        setState(
          () => _error = 'Could not paste. You can enter the ID yourself.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_processing) return;
    final service = ref.read(socialSyncServiceProvider);
    final generation = ref.read(accountGenerationProvider);
    final code = friendIdFromInput(_controller.text);
    bool current() =>
        mounted &&
        generation == ref.read(accountGenerationProvider) &&
        !ref.read(accountTransitionProvider) &&
        service.canSync;
    if (!current()) return;
    if (!SocialSyncService.isValidFriendId(code)) {
      setState(
        () => _error = 'Enter the full friend ID, or paste their invitation.',
      );
      return;
    }
    if (code == service.currentUid) {
      setState(
        () => _error = 'This is your ID. Ask your friend to share theirs.',
      );
      return;
    }
    if (ref.read(friendRepoProvider).getFriend(code) != null) {
      setState(() => _error = 'You’re already connected to this person.');
      return;
    }
    final profile = ref.read(profileProvider);
    final avatar = profile.photoPath;
    setState(() {
      _processing = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      await service.sendFriendRequest(
        code,
        profile.name,
        avatar != null && avatar.startsWith('assets/avatars/') ? avatar : null,
      );
      if (current()) setState(() => _sentId = code);
    } catch (error) {
      if (current()) {
        if (error is SocialSyncException && error.code == 'already-pending') {
          setState(() => _sentId = code);
        } else {
          setState(
            () => _error = error is SocialSyncException
                ? error.message
                : 'Could not send the request. Your ID is kept; try again.',
          );
          if (error is SocialSyncException &&
              error.code == 'request-accepted') {
            unawaited(ref.read(socialRelationshipProvider)?.refresh());
          }
        }
      }
    } finally {
      if (current()) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedFriend = _sentId == null
        ? null
        : ref
              .watch(friendsListStreamProvider)
              .valueOrNull
              ?.where((friend) => friend.uid == _sentId)
              .firstOrNull;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.screen,
        Spacing.section,
        Spacing.screen,
        shellScrollBottomPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sentId != null) ...[
            Icon(
              Icons.mark_email_read_outlined,
              size: 44,
              color: context.colors.accentText,
            ),
            const SizedBox(height: Spacing.section),
            Text(
              connectedFriend == null ? 'Request sent' : 'Connected',
              style: context.text.cardTitle,
            ),
            const SizedBox(height: Spacing.stack),
            Text(
              connectedFriend == null
                  ? 'Waiting for your friend to accept. Check that this is the ID they shared with you.'
                  : 'You are connected with ' +
                        connectedFriend.name +
                        '. Open their shared details to see their latest activity.',
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.stack),
            SelectableText(_sentId!, style: context.text.body),
            if (connectedFriend != null) ...[
              const SizedBox(height: Spacing.section),
              PrimaryButton(
                label: 'View friend details',
                onPressed: () =>
                    showFriendDetailsSheet(context, connectedFriend),
              ),
            ],
            const SizedBox(height: Spacing.section),
            TextButton(
              onPressed: () => setState(() {
                _sentId = null;
                _controller.clear();
              }),
              child: const Text('Connect with someone else'),
            ),
          ] else ...[
            Text('ENTER FRIEND ID', style: context.text.eyebrow),
            const SizedBox(height: Spacing.stack),
            Text(
              'Paste the ID or invitation your friend shared.',
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),
            const SizedBox(height: Spacing.section),
            TextField(
              controller: _controller,
              enabled: !_processing,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: const InputDecoration(
                labelText: 'Friend ID',
                hintText: 'Paste ID here',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _processing ? null : _paste,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Paste'),
              ),
            ),
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.section),
            ],
            PrimaryButton(
              label: _processing ? 'Sending request…' : 'Send request',
              icon: Icons.send_rounded,
              isLoading: _processing,
              onPressed: _submit,
            ),
            const SizedBox(height: Spacing.section),
            Text(
              'Once connected, you share activity summaries such as steps, finished workouts and scores.',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
