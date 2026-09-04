import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/track_index.dart';

/// Album art that exposes itself as a single image semantics node.
///
/// The artwork is decorative for controls, so it is never announced as an
/// interactive element — but it *does* carry a meaningful label ("Album art
/// for {title}") so screen readers can orient the user in the layout.
///
/// Resolution order: [mediaId] (MediaStore artwork bytes) wins over [artUri],
/// which is used by the platform media session and file-based art.
class AlbumArt extends ConsumerWidget {
  const AlbumArt({
    super.key,
    required this.label,
    this.artUri,
    this.mediaId,
    this.size = 200,
    this.borderRadius = 16,
  });

  final String label;
  final Uri? artUri;
  final int? mediaId;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final Widget art = _art(context, ref, scheme);

    return Semantics(
      container: true,
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox.square(
          dimension: size,
          child: art,
        ),
      ),
    );
  }

  Widget _art(BuildContext context, WidgetRef ref, ColorScheme scheme) {
    final id = mediaId;
    if (id != null) {
      final artwork = ref.watch(trackArtworkProvider(id));
      if (artwork.hasValue) {
        final bytes = artwork.value;
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(scheme),
          );
        }
      }
      return _fallback(scheme);
    }

    final uri = artUri;
    if (uri != null) {
      if (uri.isScheme('file')) {
        return Image.file(
          File.fromUri(uri),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(scheme),
        );
      }
      return Image.network(
        uri.toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(scheme),
      );
    }
    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.35,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Small non-semantic artwork thumbnail for list rows (the row's own semantics
/// label covers it, so no duplicate image node is exposed).
class ArtworkThumb extends ConsumerWidget {
  const ArtworkThumb({
    super.key,
    this.mediaId,
    this.size = 44,
  });

  final int? mediaId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final Widget child;
    final id = mediaId;
    if (id != null) {
      final artwork = ref.watch(trackArtworkProvider(id));
      if (artwork.hasValue) {
        final bytes = artwork.value;
        if (bytes is Uint8List && bytes.isNotEmpty) {
          child = Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _thumbFallback(scheme),
          );
        } else {
          child = _thumbFallback(scheme);
        }
      } else {
        child = _thumbFallback(scheme);
      }
    } else {
      child = _thumbFallback(scheme);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(dimension: size, child: child),
    );
  }

  Widget _thumbFallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.55,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
