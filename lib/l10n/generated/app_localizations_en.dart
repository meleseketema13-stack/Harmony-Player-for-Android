// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get playButton => 'Play';

  @override
  String get pauseButton => 'Pause';

  @override
  String get nextButton => 'Next track';

  @override
  String get previousButton => 'Previous track';

  @override
  String get shuffleButton => 'Shuffle';

  @override
  String get repeatButton => 'Repeat';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatAll => 'Repeat all';

  @override
  String get repeatOne => 'Repeat one';

  @override
  String get favoriteButton => 'Favorite';

  @override
  String get toggleFavorite => 'Toggle favorite';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String jumpForward(String interval) {
    return 'Jump forward $interval';
  }

  @override
  String jumpBackward(String interval) {
    return 'Jump backward $interval';
  }

  @override
  String get seekInterval10s => '10 seconds';

  @override
  String get seekInterval30s => '30 seconds';

  @override
  String get seekInterval1m => '1 minute';

  @override
  String get seekInterval10m => '10 minutes';

  @override
  String get seekInterval30m => '30 minutes';

  @override
  String get seekInterval60m => '60 minutes';

  @override
  String seekIntervalSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get seekInterval10sShort => '10 sec';

  @override
  String get seekInterval30sShort => '30 sec';

  @override
  String get seekInterval1mShort => '1 min';

  @override
  String get seekInterval10mShort => '10 min';

  @override
  String get seekInterval30mShort => '30 min';

  @override
  String get seekInterval60mShort => '60 min';

  @override
  String get seekIntervalSetting => 'Seek interval';

  @override
  String get seekIntervalSettingHint =>
      'How far the fast-forward and rewind buttons jump';

  @override
  String get minimizePlayer => 'Minimize player';

  @override
  String get seekBarLabel => 'Seek bar';

  @override
  String get seekHint => 'Swipe up or down to adjust';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get library => 'Library';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get moreOptions => 'More options';

  @override
  String albumArt(String title) {
    return 'Album art for $title';
  }

  @override
  String announcePlayingTrack(String title, String artist) {
    return 'Playing: $title by $artist';
  }

  @override
  String announcePausedTrack(String title, String artist) {
    return 'Paused: $title by $artist';
  }

  @override
  String announceSeekPercent(int percent) {
    return 'Seek bar, $percent percent, swipe up or down to adjust';
  }

  @override
  String get announceShuffleOn => 'Shuffle on';

  @override
  String get announceShuffleOff => 'Shuffle off';

  @override
  String get announceRepeatOff => 'Repeat off';

  @override
  String get announceRepeatAll => 'Repeat all';

  @override
  String get announceRepeatOne => 'Repeat one';

  @override
  String get announceFavoriteOn => 'Added to favorites';

  @override
  String get announceFavoriteOff => 'Removed from favorites';

  @override
  String get announceAddedToPlaylist => 'Added to playlist';

  @override
  String get announcePlayerMinimized => 'Player minimized';

  @override
  String announceError(String title) {
    return 'Unable to play: $title';
  }

  @override
  String get unknownTrack => 'Unknown track';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get lyricsEmpty => 'No lyrics available for this track';

  @override
  String get lyricsHeader => 'Lyrics';

  @override
  String get emptyLibrary => 'No music found on this device.';

  @override
  String get emptySearch => 'Type to search your library.';

  @override
  String get noResults => 'No tracks match your search.';

  @override
  String get noFavorites => 'No favorite tracks yet.';

  @override
  String get loadingLibrary => 'Loading your library…';

  @override
  String get permissionRequiredTitle => 'Music access needed';

  @override
  String get permissionRequiredBody =>
      'HarmonyPlayer needs permission to read the audio files on this device.';

  @override
  String get grantAccessButton => 'Grant access';

  @override
  String get retryButton => 'Retry';

  @override
  String get searchHint => 'Search tracks, artists or albums';

  @override
  String get sortBy => 'Sort tracks';

  @override
  String get sortByTitle => 'Title';

  @override
  String get sortByArtist => 'Artist';

  @override
  String get sortByAlbum => 'Album';

  @override
  String get sortByDuration => 'Duration';

  @override
  String get favoritesOnly => 'Favorites only';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get contentFirstOrder =>
      'Screen reader reads content before navigation';

  @override
  String get contentFirstOrderHint =>
      'Changes the reading order for screen readers on large screens';

  @override
  String get favorites => 'Favorites';

  @override
  String get folders => 'Folders';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get genres => 'Genres';

  @override
  String get playlists => 'Playlists';

  @override
  String get tracks => 'Tracks';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerHint =>
      'Automatically pause playback after a set duration';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String sleepTimerActive(String duration) {
    return 'Sleep timer: $duration';
  }

  @override
  String announceSleepTimerSet(String duration) {
    return 'Sleep timer set for $duration';
  }

  @override
  String get announceSleepTimerCancelled => 'Sleep timer cancelled';

  @override
  String get noFolders => 'No folders with audio files found.';

  @override
  String get noAlbums => 'No albums found.';

  @override
  String get noArtists => 'No artists found.';

  @override
  String get noGenres => 'No genres found.';

  @override
  String get emptyPlaylists => 'Your playlist is empty.';

  @override
  String get folderPlay => 'Play folder';

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String artistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count genres',
      one: '1 genre',
    );
    return '$_temp0';
  }

  @override
  String get accessibility => 'Accessibility';

  @override
  String get accessibilityHint => 'Screen reader and display preferences';

  @override
  String get playback => 'Playback';

  @override
  String get playbackHint => 'Seek intervals and playback preferences';
}
