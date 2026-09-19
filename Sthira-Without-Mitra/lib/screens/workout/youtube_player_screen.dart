import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class YoutubePlayerScreen extends StatefulWidget {
  const YoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.subtitle,
    required this.reps,
  });

  final String videoId;
  final String title;
  final String subtitle;
  final String reps;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  YoutubePlayerController? _controller;
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _initRequestGen = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller?.close();
    _controller = null;

    final currentReq = ++_initRequestGen;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (widget.videoId.isEmpty) {
      if (!mounted || currentReq != _initRequestGen) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid or missing video ID.';
        _isLoading = false;
      });
      return;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted || currentReq != _initRequestGen) return;

      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'No internet connection. Please check your network and try again.';
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted || currentReq != _initRequestGen) return;

    final controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    controller.setFullScreenListener((isFullScreen) {
      if (!mounted) return;
      setState(() {
        _isFullScreen = isFullScreen;
      });
      if (isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });

    setState(() {
      _controller = controller;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.close();
    super.dispose();
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.black,
      constraints: const BoxConstraints(minHeight: 250),
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.colors.white.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: context.text.body.copyWith(color: context.colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _initializePlayer,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: context.colors.primary,
                ),
                label: Text(
                  'Retry',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_rounded, color: context.colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: context.colors.card.withValues(alpha: 0.1),
              child: Center(
                child: CircularProgressIndicator(color: context.colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Exercise Video'),
        ),
        body: SingleChildScrollView(child: _buildVideoPlaceholder()),
      );
    }
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullScreen) {
          _controller?.exitFullScreen();
        }
      },
      // ignore: deprecated_member_use
      child: YoutubePlayerScaffold(
        controller: _controller!,
        builder: (context, player) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: _isFullScreen
                ? null
                : AppBar(
                    backgroundColor: Colors.black,
                    title: Text(
                      'Exercise Video',
                      style: context.text.bodyStrong.copyWith(
                        color: context.colors.white,
                      ),
                    ),
                    leading: IconButton(
                      tooltip: 'Back',
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: context.colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_hasError || _controller == null)
                  _buildVideoPlaceholder()
                else
                  GestureDetector(
                    onDoubleTap: () {
                      if (_isFullScreen) {
                        _controller!.exitFullScreen();
                      } else {
                        _controller!.enterFullScreen();
                      }
                    },
                    child: player,
                  ),
                if (!_isFullScreen) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: context.text.screenTitle.copyWith(
                            color: context.colors.white,
                          ),
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: context.text.body.copyWith(
                              color: context.colors.white.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (widget.reps.isNotEmpty)
                          Text(
                            'Reps: ${widget.reps}',
                            style: AppTheme.numeric(
                              context.text.bodyStrong.copyWith(
                                color: context.colors.white.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (!_hasError && _controller != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _controller!.enterFullScreen(),
                              icon: Icon(
                                Icons.fullscreen_rounded,
                                color: context.colors.primary,
                              ),
                              label: Text(
                                'Enter Fullscreen',
                                style: context.text.bodyStrong.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                backgroundColor: context.colors.primary
                                    .withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
