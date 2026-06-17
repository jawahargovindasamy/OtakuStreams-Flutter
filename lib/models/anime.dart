class Anime {
  final String id;
  final int? malId;
  final String name;
  final String jname;
  final String poster;
  final String? banner;
  final String type;
  final List<String> otherInfo;
  final String subEpisodes;
  final String? dubEpisodes;
  final String? rating;
  final int? year;
  final String? description;
  final int? rank;

  Anime({
    required this.id,
    this.malId,
    required this.name,
    required this.jname,
    required this.poster,
    this.banner,
    required this.type,
    required this.otherInfo,
    required this.subEpisodes,
    this.dubEpisodes,
    this.rating,
    this.year,
    this.description,
    this.rank,
  });

  factory Anime.fromAniList(Map<String, dynamic> media) {
    final title = media['title'] ?? {};
    final name = title['english'] ?? title['romaji'] ?? title['native'] ?? '?';
    final jname = title['romaji'] ?? title['native'] ?? '?';

    final coverImage = media['coverImage'] ?? {};
    final poster = coverImage['extraLarge'] ?? coverImage['large'] ?? '';

    final banner = media['bannerImage'];
    final format = media['format'] != null ? media['format'].toString().toUpperCase() : 'TV';
    
    final startDate = media['startDate'] ?? {};
    final startYear = startDate['year'] ?? media['seasonYear'];
    final yearStr = startYear != null ? startYear.toString() : '?';

    final nextAiring = media['nextAiringEpisode'];
    final episodesCount = nextAiring != null 
        ? (nextAiring['episode'] != null ? nextAiring['episode'] - 1 : media['episodes'])
        : media['episodes'];
    final epString = episodesCount != null ? '$episodesCount' : '?';

    final otherInfo = [
      format,
      '$epString eps',
      yearStr,
    ];

    final score = media['averageScore'];
    final rating = score != null ? (score / 10).toStringAsFixed(1) : null;

    return Anime(
      id: media['id'].toString(),
      malId: media['idMal'],
      name: name,
      jname: jname,
      poster: poster,
      banner: banner,
      type: format,
      otherInfo: otherInfo,
      subEpisodes: epString,
      dubEpisodes: null,
      rating: rating,
      year: startYear,
      description: media['description']?.replaceAll(RegExp(r'<[^>]*>'), ''),
      rank: media['popularity'],
    );
  }

  factory Anime.fromJikan(Map<String, dynamic> anime) {
    final malId = anime['mal_id'] as int;
    final name = anime['title_english'] ?? anime['title'] ?? '?';
    final jname = anime['title_japanese'] ?? anime['title'] ?? '?';

    final images = anime['images'] ?? {};
    final webp = images['webp'] ?? {};
    final poster = webp['large_image_url'] ?? images['jpg']?['large_image_url'] ?? '';

    final type = anime['type'] != null ? anime['type'].toString().toUpperCase() : 'TV';
    final episodesCount = anime['episodes'];
    final epString = episodesCount != null ? '$episodesCount' : '?';
    final year = anime['year'];
    final yearStr = year != null ? year.toString() : '?';

    final otherInfo = [
      type,
      '$epString eps',
      yearStr,
    ];

    final score = anime['score'];
    final rating = score?.toStringAsFixed(1);

    return Anime(
      id: 'mal-$malId',
      malId: malId,
      name: name,
      jname: jname,
      poster: poster,
      banner: null,
      type: type,
      otherInfo: otherInfo,
      subEpisodes: epString,
      rating: rating,
      year: year,
      description: anime['synopsis']?.replaceAll(RegExp(r'<[^>]*>'), ''),
    );
  }

  factory Anime.fromBackend(Map<String, dynamic> item) {
    return Anime(
      id: item['animeId'] ?? '',
      name: item['animeTitle'] ?? '',
      jname: item['animeTitle'] ?? '',
      poster: item['animeImage'] ?? '',
      type: 'TV',
      otherInfo: [],
      subEpisodes: '?',
    );
  }
}

class CharacterActor {
  final String characterId;
  final String characterName;
  final String characterPoster;
  final String characterRole;
  final String? voiceActorName;
  final String? voiceActorPoster;
  final String? voiceActorLanguage;

  CharacterActor({
    required this.characterId,
    required this.characterName,
    required this.characterPoster,
    required this.characterRole,
    this.voiceActorName,
    this.voiceActorPoster,
    this.voiceActorLanguage,
  });

