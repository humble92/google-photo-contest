import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humble_photo_contest/data/models/google_album.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';
import 'package:humble_photo_contest/presentation/providers/contest_provider.dart';
import 'package:humble_photo_contest/presentation/providers/google_photos_provider.dart';

class CreateContestScreen extends ConsumerStatefulWidget {
  const CreateContestScreen({super.key});

  @override
  ConsumerState<CreateContestScreen> createState() =>
      _CreateContestScreenState();
}

class _CreateContestScreenState extends ConsumerState<CreateContestScreen> {
  late Future<List<GoogleAlbum>> _albumsFuture;
  bool _showVoteCounts = false;

  @override
  void initState() {
    super.initState();
    _albumsFuture = ref.read(googlePhotosServiceProvider).getAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Album')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Vote Counts'),
            subtitle: const Text(
              'If enabled, users can see the total number of likes for each photo.',
            ),
            value: _showVoteCounts,
            onChanged: (value) {
              setState(() {
                _showVoteCounts = value;
              });
            },
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<GoogleAlbum>>(
              future: _albumsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final albums = snapshot.data ?? [];

                if (albums.isEmpty) {
                  return const Center(child: Text('No albums found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final user = ref.read(currentUserProvider);
                            if (user == null)
                              throw Exception('User not logged in');

                            await ref
                                .read(contestRepositoryProvider)
                                .createContest(
                                  hostUserId: user.id,
                                  googleAlbumId: album.id,
                                  title: album.title,
                                  showVoteCounts: _showVoteCounts,
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contest created successfully!',
                                  ),
                                ),
                              );
                              context.go('/'); // Go back to home
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create contest: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: album.coverPhotoBaseUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          '${album.coverPhotoBaseUrl}=w500-h500-c',
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[300]),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.photo_album),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    album.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${album.mediaItemsCount} items',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
