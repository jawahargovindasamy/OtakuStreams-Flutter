import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/anime.dart';
import '../core/theme.dart';
import '../core/unified_scaffold.dart';
import '../core/utils.dart';
import '../widgets/episodes_list.dart';
import '../widgets/episode_server.dart';
import '../widgets/seasons_section.dart';
import '../widgets/anime_grid.dart';
import '../widgets/section_header.dart';

class WatchScreen extends StatefulWidget {
  final String id;
  final String episodeNumber;
  final String? initialDub;
  final String? initialServer;

  const WatchScreen({
    super.key,
    required this.id,
    required this.episodeNumber,
    this.initialDub,
    this.initialServer,
  });

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  WebViewController? _webViewController;
  bool _loading = true;
  bool _checkingEpisode = false;
  bool _isAvailable = true;
  bool _hasDub = false;
  List<Episode> _episodes = [];
  AnimeDetail? _detail;

  String _audioType = 'sub';
  Map<String, String>? _activeSubServer;
  Map<String, String>? _activeDubServer;
  Map<String, String>? _activeRawServer;
  String _nextEpisodeTime = '';
  bool _showAllPopular = false;
  List<dynamic> _debugInfo = [];
  bool _isInPipMode = false;
  String? _lastSentProgress;
  bool _isPlayerBlanked = false;
  bool _isCustomWidgetActive = false;

  String get _cleanEpisodeNumber => widget.episodeNumber.replaceAll('ep=', '');

  static const List<Map<String, String>> _subServers = [
    {'serverId': 'hd-1', 'serverName': 'HD-1'},
    {'serverId': 'hd-2', 'serverName': 'HD-2'},
  ];

  static const List<Map<String, String>> _dubServers = [
    {'serverId': 'hd-1', 'serverName': 'HD-1'},
    {'serverId': 'hd-2', 'serverName': 'HD-2'},
  ];

  static const _orientationChannel = MethodChannel('com.jawahargovindasamy.otakustreams/orientation');

