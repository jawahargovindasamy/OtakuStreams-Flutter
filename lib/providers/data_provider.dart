import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/anime.dart';

class DataProvider with ChangeNotifier {
  final Dio _dio = Dio();
  static const String anilistApi = 'https://graphql.anilist.co';
  static const String jikanApi = 'https://api.jikan.moe/v4';

  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? get homeData => _homeData;

  // Cache Map
  final Map<String, dynamic> _cache = {};
  final Map<String, int> _cacheTimestamp = {};
  // Track active requests to prevent duplicate concurrent flights (cache stampede protection)
  final Map<String, Future<dynamic>> _inProgressRequests = {};
  static const Duration cacheTtl = Duration(minutes: 10);

  Future<dynamic> _fetchWithRetry(Future<dynamic> Function() fn, {int retries = 3, int delayMs = 1000}) async {
    try {
      return await fn();
    } catch (e) {
      if (retries > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
        return _fetchWithRetry(fn, retries: retries - 1, delayMs: delayMs * 2);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _anilistQuery(String query, [Map<String, dynamic> variables = const {}]) async {
    final response = await _fetchWithRetry(() => _dio.post(
      anilistApi,
      data: {'query': query, 'variables': variables},
      options: Options(receiveTimeout: const Duration(seconds: 15), sendTimeout: const Duration(seconds: 15)),
    ));
    return response.data;
  }

  Future<dynamic> _fetchWithCache(String key, Future<dynamic> Function() fn, [Duration ttl = cacheTtl]) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _cache[key];
    final timestamp = _cacheTimestamp[key];

    if (cached != null && timestamp != null && (now - timestamp < ttl.inMilliseconds)) {
      return cached;
    }

    if (_inProgressRequests.containsKey(key)) {
      return _inProgressRequests[key]!;
    }

    final future = fn().then((data) {
      if (data != null) {
        _cache[key] = data;
        _cacheTimestamp[key] = DateTime.now().millisecondsSinceEpoch;
      }
      _inProgressRequests.remove(key);
      return data;
    }).catchError((e) {
      _inProgressRequests.remove(key);
      throw e;
    });

    _inProgressRequests[key] = future;
    return future;
  }

  bool isCached(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _cache[key];
    final timestamp = _cacheTimestamp[key];
    return cached != null && timestamp != null && (now - timestamp < cacheTtl.inMilliseconds);
  }

  dynamic getCached(String key) {
    if (isCached(key)) return _cache[key];
    return null;
  }

  Future<void> fetchHomedata() async {
    try {
      final data = await _fetchWithCache('home', () async {
        const query = '''
          query {
            trending: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: TRENDING_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } status popularity nextAiringEpisode { episode } }
            }
            popular: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } popularity nextAiringEpisode { episode } }
            }
            topAiring: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], status: RELEASING, genre_not_in: ["Hentai"], sort: SCORE_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } popularity nextAiringEpisode { episode } }
            }
            favorite: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: FAVOURITES_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } popularity nextAiringEpisode { episode } }
            }
            latestCompleted: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], status: FINISHED, genre_not_in: ["Hentai"], sort: END_DATE_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } popularity nextAiringEpisode { episode } }
            }
            topUpcoming: Page(page: 1, perPage: 15) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], status: NOT_YET_RELEASED, genre_not_in: ["Hentai"], sort: POPULARITY_DESC) { id idMal title { english romaji native } coverImage { extraLarge large } bannerImage description format episodes averageScore seasonYear startDate { year } popularity nextAiringEpisode { episode } }
            }
            GenreCollection
          }
        ''';
        final res = await _anilistQuery(query);
        final resData = res['data'] ?? {};

        final trending = (resData['trending']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final popular = (resData['popular']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final topAiring = (resData['topAiring']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final favorite = (resData['favorite']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final latestCompleted = (resData['latestCompleted']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final topUpcoming = (resData['topUpcoming']?['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final genres = (resData['GenreCollection'] as List? ?? [])
            .where((g) => g != null && g.toString() != 'Hentai')
            .map((g) => g.toString())
            .toList();

        return {
          'trendingAnimes': trending.take(10).toList(),
          'topAiringAnimes': topAiring,
          'mostPopularAnimes': popular,
          'mostFavoriteAnimes': favorite,
          'latestCompletedAnimes': latestCompleted,
          'latestEpisodeAnimes': topAiring,
          'topUpcomingAnimes': topUpcoming,
          'spotlightAnimes': trending.take(10).toList(),
          'genres': genres,
          'top10Animes': {
            'today': trending.take(10).toList(),
            'week': popular.take(10).toList(),
            'month': favorite.take(10).toList(),
          }
        };
      }, const Duration(hours: 5));

      _homeData = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch home data error: $e');
    }
  }

  Future<AnimeDetail?> fetchanimeinfo(String id) async {
    return await _fetchWithCache('anime-$id', () async {
      try {
        final isMal = id.startsWith('mal-');
        final cleanId = isMal ? int.parse(id.replaceAll('mal-', '')) : int.parse(id);

        const query = '''
          query (\$id: Int, \$idMal: Int) {
            Media(id: \$id, idMal: \$idMal, type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT]) {
              id
              idMal
              title { english romaji native }
              synonyms
              coverImage { extraLarge large }
              bannerImage
              description
              episodes
              nextAiringEpisode { episode }
              streamingEpisodes { title }
              status
              averageScore
              genres
              season
              seasonYear
              startDate { year }
              format
              popularity
              studios(isMain: true) { nodes { name } }
              characters(sort: [ROLE, FAVOURITES_DESC], page: 1, perPage: 12) {
                edges {
                  role
                  node { id name { full } image { large } }
                  voiceActors(language: JAPANESE) { id name { full } image { large } languageV2 }
                }
              }
              recommendations(sort: RATING_DESC, page: 1, perPage: 15) {
                nodes { mediaRecommendation { id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity } }
              }
              relations {
                edges { relationType node { id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity } }
              }
            }
          }
        ''';

        final res = await _anilistQuery(query, isMal ? {'idMal': cleanId} : {'id': cleanId});
        final media = res['data']?['Media'];
        if (media == null) return null;

        final recNodes = media['recommendations']?['nodes'] as List? ?? [];
        final recs = recNodes
            .map((r) => r['mediaRecommendation'])
            .where((m) => m != null)
            .map((m) => Anime.fromAniList(m))
            .toList();

        final relEdges = media['relations']?['edges'] as List? ?? [];
        final rels = relEdges
            .map((r) => r['node'])
            .where((m) => m != null)
            .map((m) => Anime.fromAniList(m))
            .toList();

        return AnimeDetail.fromAniList(media, recs, rels);
      } catch (e) {
        debugPrint('Fetch anime info error: $e');
        return null;
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>?> fetchmediarelations(String id) async {
    final cleanId = int.tryParse(id);
    if (cleanId == null) return null;

    final cacheKey = 'media-relations-$cleanId';
    return await _fetchWithCache(cacheKey, () async {
      try {
        const query = '''
          query (\$id: Int) {
            Media(id: \$id, type: ANIME, isAdult: false) {
              id
              idMal
              title {
                romaji
                english
                native
              }
              format
              startDate {
                year
              }
              seasonYear
              relations {
                edges {
                  relationType
                  node {
                    id
                    idMal
                    type
                    format
                    title {
                      romaji
                      english
                      native
                    }
                    startDate {
                      year
                    }
                    seasonYear
                  }
                }
              }
            }
          }
        ''';

        final res = await _anilistQuery(query, {'id': cleanId});
        return res['data']?['Media'];
      } catch (e) {
        debugPrint('Fetch media relations error: $e');
        return null;
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>> fetchsearch(String keyword, [int page = 1]) async {
    final cacheKey = 'search-$keyword-page-$page';
    return await _fetchWithCache(cacheKey, () async {
      try {
        const query = '''
          query(\$q: String, \$page: Int) {
            Page(page: \$page, perPage: 24) {
              pageInfo { hasNextPage lastPage }
              media(search: \$q, type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity
              }
            }
            popular: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity
              }
            }
          }
        ''';

        final res = await _anilistQuery(query, {'q': keyword, 'page': page});
        final searchPage = res['data']?['Page'] ?? {};
        final popularPage = res['data']?['popular'] ?? {};

        final list = (searchPage['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final popularList = (popularPage['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();

        return {
          'animes': list,
          'mostPopularAnimes': popularList,
          'searchQuery': keyword,
          'currentPage': page,
          'hasNextPage': searchPage['pageInfo']?['hasNextPage'] ?? false,
          'totalPages': searchPage['pageInfo']?['lastPage'] ?? 1,
        };
      } catch (e) {
        debugPrint('AniList search failed: $e');
        return {'animes': <Anime>[], 'mostPopularAnimes': <Anime>[], 'currentPage': page, 'hasNextPage': false, 'totalPages': 0};
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>> fetchadvancedsearch({
    String? q,
    int page = 1,
    String? type,
    String? status,
    String? rated,
    String? score,
    String? season,
    String? sort,
    String? startDate,
    String? endDate,
    List<String>? genres,
  }) async {
    final cacheKey = 'advanced-search-$q-$page-$type-$status-$rated-$score-$season-$sort-$startDate-$endDate-${genres?.join(',')}';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final Map<String, dynamic> variables = {
          'page': page,
          'perPage': 24,
        };

        if (q != null && q.isNotEmpty) {
          variables['search'] = q;
        }

        if (type != null && type != 'all') {
          variables['format'] = type.toUpperCase();
        }

        if (status != null && status != 'all') {
          final statusMap = {
            "finished-airing": "FINISHED",
            "currently-airing": "RELEASING",
            "not-yet-aired": "NOT_YET_RELEASED"
          };
          variables['status'] = statusMap[status] ?? status.toUpperCase();
        }

        if (genres != null && genres.isNotEmpty) {
          final genreMap = {
            "action": "Action",
            "adventure": "Adventure",
            "comedy": "Comedy",
            "drama": "Drama",
            "ecchi": "Ecchi",
            "fantasy": "Fantasy",
            "hentai": "Hentai",
            "horror": "Horror",
            "mahou-shoujo": "Mahou Shoujo",
            "mecha": "Mecha",
            "music": "Music",
            "mystery": "Mystery",
            "psychological": "Psychological",
            "romance": "Romance",
            "sci-fi": "Sci-Fi",
            "slice-of-life": "Slice of Life",
            "sports": "Sports",
            "supernatural": "Supernatural",
            "thriller": "Thriller",
            "martial-arts": "Martial Arts",
            "martial arts": "Martial Arts",
            "slice of life": "Slice of Life",
            "super-power": "Super Power",
            "super power": "Super Power"
          };
          variables['genre_in'] = genres.map((g) => genreMap[g.toLowerCase()] ?? g).toList();
        }

        if (sort != null && sort != 'default') {
          final sortMap = {
            "name_az": "TITLE_ROMAJI",
            "recently-added": "START_DATE_DESC",
            "released-date": "START_DATE_DESC",
            "most-watched": "POPULARITY_DESC"
          };
          variables['sort'] = [sortMap[sort] ?? "POPULARITY_DESC"];
        } else {
          variables['sort'] = ["POPULARITY_DESC"];
        }

        const query = '''
          query (\$page: Int, \$perPage: Int, \$search: String, \$format: MediaFormat, \$status: MediaStatus, \$genre_in: [String], \$sort: [MediaSort]) {
            Page(page: \$page, perPage: \$perPage) {
              pageInfo { hasNextPage lastPage }
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], search: \$search, format: \$format, status: \$status, genre_in: \$genre_in, sort: \$sort) {
                id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity
              }
            }
            popular: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes averageScore seasonYear startDate { year } popularity
              }
            }
          }
        ''';

        final res = await _anilistQuery(query, variables);
        final searchPage = res['data']?['Page'] ?? {};
        final popularPage = res['data']?['popular'] ?? {};

        final list = (searchPage['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();
        final popularList = (popularPage['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList();

        return {
          'animes': list,
          'mostPopularAnimes': popularList,
          'searchQuery': q,
          'currentPage': page,
          'hasNextPage': searchPage['pageInfo']?['hasNextPage'] ?? false,
          'totalPages': searchPage['pageInfo']?['lastPage'] ?? 1,
        };
      } catch (e) {
        debugPrint('AniList advanced search failed: $e');
        return {
          'animes': <Anime>[],
          'mostPopularAnimes': <Anime>[],
          'searchQuery': q,
          'currentPage': page,
          'hasNextPage': false,
          'totalPages': 0,
        };
      }
    }, const Duration(hours: 5));
  }

  Future<List<Episode>> fetchepisodeinfo(String id) async {
    final cacheKey = 'episodes-$id';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final isMal = id.startsWith('mal-');
        final cleanId = isMal ? int.parse(id.replaceAll('mal-', '')) : int.parse(id);

        int? malId;
        String? status;
        int? totalEpisodes;
        Map<String, dynamic>? nextAiringEpisode;
        List<dynamic>? streamingEpisodes;

        if (isMal) {
          malId = cleanId;
        } else {
          const query = '''
            query(\$id: Int) {
              Media(id: \$id, type: ANIME, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT]) {
                idMal
                status
                episodes
                nextAiringEpisode { episode }
                streamingEpisodes { title }
              }
            }
          ''';
          final res = await _anilistQuery(query, {'id': cleanId});
          final media = res['data']?['Media'];
          if (media != null) {
            malId = media['idMal'];
            status = media['status'];
            totalEpisodes = media['episodes'];
            nextAiringEpisode = media['nextAiringEpisode'];
            streamingEpisodes = media['streamingEpisodes'];
          }
        }

        List<Episode> episodesList = [];

        // Try Jikan
        if (malId != null) {
          try {
            int page = 1;
            bool hasNext = true;
            while (hasNext && page <= 15) {
              final response = await _dio.get('$jikanApi/anime/$malId/episodes?page=$page');
              final data = response.data['data'] as List? ?? [];
              
              episodesList.addAll(data.map((ep) => Episode.fromJikan(Map<String, dynamic>.from(ep))));
              
              hasNext = response.data['pagination']?['has_next_page'] ?? false;
              page++;
              if (hasNext && page <= 15) {
                await Future.delayed(const Duration(milliseconds: 300));
              }
            }
          } catch (e) {
            debugPrint('Jikan episodes failed: $e');
          }
        }

        // Fallback: Generate dummy episodes if Jikan failed or is behind AniList
        int aniListCount = 0;
        if (status == "NOT_YET_RELEASED") {
          aniListCount = 0;
        } else if (status == "RELEASING" && nextAiringEpisode != null) {
          final nextEpNum = nextAiringEpisode['episode'];
          if (nextEpNum != null) {
            aniListCount = (nextEpNum as num).toInt() - 1;
          }
        } else {
          final airingCount = nextAiringEpisode != null ? (nextAiringEpisode['episode'] as num).toInt() - 1 : 0;
          final totalCount = totalEpisodes ?? 0;
          final streamingCount = streamingEpisodes?.length ?? 0;
          
          aniListCount = airingCount;
          if (totalCount > aniListCount) aniListCount = totalCount;
          if (streamingCount > aniListCount) aniListCount = streamingCount;
        }

        final currentCount = episodesList.length;
        if (currentCount < aniListCount) {
          final lastNumber = currentCount > 0 ? episodesList.last.number : 0;
          for (int i = lastNumber + 1; i <= aniListCount; i++) {
            episodesList.add(Episode(
              episodeId: i.toString(),
              number: i,
              title: 'Episode $i',
              isFiller: false,
            ));
          }
        }

        // Final Fallback: If still empty, ensure at least one episode
        if (episodesList.isEmpty) {
          episodesList.add(Episode(
            episodeId: '1',
            number: 1,
            title: 'Episode 1',
            isFiller: false,
          ));
        }

        return episodesList;
      } catch (e) {
        debugPrint('Fetch episodes failed: $e');
        return [Episode(episodeId: '1', number: 1, title: 'Episode 1', isFiller: false)];
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>> fetchestimatedschedules([String? dateStr]) async {
    final targetDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = startTimestamp + 86400;

    final cacheKey = 'schedule-$startTimestamp';
    return await _fetchWithCache(cacheKey, () async {
      try {
        const query = '''
          query (\$start: Int, \$end: Int, \$page: Int) {
            Page(page: \$page, perPage: 50) {
              pageInfo { hasNextPage }
              airingSchedules(airingAt_greater: \$start, airingAt_lesser: \$end, sort: TIME) {
                id airingAt episode media { id idMal title { english romaji native } coverImage { large } format episodes popularity }
              }
            }
          }
        ''';

        final List<dynamic> allSchedules = [];
        int page = 1;
        bool hasNext = true;

        while (hasNext) {
          final res = await _anilistQuery(query, {'start': startTimestamp, 'end': endTimestamp, 'page': page});
          final airing = res['data']?['Page']?['airingSchedules'] as List? ?? [];
          allSchedules.addAll(airing);
          hasNext = res['data']?['Page']?['pageInfo']?['hasNextPage'] ?? false;
          page++;
        }

        final filtered = allSchedules.where((item) {
          final format = item['media']?['format'];
          return format != 'TV_SHORT' && format != 'MANGA' && format != 'NOVEL' && format != 'ONE_SHOT' && format != 'MUSIC';
        });

        final scheduledAnimes = filtered.map((item) {
          final airingAt = item['airingAt'] as int;
          final epDate = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000).toLocal();
          final timeStr = '${epDate.hour.toString().padLeft(2, '0')}:${epDate.minute.toString().padLeft(2, '0')}';
          return ScheduledAnime.fromAniListSchedule(item, timeStr);
        }).toList();

        return {'scheduledAnimes': scheduledAnimes};
      } catch (e) {
        debugPrint('Schedule fetch failed: $e');
        return {'scheduledAnimes': <ScheduledAnime>[]};
      }
    }, const Duration(days: 1));
  }

  Future<Map<String, dynamic>?> fetchnextepisodeschedule(String id) async {
    final cacheKey = 'next-episode-schedule-$id';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final cleanId = int.parse(id.replaceAll('mal-', ''));
        const query = '''
          query(\$id: Int) {
            Media(id: \$id, type: ANIME) { nextAiringEpisode { airingAt episode } }
          }
        ''';
        final res = await _anilistQuery(query, {'id': cleanId});
        final nextEp = res['data']?['Media']?['nextAiringEpisode'];
        if (nextEp != null) {
          return {
            'airingTimestamp': (nextEp['airingAt'] as int) * 1000,
            'episode': nextEp['episode'] as int,
          };
        }
        return null;
      } catch (e) {
        return null;
      }
    }, const Duration(hours: 2));
  }

  Future<Map<String, dynamic>> fetchcategories(String category, [int page = 1]) async {
    final cacheKey = 'category-$category-page-$page';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final Map<String, dynamic> variables = {'page': page, 'perPage': 24};
        final Map<String, dynamic> sorting = {};

        switch (category) {
          case 'most-popular':
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'top-airing':
            sorting['status'] = 'RELEASING';
            sorting['sort'] = ['SCORE_DESC'];
            break;
          case 'most-favorite':
            sorting['sort'] = ['FAVOURITES_DESC'];
            break;
          case 'top-upcoming':
            sorting['status'] = 'NOT_YET_RELEASED';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'completed':
            sorting['status'] = 'FINISHED';
            sorting['sort'] = ['END_DATE_DESC'];
            break;
          case 'tv':
            sorting['format'] = 'TV';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'movie':
            sorting['format'] = 'MOVIE';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'ova':
            sorting['format'] = 'OVA';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'ona':
            sorting['format'] = 'ONA';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'special':
            sorting['format'] = 'SPECIAL';
            sorting['sort'] = ['POPULARITY_DESC'];
            break;
          case 'recently-updated':
            sorting['sort'] = ['UPDATED_AT_DESC'];
            break;
        }

        final vars = {...variables, ...sorting};
        final hasFormat = sorting['format'] != null;

        final query = hasFormat
            ? '''
          query(\$page: Int, \$perPage: Int, \$sort: [MediaSort], \$status: MediaStatus, \$format: MediaFormat) {
            Page(page: \$page, perPage: \$perPage) {
              pageInfo { hasNextPage lastPage }
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: \$sort, status: \$status, format: \$format) {
                id idMal title { english romaji native } coverImage { large } format episodes seasonYear startDate { year } popularity averageScore
              }
            }
            topToday: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: TRENDING_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            topWeek: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            topMonth: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: SCORE_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            GenreCollection
          }
        '''
            : '''
          query(\$page: Int, \$perPage: Int, \$sort: [MediaSort], \$status: MediaStatus) {
            Page(page: \$page, perPage: \$perPage) {
              pageInfo { hasNextPage lastPage }
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: \$sort, status: \$status) {
                id idMal title { english romaji native } coverImage { large } format episodes seasonYear startDate { year } popularity averageScore
              }
            }
            topToday: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: TRENDING_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            topWeek: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            topMonth: Page(page: 1, perPage: 10) { media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: SCORE_DESC) { id idMal title { english romaji native } coverImage { large } format episodes popularity averageScore seasonYear startDate { year } } }
            GenreCollection
          }
        ''';

        final res = await _anilistQuery(query, vars);
        final pageData = res['data']?['Page'] ?? {};
        final today = res['data']?['topToday']?['media'] as List? ?? [];
        final week = res['data']?['topWeek']?['media'] as List? ?? [];
        final month = res['data']?['topMonth']?['media'] as List? ?? [];
        final genres = res['data']?['GenreCollection'] as List? ?? [];

        return {
          'animes': pageData['media'] != null ? (pageData['media'] as List).map((m) => Anime.fromAniList(m)).toList() : <Anime>[],
          'top10Animes': {
            'today': today.map((m) => Anime.fromAniList(m)).toList(),
            'week': week.map((m) => Anime.fromAniList(m)).toList(),
            'month': month.map((m) => Anime.fromAniList(m)).toList(),
          },
          'genres': genres.where((g) => g != null && g.toString() != 'Hentai').map((g) => g.toString()).toList(),
          'category': category.replaceAll('-', ' ').toUpperCase(),
          'currentPage': page,
          'hasNextPage': pageData['pageInfo']?['hasNextPage'] ?? false,
          'totalPages': pageData['pageInfo']?['lastPage'] ?? 1,
        };
      } catch (e) {
        debugPrint('Category fetch failed: $e');
        return {'animes': <Anime>[], 'currentPage': page, 'hasNextPage': false, 'totalPages': 0};
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>> fetchgenres(String name, [int page = 1, String? type]) async {
    final cacheKey = 'genre-$name-page-$page-type-$type';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final Map<String, String> genreMap = {
          'action': 'Action',
          'adventure': 'Adventure',
          'comedy': 'Comedy',
          'drama': 'Drama',
          'ecchi': 'Ecchi',
          'fantasy': 'Fantasy',
          'hentai': 'Hentai',
          'horror': 'Horror',
          'mahou-shoujo': 'Mahou Shoujo',
          'mecha': 'Mecha',
          'music': 'Music',
          'mystery': 'Mystery',
          'psychological': 'Psychological',
          'romance': 'Romance',
          'sci-fi': 'Sci-Fi',
          'slice-of-life': 'Slice of Life',
          'sports': 'Sports',
          'supernatural': 'Supernatural',
          'thriller': 'Thriller'
        };

        final cleanName = name.toLowerCase().replaceAll(' ', '-').replaceAll('%20', '-');
        final formattedGenre = genreMap[cleanName] ?? name.split('-').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');

        final hasFormat = type != null && type.isNotEmpty;
        final query = hasFormat
            ? '''
          query (\$genre: String, \$page: Int, \$format: MediaFormat) {
            Page(page: \$page, perPage: 24) {
              pageInfo { hasNextPage lastPage }
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], genre_in: [\$genre], sort: POPULARITY_DESC, format: \$format) {
                id idMal title { english romaji native } coverImage { large } format episodes seasonYear startDate { year } popularity averageScore
              }
            }
            topAiring: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], status: RELEASING, sort: SCORE_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes popularity
              }
            }
            GenreCollection
          }
        '''
            : '''
          query (\$genre: String, \$page: Int) {
            Page(page: \$page, perPage: 24) {
              pageInfo { hasNextPage lastPage }
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], genre_in: [\$genre], sort: POPULARITY_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes seasonYear startDate { year } popularity averageScore
              }
            }
            topAiring: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], status: RELEASING, sort: SCORE_DESC) {
                id idMal title { english romaji native } coverImage { large } format episodes popularity
              }
            }
            GenreCollection
          }
        ''';

        final Map<String, dynamic> variables = {
          'genre': formattedGenre,
          'page': page,
        };
        if (hasFormat) {
          variables['format'] = type.toUpperCase();
        }

        final res = await _anilistQuery(query, variables);

        final mediaPage = res['data']?['Page'] ?? {};
        final topAiring = res['data']?['topAiring']?['media'] as List? ?? [];
        final genresList = res['data']?['GenreCollection'] as List? ?? [];

        return {
          'animes': (mediaPage['media'] as List? ?? []).map((m) => Anime.fromAniList(m)).toList(),
          'topAiringAnimes': topAiring.map((m) => Anime.fromAniList(m)).toList(),
          'genreName': formattedGenre,
          'currentPage': page,
          'hasNextPage': mediaPage['pageInfo']?['hasNextPage'] ?? false,
          'totalPages': mediaPage['pageInfo']?['lastPage'] ?? 1,
          'genres': genresList.where((g) => g != null && g.toString() != 'Hentai').map((g) => g.toString()).toList(),
        };
      } catch (e) {
        debugPrint('Genre fetch failed: $e');
        return {'animes': <Anime>[], 'topAiringAnimes': <Anime>[], 'currentPage': page, 'hasNextPage': false, 'totalPages': 0};
      }
    }, const Duration(hours: 5));
  }

  Future<Map<String, dynamic>> fetchproducers(String name, int page) async {
    final cacheKey = 'producer-$name-page-$page';
    return await _fetchWithCache(cacheKey, () async {
      try {
        final cleanName = name.replaceAll('-', ' ');

        // 1. Get Studio ID by name
        const studioSearchQuery = '''
          query (\$search: String) {
            Studio(search: \$search) {
              id
              name
            }
          }
        ''';

        final searchRes = await _anilistQuery(studioSearchQuery, {'search': cleanName});
        final studio = searchRes['data']?['Studio'];

        if (studio == null) {
          throw Exception("Studio not found");
        }

        final int studioId = studio['id'] as int;
        final String producerName = studio['name'] as String;

        // 2. Fetch anime list for the studio and sidebar top 10
        const query = '''
          query (\$studioId: Int, \$page: Int) {
            Studio(id: \$studioId) {
              id
              name
              media(page: \$page, perPage: 24, sort: POPULARITY_DESC) {
                pageInfo {
                  hasNextPage
                  lastPage
                }
                nodes {
                  id
                  idMal
                  title {
                    english
                    romaji
                    native
                  }
                  coverImage {
                    large
                  }
                  format
                  episodes
                  seasonYear
                  startDate {
                    year
                  }
                  popularity
                  averageScore
                }
              }
            }
            topToday: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: TRENDING_DESC) {
                id
                idMal
                title {
                  english
                  romaji
                  native
                }
                coverImage {
                  large
                }
                format
                episodes
                seasonYear
                startDate {
                  year
                }
                popularity
                averageScore
              }
            }
            topWeek: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: POPULARITY_DESC) {
                id
                idMal
                title {
                  english
                  romaji
                  native
                }
                coverImage {
                  large
                }
                format
                episodes
                seasonYear
                startDate {
                  year
                }
                popularity
                averageScore
              }
            }
            topMonth: Page(page: 1, perPage: 10) {
              media(type: ANIME, isAdult: false, format_not_in: [TV_SHORT, MANGA, NOVEL, ONE_SHOT], genre_not_in: ["Hentai"], sort: SCORE_DESC) {
                id
                idMal
                title {
                  english
                  romaji
                  native
                }
                coverImage {
                  large
                }
                format
                episodes
                seasonYear
                startDate {
                  year
                }
                popularity
                averageScore
              }
            }
          }
        ''';

        final res = await _anilistQuery(query, {'studioId': studioId, 'page': page});
        final studioMedia = res['data']?['Studio']?['media'];
        final topToday = res['data']?['topToday']?['media'] as List? ?? [];
        final topWeek = res['data']?['topWeek']?['media'] as List? ?? [];
        final topMonth = res['data']?['topMonth']?['media'] as List? ?? [];

        if (studioMedia == null) {
          throw Exception("No media found for studio");
        }

        final mediaNodes = studioMedia['nodes'] as List? ?? [];
        final list = mediaNodes.map((m) => Anime.fromAniList(m)).toList();

        return {
          'animes': list,
          'producerName': producerName,
          'top10Animes': {
            'today': topToday.map((m) => Anime.fromAniList(m)).toList(),
            'week': topWeek.map((m) => Anime.fromAniList(m)).toList(),
            'month': topMonth.map((m) => Anime.fromAniList(m)).toList(),
          },
          'currentPage': page,
          'hasNextPage': studioMedia['pageInfo']?['hasNextPage'] ?? false,
          'totalPages': studioMedia['pageInfo']?['lastPage'] ?? 1,
        };
      } catch (e) {
        debugPrint('Producer fetch failed from AniList: $e');
        return await fetchsearch(name, page);
      }
    }, const Duration(hours: 5));
  }
}
