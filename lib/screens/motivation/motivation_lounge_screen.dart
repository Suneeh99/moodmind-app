import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/motivation_reel.dart';
import '../../services/motivation_reels_service.dart';

class MotivationLoungeScreen extends StatefulWidget {
  const MotivationLoungeScreen({super.key});

  @override
  State<MotivationLoungeScreen> createState() => _MotivationLoungeScreenState();
}

class _MotivationLoungeScreenState extends State<MotivationLoungeScreen> {
  final _service = MotivationReelsService();
  final PageController _pageController = PageController();

  // controllers per index
  final Map<int, VideoPlayerController> _mp4Ctrls = {};
  final Map<int, YoutubePlayerController> _ytCtrls = {};
  int _current = 0;
  List<MotivationReel> _items = const [];

  @override
  void dispose() {
    for (final c in _mp4Ctrls.values) c.dispose();
    for (final c in _ytCtrls.values) c.close();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _pauseAt(_current);
    _current = index;
    _ensureInit(index);
    _playAt(index);
    _prewarmNeighbors(index);
    setState(() {});
  }

  void _ensureInit(int i) {
    if (i < 0 || i >= _items.length) return;
    final reel = _items[i];

    if (reel.source == 'mp4') {
      if (!_mp4Ctrls.containsKey(i)) {
        final c = VideoPlayerController.networkUrl(Uri.parse(reel.videoUrl));
        _mp4Ctrls[i] = c;
        c.initialize().then((_) {
          c.setLooping(true);
          c.play();
          setState(() {});
        });
      }
    } else if (reel.source == 'youtube') {
      if (!_ytCtrls.containsKey(i)) {
        final id = YoutubePlayerController.convertUrlToId(reel.videoUrl) ?? '';
        final c = YoutubePlayerController(
          params: const YoutubePlayerParams(
            mute: false,
            loop: true,
            playsInline: true,
            showControls: false,
            strictRelatedVideos: true,
          ),
        )..loadVideoById(videoId: id);
        _ytCtrls[i] = c;
      }
    }
  }

  void _prewarmNeighbors(int i) {
    for (final n in [i - 1, i + 1]) {
      if (n >= 0 && n < _items.length) _ensureInit(n);
    }

    // dispose far ones
    for (final k in _mp4Ctrls.keys.toList()) {
      if ((k - i).abs() > 1) {
        _mp4Ctrls[k]?.dispose();
        _mp4Ctrls.remove(k);
      }
    }
    for (final k in _ytCtrls.keys.toList()) {
      if ((k - i).abs() > 1) {
        _ytCtrls[k]?.close();
        _ytCtrls.remove(k);
      }
    }
  }

  void _pauseAt(int i) {
    _mp4Ctrls[i]?.pause();
    _ytCtrls[i]?.pauseVideo();
  }

  void _playAt(int i) {
    _mp4Ctrls[i]?.play();
    _ytCtrls[i]?.playVideo();
  }

  void _toggleTap(int i) {
    final mp4 = _mp4Ctrls[i];
    if (mp4 != null) {
      mp4.value.isPlaying ? mp4.pause() : mp4.play();
      setState(() {});
      return;
    }
    final yt = _ytCtrls[i];
    if (yt != null) {
      // youtube_iframe has no isPlaying; quick toggle
      yt.pauseVideo();
      Future.delayed(const Duration(milliseconds: 50), () => yt.playVideo());
    }
  }

  void _share(MotivationReel reel) {
    final msg = '${reel.title}\n\nWatch: ${reel.videoUrl}';
    Share.share(msg, subject: 'Motivation Lounge');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MotivationReel>>(
      stream: _service.streamActive(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('Firestore stream error: ${snap.error}');
          debugPrint('Stack trace: ${snap.stackTrace}');
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _items = snap.data!;
        if (_items.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No reels yet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Make sure current page is initialized
        _ensureInit(_current);
        _prewarmNeighbors(_current);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Motivation Lounge',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical, // swipe down for next
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, i) {
              final reel = _items[i];
              final mp4 = _mp4Ctrls[i];
              final yt = _ytCtrls[i];

              Widget player;
              if (reel.source == 'mp4') {
                player = (mp4 != null && mp4.value.isInitialized)
                    ? GestureDetector(
                        onTap: () => _toggleTap(i),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: mp4.value.size.width,
                            height: mp4.value.size.height,
                            child: VideoPlayer(mp4),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator());
              } else if (reel.source == 'youtube') {
                player = yt == null
                    ? const Center(child: CircularProgressIndicator())
                    : YoutubePlayerScaffold(
                        controller: yt,
                        aspectRatio: 9 / 16,
                        builder: (context, youtubePlayer) =>
                            YoutubeValueBuilder(
                              controller: yt,
                              builder: (context, value) {
                                // Fallback if embed is blocked/unavailable
                                final notPlaying =
                                    value.hasError ||
                                    value.playerState == PlayerState.unknown ||
                                    value.playerState == PlayerState.unStarted;
                                if (notPlaying) {
                                  return _OpenExternallyOverlay(
                                    url: reel.videoUrl,
                                  );
                                }
                                return Center(child: youtubePlayer);
                              },
                            ),
                      );
              } else {
                // Open link in WebView (e.g., Pinterest page) inside a 9:16 container
                player = _InPageWebView(url: reel.videoUrl);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  player,

                  // Gradient to improve text contrast
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom info
                  Positioned(
                    left: 16,
                    right: 80,
                    bottom: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${reel.author}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reel.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Share only
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: GestureDetector(
                      onTap: () => _share(reel),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  // MP4 progress + hint
                  if (reel.source == 'mp4' && mp4 != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 28,
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            mp4,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mp4.value.isPlaying
                                ? 'Tap to Pause'
                                : 'Tap to Play',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _OpenExternallyOverlay extends StatelessWidget {
  const _OpenExternallyOverlay({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black54),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Video unavailable in embedded player',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    launchUrlString(url, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in YouTube'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 9:16 WebView for non-YouTube "web" sources (e.g., Pinterest pages)
class _InPageWebView extends StatefulWidget {
  const _InPageWebView({required this.url});
  final String url;

  @override
  State<_InPageWebView> createState() => _InPageWebViewState();
}

class _InPageWebViewState extends State<_InPageWebView> {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: WebViewWidget(controller: _web),
      ),
    );
  }
}