  Future<void> _setSensorLandscape() async {
    if (Platform.isAndroid) {
      try {
        await _orientationChannel.invokeMethod('setSensorLandscape');
      } catch (e) {
        debugPrint('Failed to set sensor landscape via channel: $e');
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<void> _resetOrientation() async {
    if (Platform.isAndroid) {
      try {
        await _orientationChannel.invokeMethod('resetOrientation');
      } catch (e) {
        debugPrint('Failed to reset orientation via channel: $e');
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _setupPipListener() {
    _orientationChannel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged' && mounted) {
        setState(() => _isInPipMode = call.arguments as bool);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadWatchData();
    _setupPipListener();
  }

  @override
  void dispose() {
    _orientationChannel.invokeMethod('setWatchScreenActive', false);
    _resetOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.episodeNumber != widget.episodeNumber) {
      _loadWatchData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrent && !_isCustomWidgetActive) {
      if (_webViewController != null && !_isPlayerBlanked) {
        _webViewController?.loadRequest(Uri.parse('about:blank'));
        _isPlayerBlanked = true;
      }
    } else {
      if (_isPlayerBlanked) {
        _isPlayerBlanked = false;
        _initWebViewController();
      }
    }
  }

  Future<void> _updateWatchProgress() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn || _detail == null) return;

    final activeEpNum = int.tryParse(_cleanEpisodeNumber) ?? 1;

    String epTitle = 'Episode $_cleanEpisodeNumber';
    if (_episodes.isNotEmpty) {
      for (final e in _episodes) {
        if (e.number.toString() == _cleanEpisodeNumber) {
          if (e.title.isNotEmpty) {
            epTitle = '${e.title} (Episode $_cleanEpisodeNumber)';
          }
          break;
        }
      }
    }

    final activeServerId = _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? _activeRawServer?['serverId'] ?? 'hd-1';
    final dub = _audioType == 'dub' ? 'yes' : 'no';

    final progressData = {
      'animeId': widget.id,
      'animeTitle': _detail!.anime.name,
      'animeImage': _detail!.anime.poster,
      'currentEpisode': activeEpNum,
      'episodeTitle': epTitle,
      'server': activeServerId,
      'dub': dub,
    };

    final progressString = '${widget.id}-$_cleanEpisodeNumber-$activeServerId-$dub';
    if (_lastSentProgress == progressString) return;
    _lastSentProgress = progressString;

    try {
      await auth.updateProgress(progressData);
      debugPrint('Watch progress updated successfully');
    } catch (e) {
      debugPrint('Failed to update watch progress: $e');
    }
  }

  Future<void> _loadWatchData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final String animeKey = 'anime-${widget.id}';
    final String episodesKey = 'episodes-${widget.id}';
    final String scheduleKey = 'next-episode-schedule-${widget.id}';

    final bool isCached = dataProvider.isCached(animeKey) && dataProvider.isCached(episodesKey);

    if (isCached) {
      // Load synchronously from cache without triggering full screen loading indicator!
      final detail = dataProvider.getCached(animeKey) as AnimeDetail?;
      final eps = dataProvider.getCached(episodesKey) as List<Episode>? ?? [];
      final schedule = dataProvider.getCached(scheduleKey) as Map<String, dynamic>?;

      final preferences = auth.preferences;

      final String dubState = widget.initialDub ?? '';
      final String prefAudio = dubState.isNotEmpty
          ? (dubState == 'yes' ? 'dub' : 'sub')
          : (preferences['audio'] ?? 'sub');

      final String? stateServer = widget.initialServer;

      Map<String, String>? activeSub;
      if (dubState == 'no' && stateServer != null) {
        activeSub = _subServers.firstWhere((s) => s['serverId'] == stateServer, orElse: () => _subServers.first);
      } else if (dubState == 'yes') {
        activeSub = null;
      } else if (dubState.isEmpty && preferences['audio'] == 'sub') {
        final targetServer = stateServer ?? preferences['server'] ?? 'hd-1';
        activeSub = _subServers.firstWhere((s) => s['serverId'] == targetServer, orElse: () => _subServers.first);
      } else {
        activeSub = preferences['audio'] == 'dub' ? null : _subServers.first;
      }

      Map<String, String>? activeDub;
      if (dubState == 'yes' && stateServer != null) {
        activeDub = _dubServers.firstWhere((s) => s['serverId'] == stateServer, orElse: () => _dubServers.first);
      } else if (dubState.isEmpty && preferences['audio'] == 'dub') {
        final targetServer = stateServer ?? preferences['server'] ?? 'hd-1';
        activeDub = _dubServers.firstWhere((s) => s['serverId'] == targetServer, orElse: () => _dubServers.first);
      } else {
        activeDub = null;
      }

      if (mounted) {
        setState(() {
          _detail = detail;
          _episodes = eps;
          _audioType = prefAudio;
          _showAllPopular = false;
          _activeSubServer = activeSub;
          _activeDubServer = activeDub;
          _activeRawServer = null;

          _hasDub = detail?.anime.dubEpisodes != null;

          if (schedule != null && schedule['airingTimestamp'] != null) {
            _nextEpisodeTime = _formatNextEpisodeTime(schedule['airingTimestamp'] as int);
          } else {
            _nextEpisodeTime = '';
          }

          _loading = false;
          _checkingEpisode = true;
          _isAvailable = true;
          _debugInfo = [];
        });

        // Check episode availability asynchronously (runs the Netlify function check)
        _checkEpisodeAvailability().then((_) {
          if (mounted && _isAvailable && _isCurrentServerWorking()) {
            final isCurrent = (ModalRoute.of(context)?.isCurrent ?? true) || _isCustomWidgetActive;
            if (isCurrent) {
              _initWebViewController();
              _updateWatchProgress();
            } else {
              _isPlayerBlanked = true;
            }
          }
        });
      }
    } else {
      // Normal path: Not cached, show full screen loading spinner
      setState(() {
        _loading = true;
        _checkingEpisode = false;
        _isAvailable = true;
        _debugInfo = [];
      });

      // Fetch episodes and anime info concurrently
      final results = await Future.wait([
        dataProvider.fetchanimeinfo(widget.id),
        dataProvider.fetchepisodeinfo(widget.id),
        dataProvider.fetchnextepisodeschedule(widget.id),
      ]);

      final detail = results[0] as AnimeDetail?;
      final eps = results[1] as List<Episode>? ?? [];
      final schedule = results[2] as Map<String, dynamic>?;

      final preferences = auth.preferences;

      final String dubState = widget.initialDub ?? '';
      final String prefAudio = dubState.isNotEmpty
          ? (dubState == 'yes' ? 'dub' : 'sub')
          : (preferences['audio'] ?? 'sub');

      final String? stateServer = widget.initialServer;

      Map<String, String>? activeSub;
      if (dubState == 'no' && stateServer != null) {
        activeSub = _subServers.firstWhere((s) => s['serverId'] == stateServer, orElse: () => _subServers.first);
      } else if (dubState == 'yes') {
        activeSub = null;
      } else if (dubState.isEmpty && preferences['audio'] == 'sub') {
        final targetServer = stateServer ?? preferences['server'] ?? 'hd-1';
        activeSub = _subServers.firstWhere((s) => s['serverId'] == targetServer, orElse: () => _subServers.first);
      } else {
        activeSub = preferences['audio'] == 'dub' ? null : _subServers.first;
      }

      Map<String, String>? activeDub;
      if (dubState == 'yes' && stateServer != null) {
        activeDub = _dubServers.firstWhere((s) => s['serverId'] == stateServer, orElse: () => _dubServers.first);
      } else if (dubState.isEmpty && preferences['audio'] == 'dub') {
        final targetServer = stateServer ?? preferences['server'] ?? 'hd-1';
        activeDub = _dubServers.firstWhere((s) => s['serverId'] == targetServer, orElse: () => _dubServers.first);
      } else {
        activeDub = null;
      }

      if (mounted) {
        setState(() {
          _detail = detail;
          _episodes = eps;
          _audioType = prefAudio;
          _showAllPopular = false;
          _activeSubServer = activeSub;
          _activeDubServer = activeDub;
          _activeRawServer = null;

          _hasDub = detail?.anime.dubEpisodes != null;

          if (schedule != null && schedule['airingTimestamp'] != null) {
            _nextEpisodeTime = _formatNextEpisodeTime(schedule['airingTimestamp'] as int);
          } else {
            _nextEpisodeTime = '';
          }

          _loading = false;
        });

        // Check episode availability asynchronously (runs the Netlify function check)
        _checkEpisodeAvailability().then((_) {
          if (mounted && _isAvailable && _isCurrentServerWorking()) {
            final isCurrent = (ModalRoute.of(context)?.isCurrent ?? true) || _isCustomWidgetActive;
            if (isCurrent) {
              _initWebViewController();
              _updateWatchProgress();
            } else {
              _isPlayerBlanked = true;
            }
          }
        });
      }
    }
  }

  String _formatNextEpisodeTime(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      return '${date.month}/${date.day}/${date.year}, $hour:$minute:$second $period';
    } catch (e) {
      return '';
    }
  }

  bool _isCurrentServerWorking() {
    if (_debugInfo.isEmpty) return true;

    final activeServerId = _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? 'hd-1';
    final typePath = activeServerId == 'hd-2' ? '/mal/' : '/ani/';
    
    // Find matching debug status for current server and audio type
    final status = _debugInfo.firstWhere(
      (d) => d['url'].toString().contains(typePath) && d['url'].toString().contains('/$_audioType'),
      orElse: () => null,
    );

    return status == null || status['status'] == 'Success';
  }

  void _tryNextServer() {
    final activeServerId = _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? _activeRawServer?['serverId'] ?? 'hd-1';
    final nextServerId = activeServerId == 'hd-1' ? 'hd-2' : 'hd-1';

    setState(() {
      if (_audioType == 'dub') {
        _activeDubServer = _dubServers.firstWhere(
          (s) => s['serverId'] == nextServerId,
          orElse: () => _dubServers.first,
        );
        _activeSubServer = null;
        _activeRawServer = null;
      } else {
        _activeSubServer = _subServers.firstWhere(
          (s) => s['serverId'] == nextServerId,
          orElse: () => _subServers.first,
        );
        _activeDubServer = null;
        _activeRawServer = null;
      }
    });

    if (_isCurrentServerWorking()) {
      _initWebViewController();
      _updateWatchProgress();
    }
  }

  Future<void> _checkEpisodeAvailability() async {
    if (mounted) {
      setState(() {
        _checkingEpisode = true;
        _isAvailable = false;
        _debugInfo = [];
      });
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      final malId = _detail?.anime.malId?.toString() ?? '';
      final url = 'https://otakustreams.netlify.app/.netlify/functions/check-episode?animeId=${widget.id}&episode=$_cleanEpisodeNumber&malId=$malId';

      final response = await dio.get(url);

      if (mounted && response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          setState(() {
            _isAvailable = data['isAvailable'] ?? false;
            _hasDub = data['hasDub'] ?? false;
            _debugInfo = data['debug'] as List<dynamic>? ?? [];

            // If selected audio is DUB but DUB is not available, switch back to SUB
            if (!_hasDub && _audioType == 'dub') {
              _audioType = 'sub';
              _activeSubServer = _subServers.first;
              _activeDubServer = null;
              _activeRawServer = null;
            }
          });
        } else {
          setState(() {
            _isAvailable = false;
          });
        }
      } else {
        setState(() {
          _isAvailable = false;
        });
      }
    } catch (e) {
      debugPrint('Episode availability check failed: $e');
      if (mounted) {
        setState(() {
          _isAvailable = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingEpisode = false;
        });
      }
    }
  }


