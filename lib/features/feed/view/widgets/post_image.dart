import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/reddit_post.dart';

class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context) {
    if (!post.hasThumbnail) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: post.thumbnail,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
