import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/surface_card.dart';
import '../../../widgets/setup_sheets.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/credential_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  bool _healthConnected = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: Motion.deliberate,
    );
    _staggerController.forward();
    _checkHealthStatus();
  }

  Future<void> _checkHealthStatus() async {
    final hcService = ref.read(healthConnectServiceProvider);
    final isAuthorized = await hcService.isAuthorized();
    if (mounted) {
      setState(() {
        _healthConnected = isAuthorized;
      });
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Widget _buildAnimEntrance(int index, Widget child) {
    return Builder(
      builder: (context) {
        if (MediaQuery.disableAnimationsOf(context)) {
          return child;
        }
        final start = index * 0.1;
        final end = (start + 0.5).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _staggerController,
          builder: (context, animChild) {
            final slide = CurvedAnimation(
              parent: _staggerController,
              curve: Interval(start, end, curve: Motion.enter),
            ).value;
            final fade = CurvedAnimation(
              parent: _staggerController,
              curve: Interval(start, end - 0.2, curve: Motion.exit),
            ).value;
            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - slide)),
                child: animChild,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current statuses
    final cred = ref.watch(credentialProvider);
    final hasGemini =
        cred.status == CredentialStatus.present && (cred.key ?? '').isNotEmpty;

    final cloudConnected = ref.watch(isSignedInProvider);
    final syncState = ref.watch(cloudSyncControllerProvider);

    String cloudStatusText = 'Local-only';
    if (cloudConnected) {
      if (syncState == CloudSyncState.syncing) {
        cloudStatusText = 'Sync pending';
      } else if (syncState == CloudSyncState.error) {
        cloudStatusText = 'Retry';
      } else {
        cloudStatusText = 'Connected';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          _buildAnimEntrance(
            0,
            Column(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 48,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect',
                  textAlign: TextAlign.center,
                  style: context.text.display.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Optional — you can do any of this later in Settings.',
                  textAlign: TextAlign.center,
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildAnimEntrance(
            1,
            _IntegrationRow(
              icon: Icons.favorite_rounded,
              title: 'Health Connect',
              subtitle: 'Sync steps & sleep natively.',
              statusText: _healthConnected ? 'Connected' : 'Optional',
              statusActive: _healthConnected,
              onTap: () async {
                await showAppBottomSheet<bool>(
                  context: context,
                  builder: (_) => const HealthConnectSheet(),
                );
                if (mounted) {
                  await _checkHealthStatus();
                }
              },
            ),
          ),

          _buildAnimEntrance(
            2,
            _IntegrationRow(
              icon: Icons.camera_alt_rounded,
              title: 'AI Food Scanning',
              subtitle:
                  'Review meal estimates. Requires internet and your API key.',
              statusText: hasGemini ? 'Key saved' : 'Optional',
              statusActive: hasGemini,
              onTap: () {
                showAppBottomSheet(
                  context: context,
                  builder: (_) => const AiSetupSheet(),
                );
              },
            ),
          ),

          _buildAnimEntrance(
            3,
            _IntegrationRow(
              icon: Icons.cloud_sync_rounded,
              title: 'Cloud Backup',
              subtitle: 'Securely sync your progress.',
              statusText: cloudStatusText,
              statusActive: cloudConnected,
              onTap: () async {
                await showAppBottomSheet<bool>(
                  context: context,
                  builder: (_) => const CloudSyncSheet(),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String statusText;
  final bool statusActive;
  final VoidCallback onTap;

  const _IntegrationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        // The page already owns the horizontal gutter.
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: context.colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.cardTitle.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: context.text.caption.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  statusText,
                  style: context.text.caption.copyWith(
                    color: statusActive
                        ? context.colors.primary
                        : context.colors.textMedium,
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(statusActive ? 'Edit' : 'Set up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