  void _initWebViewController() {
    final activeServerId = _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? 'hd-1';
    final malId = _detail?.anime.malId?.toString();
    final isMal = widget.id.startsWith('mal-') || (malId != null && activeServerId == 'hd-2');
    final cleanId = isMal ? (widget.id.startsWith('mal-') ? widget.id.replaceAll('mal-', '') : malId) : widget.id;
    final typePath = isMal ? 'mal' : 'ani';

    final streamUrl = 'https://megaplay.buzz/stream/$typePath/$cleanId/$_cleanEpisodeNumber/$_audioType';

    final htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>OtakuStreams Player</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            background-color: #000;
        }
        html, body, #player-container {
            width: 100%;
            height: 100%;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
    </style>
</head>
<body>
    <div id="player-container">
        <iframe 
            src="$streamUrl" 
            allow="autoplay; fullscreen; encrypted-media"
            allowfullscreen="true">
        </iframe>
    </div>
    <script>
        // Anti-clickjacking ad redirection shield
        window.open = function() { return null; };
        
        document.addEventListener('click', function(e) {
            const tag = e.target.tagName.toLowerCase();
            if (tag === 'a' && !e.target.href.includes('megaplay.buzz')) {
                e.preventDefault();
                e.stopPropagation();
            }
        }, true);

