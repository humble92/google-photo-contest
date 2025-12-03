import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:humble_photo_contest/data/models/google_media_item.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';
import 'package:humble_photo_contest/presentation/providers/google_photos_provider.dart';
import 'package:humble_photo_contest/presentation/providers/vote_provider.dart';

class ContestDetailScreen extends ConsumerStatefulWidget {
  final Contest contest;

  const ContestDetailScreen({super.key, required this.contest});

  @override
  ConsumerState<ContestDetailScreen> createState() =>
      _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  late Future<List<GoogleMediaItem>> _photosFuture;
  Set<String> _votedMediaItemIds = {};
  Map<String, int> _voteCounts = {};

  @override
  void initState() {
    super.initState();
    _photosFuture = ref
        .read(googlePhotosServiceProvider)
        .getMediaItems(widget.contest.googleAlbumId);
    _fetchMyVotes();
    if (widget.contest.showVoteCounts) {
      _fetchVoteCounts();
    }
  }

  Future<void> _fetchMyVotes() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final votes = await ref
          .read(voteRepositoryProvider)
          .getMyVotes(user.id, widget.contest.id);
      if (mounted) {
        setState(() {
          _votedMediaItemIds = votes;
        });
      }
    }
  }

  Future<void> _fetchVoteCounts() async {
    final counts = await ref
        .read(voteRepositoryProvider)
        .getVoteCounts(widget.contest.id);
    if (mounted) {
      setState(() {
        _voteCounts = counts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contest.title)),
      body: FutureBuilder<List<GoogleMediaItem>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return const Center(child: Text('No photos found in this album.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final isVoted = _votedMediaItemIds.contains(photo.id);
              final voteCount = _voteCounts[photo.id] ?? 0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: '${photo.baseUrl}=w500-h500-c',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[300]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.contest.showVoteCounts)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '$voteCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            isVoted ? Icons.favorite : Icons.favorite_border,
                            color: isVoted ? Colors.red : Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              final user = ref.read(currentUserProvider);
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to vote'),
                                  ),
                                );
                                return;
                              }

                              if (isVoted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You have already voted for this photo',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await ref
                                  .read(voteRepositoryProvider)
                                  .castVote(
                                    userId: user.id,
                                    contestId: widget.contest.id,
                                    googleMediaItemId: photo.id,
                                    metaData: {
                                      'filename': photo.filename,
                                      'mimeType': photo.mimeType,
                                      'baseUrl': photo.baseUrl,
                                    },
                                  );

                              setState(() {
                                _votedMediaItemIds.add(photo.id);
                                if (widget.contest.showVoteCounts) {
                                  _voteCounts[photo.id] =
                                      (_voteCounts[photo.id] ?? 0) + 1;
                                }
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vote cast!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to vote: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
