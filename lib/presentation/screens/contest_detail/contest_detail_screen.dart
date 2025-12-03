import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:humble_photo_contest/data/models/photo.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';
import 'package:humble_photo_contest/presentation/providers/photo_provider.dart';
import 'package:humble_photo_contest/presentation/providers/vote_provider.dart';
import 'package:image_picker/image_picker.dart';

class ContestDetailScreen extends ConsumerStatefulWidget {
  final Contest contest;

  const ContestDetailScreen({super.key, required this.contest});

  @override
  ConsumerState<ContestDetailScreen> createState() =>
      _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  late Future<List<Photo>> _photosFuture;
  Set<String> _votedPhotoIds = {};
  Map<String, int> _voteCounts = {};
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _refreshPhotos();
    _fetchMyVotes();
    if (widget.contest.showVoteCounts) {
      _fetchVoteCounts();
    }
  }

  void _refreshPhotos() {
    setState(() {
      _photosFuture = ref
          .read(photoRepositoryProvider)
          .getPhotos(widget.contest.id);
    });
  }

  Future<void> _fetchMyVotes() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final votes = await ref
          .read(voteRepositoryProvider)
          .getMyVotes(user.id, widget.contest.id);
      if (mounted) {
        setState(() {
          _votedPhotoIds = votes;
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

  Future<void> _pickAndUploadPhoto() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to upload photos')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      await ref
          .read(photoRepositoryProvider)
          .uploadPhoto(
            contestId: widget.contest.id,
            userId: user.id,
            file: File(image.path),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
        _refreshPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contest.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadPhoto,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_a_photo),
        label: Text(_isUploading ? 'Uploading...' : 'Submit Photo'),
      ),
      body: FutureBuilder<List<Photo>>(
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('No photos yet. Be the first to submit!'),
                ],
              ),
            );
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
              final isVoted = _votedPhotoIds.contains(photo.id);
              final voteCount = _voteCounts[photo.id] ?? 0;
              final photoUrl = ref
                  .read(photoRepositoryProvider)
                  .getPhotoUrl(photo.storagePath);

              return Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: photoUrl,
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
                                    photoId: photo.id,
                                  );

                              setState(() {
                                _votedPhotoIds.add(photo.id);
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
