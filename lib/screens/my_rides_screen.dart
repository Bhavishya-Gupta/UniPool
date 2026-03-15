import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/screens/chat_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AppGradientBackground(
          useSafeArea: false,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppPageHeader(
                  title: 'My rides',
                  subtitle: 'Rides you lead and rides you joined.',
                  leading: _TopBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  badge: const AppPill(
                    label: 'My activity',
                    icon: Icons.route_rounded,
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0x33FFFFFF),
                  ),
                  bottom: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1629),
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Color(0xFFB3C0DB),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      indicator: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_taxi_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('I am leading'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('I joined'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      RideList(isLeader: true),
                      RideList(isLeader: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RideList extends StatelessWidget {
  const RideList({super.key, required this.isLeader});

  final bool isLeader;

  Future<void> _completeRide(
    BuildContext context,
    String rideId,
    String leaderId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'status': 'completed',
      });

      await FirebaseFirestore.instance.collection('users').doc(leaderId).update(
        {'ridesCompleted': FieldValue.increment(1)},
      );

      if (context.mounted) {
        showAppSnackBar(context, 'Ride marked as completed.', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Unable to complete ride: $e', isError: true);
      }
    }
  }

  Future<void> _deleteRide(BuildContext context, String rideId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete ride?'),
          content: const Text(
            'This will cancel the ride and remove it for everyone. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).delete();
      if (context.mounted) {
        showAppSnackBar(context, 'Ride deleted successfully.', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Error deleting ride: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    final query = isLeader
        ? FirebaseFirestore.instance
              .collection('rides')
              .where('leaderId', isEqualTo: user.uid)
        : FirebaseFirestore.instance
              .collection('rides')
              .where('participants', arrayContains: user.uid);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) => _rideDate(b).compareTo(_rideDate(a)));

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AppEmptyState(
              icon: isLeader
                  ? Icons.local_taxi_rounded
                  : Icons.travel_explore_rounded,
              title: isLeader ? 'No rides posted yet' : 'No joined rides yet',
              subtitle: isLeader
                  ? 'Create a ride from the home screen.'
                  : 'Join a ride to see it here.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ride = docs[index];
            final status = (ride['status'] ?? 'open').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIconBadge(
                          icon: isLeader
                              ? Icons.local_taxi_rounded
                              : Icons.group_outlined,
                          color: isLeader
                              ? AppColors.primary
                              : AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ride['source']} to ${ride['destination']}',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEE, d MMM yyyy',
                                ).format(_rideDate(ride)),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppPill(
                          label: status.toUpperCase(),
                          foregroundColor: _statusColor(status),
                          backgroundColor: _statusColor(
                            status,
                          ).withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppPill(
                          label: isLeader ? 'You are leading' : 'Joined ride',
                          icon: isLeader
                              ? Icons.workspace_premium_outlined
                              : Icons.verified_user_outlined,
                        ),
                        AppPill(
                          label: ride['leaderName'] ?? 'Student',
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  rideId: ride.id,
                                  rideDestination: ride['destination'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Open chat'),
                        ),
                        if (isLeader && status == 'open')
                          FilledButton.icon(
                            onPressed: () =>
                                _completeRide(context, ride.id, user.uid),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('Mark complete'),
                          ),
                        if (isLeader)
                          OutlinedButton.icon(
                            onPressed: () => _deleteRide(context, ride.id),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime _rideDate(DocumentSnapshot ride) {
    return DateTime.tryParse(ride['rideDate'].toString()) ?? DateTime.now();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.secondary;
      case 'open':
        return AppColors.success;
      default:
        return AppColors.muted;
    }
  }
}

class _TopBackButton extends StatelessWidget {
  const _TopBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
