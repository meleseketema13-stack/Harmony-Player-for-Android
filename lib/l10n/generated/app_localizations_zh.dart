// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get playButton => '播放';

  @override
  String get pauseButton => '暂停';

  @override
  String get nextButton => '下一首';

  @override
  String get previousButton => '上一首';

  @override
  String get shuffleButton => '随机播放';

  @override
  String get repeatButton => '循环播放';

  @override
  String get repeatOff => '关闭循环';

  @override
  String get repeatAll => '列表循环';

  @override
  String get repeatOne => '单曲循环';

  @override
  String get favoriteButton => '收藏';

  @override
  String get toggleFavorite => '切换收藏';

  @override
  String get addToPlaylist => '添加到播放列表';

  @override
  String jumpForward(String interval) {
    return '快进 $interval';
  }

  @override
  String jumpBackward(String interval) {
    return '快退 $interval';
  }

  @override
  String get seekInterval10s => '10 秒';

  @override
  String get seekInterval30s => '30 秒';

  @override
  String get seekInterval1m => '1 分钟';

  @override
  String get seekInterval10m => '10 分钟';

  @override
  String get seekInterval30m => '30 分钟';

  @override
  String get seekInterval60m => '60 分钟';

  @override
  String seekIntervalSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get seekInterval10sShort => '10 秒';

  @override
  String get seekInterval30sShort => '30 秒';

  @override
  String get seekInterval1mShort => '1 分钟';

  @override
  String get seekInterval10mShort => '10 分钟';

  @override
  String get seekInterval30mShort => '30 分钟';

  @override
  String get seekInterval60mShort => '60 分钟';

  @override
  String get seekIntervalSetting => '跳转间隔';

  @override
  String get seekIntervalSettingHint => '快进和快退按钮每次跳转的距离';

  @override
  String get minimizePlayer => '最小化播放器';

  @override
  String get seekBarLabel => '进度条';

  @override
  String get seekHint => '上下滑动调整';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get library => '音乐库';

  @override
  String get search => '搜索';

  @override
  String get settings => '设置';

  @override
  String get moreOptions => '更多选项';

  @override
  String albumArt(String title) {
    return '$title 的专辑封面';
  }

  @override
  String announcePlayingTrack(String title, String artist) {
    return '正在播放：$title，演唱者 $artist';
  }

  @override
  String announcePausedTrack(String title, String artist) {
    return '已暂停：$title，演唱者 $artist';
  }

  @override
  String announceSeekPercent(int percent) {
    return '进度条，$percent%，上下滑动调整';
  }

  @override
  String get announceShuffleOn => '随机播放已开启';

  @override
  String get announceShuffleOff => '随机播放已关闭';

  @override
  String get announceRepeatOff => '循环已关闭';

  @override
  String get announceRepeatAll => '列表循环';

  @override
  String get announceRepeatOne => '单曲循环';

  @override
  String get announceFavoriteOn => '已添加到收藏';

  @override
  String get announceFavoriteOff => '已从收藏移除';

  @override
  String get announceAddedToPlaylist => '已添加到播放列表';

  @override
  String get announcePlayerMinimized => '播放器已最小化';

  @override
  String announceError(String title) {
    return '无法播放：$title';
  }

  @override
  String get unknownTrack => '未知曲目';

  @override
  String get unknownArtist => '未知歌手';

  @override
  String get lyricsEmpty => '此曲目暂无歌词';

  @override
  String get lyricsHeader => '歌词';

  @override
  String get emptyLibrary => '此设备上未找到音乐。';

  @override
  String get emptySearch => '输入以搜索您的音乐库。';

  @override
  String get noResults => '没有匹配的曲目。';

  @override
  String get noFavorites => '还没有收藏的歌曲。';

  @override
  String get loadingLibrary => '正在加载音乐库…';

  @override
  String get permissionRequiredTitle => '需要音乐访问权限';

  @override
  String get permissionRequiredBody => 'HarmonyPlayer 需要读取此设备上的音频文件。';

  @override
  String get grantAccessButton => '授予权限';

  @override
  String get retryButton => '重试';

  @override
  String get searchHint => '搜索歌曲、歌手或专辑';

  @override
  String get sortBy => '排序';

  @override
  String get sortByTitle => '标题';

  @override
  String get sortByArtist => '歌手';

  @override
  String get sortByAlbum => '专辑';

  @override
  String get sortByDuration => '时长';

  @override
  String get favoritesOnly => '仅收藏';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲',
      one: '1 首歌曲',
    );
    return '$_temp0';
  }

  @override
  String get contentFirstOrder => '屏幕阅读器优先朗读内容而非导航';

  @override
  String get contentFirstOrderHint => '在大屏上更改屏幕阅读器的朗读顺序';

  @override
  String get favorites => '收藏';

  @override
  String get folders => '文件夹';

  @override
  String get albums => '专辑';

  @override
  String get artists => '歌手';

  @override
  String get genres => '流派';

  @override
  String get playlists => '播放列表';

  @override
  String get tracks => '歌曲';

  @override
  String get sleepTimer => '睡眠定时器';

  @override
  String get sleepTimerHint => '在设定时间后自动暂停播放';

  @override
  String get sleepTimerOff => '关闭';

  @override
  String sleepTimerActive(String duration) {
    return '睡眠定时器：$duration';
  }

  @override
  String announceSleepTimerSet(String duration) {
    return '睡眠定时器已设置为 $duration';
  }

  @override
  String get announceSleepTimerCancelled => '睡眠定时器已取消';

  @override
  String get noFolders => '未找到包含音频文件的文件夹。';

  @override
  String get noAlbums => '未找到专辑。';

  @override
  String get noArtists => '未找到歌手。';

  @override
  String get noGenres => '未找到流派。';

  @override
  String get emptyPlaylists => '您的播放列表为空。';

  @override
  String get folderPlay => '播放文件夹';

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张专辑',
      one: '1 张专辑',
    );
    return '$_temp0';
  }

  @override
  String artistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 位歌手',
      one: '1 位歌手',
    );
    return '$_temp0';
  }

  @override
  String genreCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个流派',
      one: '1 个流派',
    );
    return '$_temp0';
  }

  @override
  String get accessibility => '无障碍';

  @override
  String get accessibilityHint => '屏幕阅读器和显示偏好';

  @override
  String get playback => '播放';

  @override
  String get playbackHint => '跳转间隔和播放偏好';
}
