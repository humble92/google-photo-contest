import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:humble_photo_contest/data/models/photo.dart';
import 'package:humble_photo_contest/presentation/common_widgets/pass_key_dialog.dart';
import 'package:humble_photo_contest/presentation/providers/auth_provider.dart';
import 'package:humble_photo_contest/presentation/providers/contest_provider.dart';
import 'package:humble_photo_contest/presentation/providers/photo_provider.dart';
import 'package:humble_photo_contest/presentation/providers/vote_provider.dart';
import 'package:humble_photo_contest/presentation/screens/create_contest/edit_contest_screen.dart';
import 'package:image_picker/image_picker.dart';

class ContestDetailScreen extends ConsumerStatefulWidget {
  final Contest contest;

  const ContestDetailScreen({super.key, required this.contest});

  @override
  ConsumerState<ContestDetailScreen> createState() =>
      _ContestDetailScreenState();
}

class _ContestDetailScreenState extends ConsumerState<ContestDetailScreen> {
  Future<List<Photo>>? _photosFuture; // Make nullable
  Set<String> _votedPhotoIds = {};
  Map<String, int> _voteCounts = {};
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndInitialize();
  }

  Future<void> _checkAccessAndInitialize() async {
    // Check if this is a private contest and user is not the host
    final user = ref.read(currentUserProvider);
    final isHost = user?.id == widget.contest.hostUserId;

    if (widget.contest.isPrivate && !isHost) {
      // Show pass key dialog after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final passKey = await showPassKeyDialog(
          context: context,
          onVerify: (inputKey) async {
            // Verify pass key
            return await ref
                .read(contestRepositoryProvider)
                .verifyPassKey(widget.contest.id, inputKey);
          },
          contestTitle: widget.contest.title,
        );

        if (passKey == null) {
          // User cancelled, go back
          if (mounted) {
            context.pop();
          }
        } else {
          // Access granted - initialize data
          _initializeData();
        }
      });
    } else {
      // Public contest or user is host - grant immediate access
      _initializeData();
    }
  }

  void _initializeData() {
    _refreshPhotos();
    _fetchMyVotes();
    // Always fetch vote counts if contest has ended or if show_vote_counts is enabled
    if (widget.contest.showVoteCounts ||
        widget.contest.status == ContestStatus.ended) {
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
    print('📥 _fetchMyVotes called');
    final user = ref.read(currentUserProvider);
    print('📥 Current user: ${user?.id}');
    if (user != null) {
      final votes = await ref
          .read(voteRepositoryProvider)
          .getMyVotes(user.id, widget.contest.id);
      print('📥 Received votes: $votes');
      if (mounted) {
        setState(() {
          _votedPhotoIds = votes;
          print('✅ _votedPhotoIds updated: $_votedPhotoIds');
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

      // Read image as bytes (works on both web and mobile)
      final bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().toIso8601String()}_${user.id}.jpg';

      await ref
          .read(photoRepositoryProvider)
          .uploadPhotoFromBytes(
            contestId: widget.contest.id,
            userId: user.id,
            bytes: bytes,
            fileName: fileName,
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

  Future<void> _deleteContest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contest'),
        content: const Text(
          'Are you sure you want to delete this contest? '
          'This will permanently delete all photos and votes associated with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(contestRepositoryProvider)
          .deleteContest(widget.contest.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contest deleted successfully')),
        );
        context.go('/'); // Navigate back to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete contest: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isHost = user?.id == widget.contest.hostUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contest.title),
        actions: isHost
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            EditContestScreen(contest: widget.contest),
                      ),
                    );
                    // Refresh after editing
                    _refreshPhotos();
                  },
                  tooltip: 'Edit Contest',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteContest,
                  tooltip: 'Delete Contest',
                ),
              ]
            : null,
      ),
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
      body: _photosFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Photo>>(
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

                // Sort photos by vote count if contest has ended
                final sortedPhotos =
                    widget.contest.status == ContestStatus.ended
                    ? (photos.toList()..sort((a, b) {
                        final aVotes = _voteCounts[a.id] ?? 0;
                        final bVotes = _voteCounts[b.id] ?? 0;
                        return bVotes.compareTo(aVotes); // Descending order
                      }))
                    : photos;

                // Calculate rankings with tie handling
                Map<String, int> photoRanks = {};
                if (widget.contest.status == ContestStatus.ended) {
                  int currentRank = 1;
                  int? previousVoteCount;

                  for (int i = 0; i < sortedPhotos.length; i++) {
                    final photo = sortedPhotos[i];
                    final voteCount = _voteCounts[photo.id] ?? 0;

                    // If this is not the first photo and vote count is different, update rank
                    if (previousVoteCount != null &&
                        voteCount != previousVoteCount) {
                      currentRank = i + 1; // Jump to current position
                    }

                    photoRanks[photo.id] = currentRank;
                    previousVoteCount = voteCount;
                  }
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: sortedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = sortedPhotos[index];
                    final isVoted = _votedPhotoIds.contains(photo.id);
                    final voteCount = _voteCounts[photo.id] ?? 0;
                    final photoUrl = ref
                        .read(photoRepositoryProvider)
                        .getPhotoUrl(photo.storagePath);

                    // Determine ranking for ended contests
                    final isEnded =
                        widget.contest.status == ContestStatus.ended;
                    final rank = isEnded ? photoRanks[photo.id] : null;
                    final showRank = isEnded && rank != null && rank <= 3;

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
                        // Ranking badge for top 3
                        if (showRank)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: rank == 1
                                    ? Colors.amber
                                    : rank == 2
                                    ? Colors.grey[400]
                                    : Colors.brown[300],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    rank == 1
                                        ? Icons.emoji_events
                                        : rank == 2
                                        ? Icons.emoji_events_outlined
                                        : Icons.workspace_premium,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rank == 1
                                        ? '1st'
                                        : rank == 2
                                        ? '2nd'
                                        : '3rd',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                  Colors.black.withValues(alpha: 0.7),
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
                              if (widget.contest.showVoteCounts || isEnded)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$voteCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              // Only show vote button if contest is active
                              if (widget.contest.status == ContestStatus.active)
                                IconButton(
                                  icon: Icon(
                                    isVoted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isVoted ? Colors.red : Colors.white,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final user = ref.read(
                                        currentUserProvider,
                                      );
                                      if (user == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please login to vote',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (isVoted) {
                                        // Remove vote (unvote)
                                        print(
                                          '🔴 Removing vote for photo: ${photo.id}',
                                        );
                                        await ref
                                            .read(voteRepositoryProvider)
                                            .removeVote(
                                              userId: user.id,
                                              photoId: photo.id,
                                            );
                                        print('✅ Vote removed from DB');

                                        // Refresh data from database
                                        await _fetchMyVotes();
                                        if (widget.contest.showVoteCounts) {
                                          await _fetchVoteCounts();
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Vote removed!'),
                                            ),
                                          );
                                        }
                                      } else {
                                        // Cast vote
                                        print(
                                          '🟢 Casting vote for photo: ${photo.id}',
                                        );
                                        await ref
                                            .read(voteRepositoryProvider)
                                            .castVote(
                                              userId: user.id,
                                              contestId: widget.contest.id,
                                              photoId: photo.id,
                                            );
                                        print('✅ Vote cast to DB');

                                        // Refresh data from database
                                        await _fetchMyVotes();
                                        if (widget.contest.showVoteCounts) {
                                          await _fetchVoteCounts();
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Vote cast!'),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      print('❌ Vote error: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to vote: $e'),
                                          ),
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