        // Periodically sanitize target blank links
        setInterval(function() {
            const anchors = document.getElementsByTagName('a');
            for (let i = 0; i < anchors.length; i++) {
                if (anchors[i].getAttribute('target') === '_blank') {
                    anchors[i].removeAttribute('target');
                    anchors[i].href = 'javascript:void(0);';
                }
            }
        }, 1000);
    </script>
</body>
</html>
''';

    if (_webViewController != null) {
      _orientationChannel.invokeMethod('setWatchScreenActive', true);
      _webViewController!.loadHtmlString(htmlContent, baseUrl: 'https://megaplay.buzz/');
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('WebView started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished loading: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.host.contains('megaplay.buzz') ||
                uri.host.contains('otakustreams.netlify.app') ||
                uri.host.contains('netlify.app') ||
                uri.host.contains('googleapis.com') ||
                request.url.startsWith('about:blank') ||
                request.url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            debugPrint('Prevented intrusive redirect popup to: ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget widget, OnHideCustomWidgetCallback callback) async {
          if (_isCustomWidgetActive) return;
          _isCustomWidgetActive = true;

          await _setSensorLandscape();
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(
                backgroundColor: Colors.black,
                body: PopScope(
                  canPop: true,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) {
                      if (_isCustomWidgetActive) {
                        _isCustomWidgetActive = false;
                        _resetOrientation();
                        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                        callback();
                      }
                    }
                  },
                  child: Center(child: widget),
                ),
              ),
              fullscreenDialog: true,
            ),
          );
        },
        onHideCustomWidget: () async {
          if (!_isCustomWidgetActive) return;
          _isCustomWidgetActive = false;

          await _resetOrientation();
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

          if (!mounted) return;

          Navigator.of(context).pop();
        },
      );
    }

    _orientationChannel.invokeMethod('setWatchScreenActive', true);
    controller.loadHtmlString(htmlContent, baseUrl: 'https://megaplay.buzz/');

    setState(() {
      _webViewController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    // When in PiP mode, show only the bare video player — no app bars or chrome
    if (_isInPipMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildPlayerContent(),
      );
    }

    if (_loading) {
      return const UnifiedScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final animeName = _detail != null ? AnimeUtils.getTitle(context, _detail!.anime) : '';
    final typeLower = _detail?.anime.type.toLowerCase() ?? 'tv';
    final typePath = typeLower == 'tv' ? '/tv' : typeLower == 'movie' ? '/movie' : typeLower == 'ova' ? '/ova' : typeLower == 'ona' ? '/ona' : typeLower == 'special' ? '/special' : '/movie';

    final breadcrumbs = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          GestureDetector(
            onTap: () => context.push('/home'),
            child: const Text('Home', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const Text('/', style: TextStyle(color: Colors.grey, fontSize: 13)),
          GestureDetector(
            onTap: () => context.push(typePath),
            child: Text(_detail?.anime.type.toUpperCase() ?? 'TV', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const Text('/', style: TextStyle(color: Colors.grey, fontSize: 13)),
          GestureDetector(
            onTap: () => context.push('/${AnimeUtils.slugify(animeName)}/${widget.id}'),
            child: Text(
              animeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return UnifiedScaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth > 1000;
  
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs trail
                  breadcrumbs,
                  const SizedBox(height: 8),
  
                  // Responsive Top Grid Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTopSection(isDesktop, constraints),
                  ),
                  const SizedBox(height: 40),
  
                  // Bottom Content Section (Recommended & Popular Lists)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBottomSection(isDesktop, constraints),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSection(bool isDesktop, BoxConstraints constraints) {
    if (isDesktop) {
      final playerColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Box
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerContent(),
            ),
          ),
          const SizedBox(height: 16),

          // Server controls
          if (_isAvailable && !_checkingEpisode)
            EpisodeServer(
              episodeNo: _cleanEpisodeNumber,
              subServers: _subServers,
              dubServers: _hasDub ? _dubServers : const [],
              rawServers: const [],
              activeSub: _activeSubServer,
              activeDub: _activeDubServer,
              activeRaw: _activeRawServer,
              nextEpisodeTime: _nextEpisodeTime,
              onServerSelected: (audioType, s) {
                setState(() {
                  _audioType = audioType;
                  if (audioType == 'sub') {
                    _activeSubServer = s;
                    _activeDubServer = null;
                    _activeRawServer = null;
                  } else if (audioType == 'dub') {
                    _activeDubServer = s;
                    _activeSubServer = null;
                    _activeRawServer = null;
                  } else if (audioType == 'raw') {
                    _activeRawServer = s;
                    _activeSubServer = null;
                    _activeDubServer = null;
                  }
                });
                _initWebViewController();
                _updateWatchProgress();
                Provider.of<AuthProvider>(context, listen: false).updatePreferences({
                  'audio': audioType,
                  'server': s['serverId'] ?? 'hd-1',
                });
              },
            ),
          const SizedBox(height: 24),

          // Seasons List
          SeasonsSection(animeId: widget.id),
        ],
      );

      final double sidebarWidth = constraints.maxWidth > 1200 ? 340 : 300;
      final double playerWidth = constraints.maxWidth - sidebarWidth - 24 - 32; // subtracting columns spacing and margins
      final double playerHeight = playerWidth * 9 / 16;
      final double listHeight = playerHeight + 160;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Column
          SizedBox(
            width: sidebarWidth,
            height: listHeight,
            child: EpisodesList(
              episodeList: _episodes,
              totalepisodes: (_detail != null && _detail!.anime.subEpisodes != '?') ? (int.tryParse(_detail!.anime.subEpisodes) ?? 0) : 0,
              activeEpisode: _cleanEpisodeNumber,
              onEpisodeChange: (epNum) {
                context.go(
                  '/watch/${widget.id}/$epNum',
                  extra: {
                    'server': _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? _activeRawServer?['serverId'],
                    'dub': _audioType == 'dub' ? 'yes' : 'no',
                  },
                );
              },
              maxHeight: listHeight,
            ),
          ),
          const SizedBox(width: 24),

          // Right Player Column
          Expanded(
            child: playerColumn,
          ),
        ],
      );
    } else {
      // Mobile stacked layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Box
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayerContent(),
            ),
          ),
          const SizedBox(height: 16),

          // Server controls
          if (_isAvailable && !_checkingEpisode) ...[
            EpisodeServer(
              episodeNo: _cleanEpisodeNumber,
              subServers: _subServers,
              dubServers: _hasDub ? _dubServers : const [],
              rawServers: const [],
              activeSub: _activeSubServer,
              activeDub: _activeDubServer,
              activeRaw: _activeRawServer,
              nextEpisodeTime: _nextEpisodeTime,
              onServerSelected: (audioType, s) {
                setState(() {
                  _audioType = audioType;
                  if (audioType == 'sub') {
                    _activeSubServer = s;
                    _activeDubServer = null;
                    _activeRawServer = null;
                  } else if (audioType == 'dub') {
                    _activeDubServer = s;
                    _activeSubServer = null;
                    _activeRawServer = null;
                  } else if (audioType == 'raw') {
                    _activeRawServer = s;
                    _activeSubServer = null;
                    _activeDubServer = null;
                  }
                });
                _initWebViewController();
                _updateWatchProgress();
                Provider.of<AuthProvider>(context, listen: false).updatePreferences({
                  'audio': audioType,
                  'server': s['serverId'] ?? 'hd-1',
                });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Episode List (directly below Episode Server controls on mobile!)
          EpisodesList(
            episodeList: _episodes,
            totalepisodes: (_detail != null && _detail!.anime.subEpisodes != '?') ? (int.tryParse(_detail!.anime.subEpisodes) ?? 0) : 0,
            activeEpisode: _cleanEpisodeNumber,
            onEpisodeChange: (epNum) {
              context.go(
                '/watch/${widget.id}/$epNum',
                extra: {
                  'server': _activeSubServer?['serverId'] ?? _activeDubServer?['serverId'] ?? _activeRawServer?['serverId'],
                  'dub': _audioType == 'dub' ? 'yes' : 'no',
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Seasons List
          SeasonsSection(animeId: widget.id),
        ],
      );
    }
  }

  Widget _buildPlayerContent() {
    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: _checkingEpisode
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Checking episode availability...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : _isAvailable
                  ? _isCurrentServerWorking()
                      ? (_webViewController != null
                          ? WebViewWidget(controller: _webViewController!)
                          : const SizedBox.shrink())
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(LucideIcons.play, color: Colors.amber, size: 32),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Server Not Available',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This episode is not available in this server, so please check the next server.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _tryNextServer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Try Next Server'),
                                ),
                              ],
                            ),
                          ),
                        )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Episode Stream Not Available',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Please check again later or reload.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool isDesktop, BoxConstraints constraints) {
    final homeData = Provider.of<DataProvider>(context).homeData ?? {};
    final popularList = List<Anime>.from(homeData['mostPopularAnimes'] ?? []);

    final recommendedAnimes = _detail?.recommendations ?? [];
    final hasRecommended = recommendedAnimes.isNotEmpty;
    final hasPopular = popularList.isNotEmpty;

    if (isDesktop && hasPopular) {
      final double sidebarWidth = constraints.maxWidth > 1200 ? 380 : 300;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Recommended
          if (hasRecommended)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Recommended For You', padding: EdgeInsets.zero),
                  const SizedBox(height: 16),
                  AnimeGrid(animes: recommendedAnimes, padding: EdgeInsets.zero),
                ],
              ),
            ),
          if (hasRecommended) const SizedBox(width: 32),

          // Right sidebar: Most Popular
          SizedBox(
            width: sidebarWidth,
            child: _buildPopularSidebar(popularList),
          ),
        ],
      );
    } else {
      // Mobile vertical stack
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasRecommended) ...[
            const SectionHeader(title: 'Recommended For You', padding: EdgeInsets.zero),
            const SizedBox(height: 16),
            AnimeGrid(animes: recommendedAnimes, padding: EdgeInsets.zero),
            const SizedBox(height: 32),
          ],
          if (hasPopular) ...[
            _buildPopularSidebar(popularList),
          ],
        ],
      );
    }
  }

  Widget _buildPopularSidebar(List<Anime> popularList) {
    final int popularCount = popularList.length;
    final displayedList = _showAllPopular ? popularList : popularList.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.flame, color: AppTheme.primaryBlue, size: 18),
            SizedBox(width: 8),
            Text(
              'Most Popular',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: List.generate(displayedList.length, (index) {
                    final item = displayedList[index];
                    final itemTitle = AnimeUtils.getTitle(context, item);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: GestureDetector(
                        onTap: () => context.push('/${AnimeUtils.slugify(itemTitle)}/${item.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              // Poster image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.poster,
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[850]!,
                                    highlightColor: Colors.grey[700]!,
                                    child: Container(color: Colors.black),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (item.type.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.black.withValues(alpha: 0.05),
                                            ),
                                            child: Text(
                                              item.type.replaceAll('_', ' '),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        if (item.year != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.03),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              '${item.year}',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        if (item.rating != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 10),
                                                const SizedBox(width: 2),
                                                Text(
                                                  item.rating!,
                                                  style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (popularCount > 5) ...[
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showAllPopular = !_showAllPopular;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllPopular ? 'Show Less' : 'Show More (${popularCount - 5})',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllPopular ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
