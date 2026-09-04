import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @pauseButton.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextButton;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousButton;

  /// No description provided for @shuffleButton.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleButton;

  /// No description provided for @repeatButton.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatButton;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get repeatOne;

  /// No description provided for @favoriteButton.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteButton;

  /// No description provided for @toggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle favorite'**
  String get toggleFavorite;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @jumpForward.
  ///
  /// In en, this message translates to:
  /// **'Jump forward {interval}'**
  String jumpForward(String interval);

  /// No description provided for @jumpBackward.
  ///
  /// In en, this message translates to:
  /// **'Jump backward {interval}'**
  String jumpBackward(String interval);

  /// No description provided for @seekInterval10s.
  ///
  /// In en, this message translates to:
  /// **'10 seconds'**
  String get seekInterval10s;

  /// No description provided for @seekInterval30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get seekInterval30s;

  /// No description provided for @seekInterval1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get seekInterval1m;

  /// No description provided for @seekInterval10m.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get seekInterval10m;

  /// No description provided for @seekInterval30m.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get seekInterval30m;

  /// No description provided for @seekInterval60m.
  ///
  /// In en, this message translates to:
  /// **'60 minutes'**
  String get seekInterval60m;

  /// No description provided for @seekIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String seekIntervalSeconds(int seconds);

  /// No description provided for @seekInterval10sShort.
  ///
  /// In en, this message translates to:
  /// **'10 sec'**
  String get seekInterval10sShort;

  /// No description provided for @seekInterval30sShort.
  ///
  /// In en, this message translates to:
  /// **'30 sec'**
  String get seekInterval30sShort;

  /// No description provided for @seekInterval1mShort.
  ///
  /// In en, this message translates to:
  /// **'1 min'**
  String get seekInterval1mShort;

  /// No description provided for @seekInterval10mShort.
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get seekInterval10mShort;

  /// No description provided for @seekInterval30mShort.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get seekInterval30mShort;

  /// No description provided for @seekInterval60mShort.
  ///
  /// In en, this message translates to:
  /// **'60 min'**
  String get seekInterval60mShort;

  /// No description provided for @seekIntervalSetting.
  ///
  /// In en, this message translates to:
  /// **'Seek interval'**
  String get seekIntervalSetting;

  /// No description provided for @seekIntervalSettingHint.
  ///
  /// In en, this message translates to:
  /// **'How far the fast-forward and rewind buttons jump'**
  String get seekIntervalSettingHint;

  /// No description provided for @minimizePlayer.
  ///
  /// In en, this message translates to:
  /// **'Minimize player'**
  String get minimizePlayer;

  /// No description provided for @seekBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Seek bar'**
  String get seekBarLabel;

  /// No description provided for @seekHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up or down to adjust'**
  String get seekHint;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @albumArt.
  ///
  /// In en, this message translates to:
  /// **'Album art for {title}'**
  String albumArt(String title);

  /// No description provided for @announcePlayingTrack.
  ///
  /// In en, this message translates to:
  /// **'Playing: {title} by {artist}'**
  String announcePlayingTrack(String title, String artist);

  /// No description provided for @announcePausedTrack.
  ///
  /// In en, this message translates to:
  /// **'Paused: {title} by {artist}'**
  String announcePausedTrack(String title, String artist);

  /// No description provided for @announceSeekPercent.
  ///
  /// In en, this message translates to:
  /// **'Seek bar, {percent} percent, swipe up or down to adjust'**
  String announceSeekPercent(int percent);

  /// No description provided for @announceShuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on'**
  String get announceShuffleOn;

  /// No description provided for @announceShuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle off'**
  String get announceShuffleOff;

  /// No description provided for @announceRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get announceRepeatOff;

  /// No description provided for @announceRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get announceRepeatAll;

  /// No description provided for @announceRepeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get announceRepeatOne;

  /// No description provided for @announceFavoriteOn.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get announceFavoriteOn;

  /// No description provided for @announceFavoriteOff.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get announceFavoriteOff;

  /// No description provided for @announceAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to playlist'**
  String get announceAddedToPlaylist;

  /// No description provided for @announcePlayerMinimized.
  ///
  /// In en, this message translates to:
  /// **'Player minimized'**
  String get announcePlayerMinimized;

  /// No description provided for @announceError.
  ///
  /// In en, this message translates to:
  /// **'Unable to play: {title}'**
  String announceError(String title);

  /// No description provided for @unknownTrack.
  ///
  /// In en, this message translates to:
  /// **'Unknown track'**
  String get unknownTrack;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @lyricsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available for this track'**
  String get lyricsEmpty;

  /// No description provided for @lyricsHeader.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsHeader;

  /// No description provided for @emptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No music found on this device.'**
  String get emptyLibrary;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search your library.'**
  String get emptySearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No tracks match your search.'**
  String get noResults;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite tracks yet.'**
  String get noFavorites;

  /// No description provided for @loadingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Loading your library…'**
  String get loadingLibrary;

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Music access needed'**
  String get permissionRequiredTitle;

  /// No description provided for @permissionRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'HarmonyPlayer needs permission to read the audio files on this device.'**
  String get permissionRequiredBody;

  /// No description provided for @grantAccessButton.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get grantAccessButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tracks, artists or albums'**
  String get searchHint;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort tracks'**
  String get sortBy;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortByTitle;

  /// No description provided for @sortByArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortByArtist;

  /// No description provided for @sortByAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortByAlbum;

  /// No description provided for @sortByDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortByDuration;

  /// No description provided for @favoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get favoritesOnly;

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String trackCount(int count);

  /// No description provided for @contentFirstOrder.
  ///
  /// In en, this message translates to:
  /// **'Screen reader reads content before navigation'**
  String get contentFirstOrder;

  /// No description provided for @contentFirstOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Changes the reading order for screen readers on large screens'**
  String get contentFirstOrderHint;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically pause playback after a set duration'**
  String get sleepTimerHint;

  /// No description provided for @sleepTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerActive.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer: {duration}'**
  String sleepTimerActive(String duration);

  /// No description provided for @announceSleepTimerSet.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {duration}'**
  String announceSleepTimerSet(String duration);

  /// No description provided for @announceSleepTimerCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer cancelled'**
  String get announceSleepTimerCancelled;

  /// No description provided for @noFolders.
  ///
  /// In en, this message translates to:
  /// **'No folders with audio files found.'**
  String get noFolders;

  /// No description provided for @noAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums found.'**
  String get noAlbums;

  /// No description provided for @noArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists found.'**
  String get noArtists;

  /// No description provided for @noGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres found.'**
  String get noGenres;

  /// No description provided for @emptyPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Your playlist is empty.'**
  String get emptyPlaylists;

  /// No description provided for @folderPlay.
  ///
  /// In en, this message translates to:
  /// **'Play folder'**
  String get folderPlay;

  /// No description provided for @albumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String albumCount(int count);

  /// No description provided for @artistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 artist} other{{count} artists}}'**
  String artistCount(int count);

  /// No description provided for @genreCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 genre} other{{count} genres}}'**
  String genreCount(int count);

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @accessibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Screen reader and display preferences'**
  String get accessibilityHint;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @playbackHint.
  ///
  /// In en, this message translates to:
  /// **'Seek intervals and playback preferences'**
  String get playbackHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