  factory CharacterActor.fromAniListEdge(Map<String, dynamic> edge) {
    final node = edge['node'] ?? {};
    final voiceActors = edge['voiceActors'] as List?;
    final primaryActor = voiceActors != null && voiceActors.isNotEmpty ? voiceActors[0] : null;

    return CharacterActor(
      characterId: node['id']?.toString() ?? '',
      characterName: node['name']?['full'] ?? '',
      characterPoster: node['image']?['large'] ?? '',
      characterRole: edge['role'] ?? '',
      voiceActorName: primaryActor?['name']?['full'],
      voiceActorPoster: primaryActor?['image']?['large'],
      voiceActorLanguage: primaryActor?['languageV2'],
    );
  }
}

class AnimeDetail {
  final Anime anime;
  final String japaneseTitle;
  final String synonyms;
  final String aired;
  final String premiered;
  final String duration;
  final String status;
  final List<String> genres;
  final String studios;
  final List<CharacterActor> characters;
  final List<Anime> recommendations;
  final List<Anime> relations;

  AnimeDetail({
    required this.anime,
    required this.japaneseTitle,
    required this.synonyms,
    required this.aired,
    required this.premiered,
    required this.duration,
    required this.status,
    required this.genres,
    required this.studios,
    required this.characters,
    required this.recommendations,
    required this.relations,
  });

  factory AnimeDetail.fromAniList(Map<String, dynamic> media, List<Anime> recs, List<Anime> rels) {
    final anime = Anime.fromAniList(media);
    final studiosNodes = media['studios']?['nodes'] as List?;
    final studiosStr = studiosNodes != null && studiosNodes.isNotEmpty
        ? studiosNodes.map((s) => s['name']).join(', ')
        : '';

    final charEdges = media['characters']?['edges'] as List? ?? [];
    final characters = charEdges.map((e) => CharacterActor.fromAniListEdge(e)).toList();

    final nextEp = media['nextAiringEpisode'];
    final episodesTotal = media['episodes'];
    final episodesStr = nextEp != null ? '${nextEp['episode'] - 1}' : (episodesTotal != null ? '$episodesTotal' : '?');

    final infoStats = media['format'] != null ? media['format'].toString().toUpperCase() : 'TV';
    final durationMins = media['duration'] != null ? '${media['duration']}m' : '?m';

    final synonyms = media['synonyms'] as List?;
    final synonymStr = synonyms != null && synonyms.isNotEmpty ? synonyms[0].toString() : '';

    return AnimeDetail(
      anime: Anime(
        id: anime.id,
        malId: anime.malId,
        name: anime.name,
        jname: anime.jname,
        poster: anime.poster,
        banner: anime.banner,
        type: infoStats,
        otherInfo: anime.otherInfo,
        subEpisodes: episodesStr,
        rating: anime.rating,
        year: anime.year,
        description: anime.description,
      ),
      japaneseTitle: media['title']?['native'] ?? '',
      synonyms: synonymStr,
      aired: media['seasonYear'] != null ? '${media['season']} ${media['seasonYear']}' : '?',
      premiered: media['seasonYear'] != null ? '${media['season']} ${media['seasonYear']}' : '?',
      duration: durationMins,
      status: media['status'] ?? '?',
      genres: (media['genres'] as List?)?.map((g) => g.toString()).toList() ?? [],
      studios: studiosStr,
      characters: characters,
      recommendations: recs,
      relations: rels,
    );
  }
}

class Episode {
  final String episodeId;
  final int number;
  final String title;
  final bool isFiller;

  Episode({
    required this.episodeId,
    required this.number,
    required this.title,
    required this.isFiller,
  });

  factory Episode.fromJikan(Map<String, dynamic> ep) {
    return Episode(
      episodeId: ep['mal_id'].toString(),
      number: ep['mal_id'] as int,
      title: ep['title'] ?? 'Episode ${ep['mal_id']}',
      isFiller: ep['filler'] ?? false,
    );
  }
}

class ScheduledAnime {
  final String id;
  final String name;
  final String jname;
  final String poster;
  final String type;
  final List<String> otherInfo;
  final String subEpisodes;
  final String time;
  final int episode;

  ScheduledAnime({
    required this.id,
    required this.name,
    required this.jname,
    required this.poster,
    required this.type,
    required this.otherInfo,
    required this.subEpisodes,
    required this.time,
    required this.episode,
  });

  factory ScheduledAnime.fromAniListSchedule(Map<String, dynamic> item, String timeStr) {
    final media = item['media'] ?? {};
    final anime = Anime.fromAniList(media);
    return ScheduledAnime(
      id: anime.id,
      name: anime.name,
      jname: anime.jname,
      poster: anime.poster,
      type: anime.type,
      otherInfo: anime.otherInfo,
      subEpisodes: '${item['episode'] ?? "?"}',
      time: timeStr,
      episode: item['episode'] ?? 1,
    );
  }
}
