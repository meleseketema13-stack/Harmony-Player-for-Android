# Changelog

## 0.3.0

A cleanup release focused on the bottom playback area and screen reader speech.

**One playback bar instead of two.** The mini player and the separate transport bar that sat beneath it are now a single bar holding artwork, track title, and Previous / Play / Next. This halves the number of swipe stops along the bottom edge, which makes touch exploration and Explore by Touch easier to move through. Tapping the artwork or title opens the full player, which carries all five transport controls plus Favorite, Add to playlist, Shuffle, and Repeat.

**Cleaner speech on action buttons.** Play, Pause, and the other buttons were being announced with a "Switch on" or "Switch off" prefix, because they were exposed to the platform as toggle switches. They are plain action buttons, so they are now announced simply as "Play" or "Pause". State that still matters, such as whether Shuffle is on, is spoken as part of the button rather than as a separate switch state.

**No playback controls on the Settings page.** The settings page already hid the mini player, but the transport bar underneath stayed visible. Both are now hidden, so nothing from the player interrupts while adjusting preferences.

**Tablet and foldable fix.** On large screens the jump backward and jump forward buttons disappeared. They are back in the side panel, which together with the bottom bar again offers all five transport controls.

Also updated: the Android version number is now taken from `pubspec.yaml` instead of being hardcoded separately, so the two can no longer drift apart.

## 0.2.0

First release with Sleep timer, folder playback, library tabs, Favorites, and the responsive layout rework.