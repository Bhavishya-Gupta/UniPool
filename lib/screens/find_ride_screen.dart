import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unipool/data/ride_locations.dart';
import 'package:unipool/screens/chat_screen.dart';
import 'package:unipool/theme/app_theme.dart';
import 'package:unipool/widgets/app_ui.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  String _filterDestination = allLocationsLabel;

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'open');

    if (_filterDestination != allLocationsLabel) {
      query = query.where('destination', isEqualTo: _filterDestination);
    }

    return Scaffold(
      body: AppGradientBackground(
        useSafeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Find a ride',
                subtitle: 'Browse open rides by destination.',
                leading: _TopBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                badge: const AppPill(
                  label: 'Pooler mode',
                  icon: Icons.travel_explore_rounded,
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: AppSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination filter',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Narrow the list when you already know where you want to go.',
                              style: TextStyle(
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _filterDestination,
                              decoration: const InputDecoration(
                                labelText: 'Destination',
                                prefixIcon: Icon(
                                  Icons.filter_list_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              items: [allLocationsLabel, ...rideLocations]
                                  .map(
                                    (location) => DropdownMenuItem<String>(
                                      value: location,
                                      child: Text(
                                        location,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _filterDestination = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: query.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No rides found',
                              subtitle: _filterDestination == allLocationsLabel
                                  ? 'There are no open rides right now.'
                                  : 'Try another destination or switch back to all locations.',
                            );
                          }

                          final rideDocs = snapshot.data!.docs.toList()
                            ..sort(
                              (a, b) => _rideDate(b).compareTo(_rideDate(a)),
                            );

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: rideDocs.length,
                            itemBuilder: (context, index) {
                              final ride = rideDocs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _RideCard(
                                  ride: ride,
                                  onTap: () => _showRideDetails(context, ride),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRideDetails(
    BuildContext context,
    DocumentSnapshot ride,
  ) async {
    final leaderData = await FirebaseFirestore.instance
        .collection('users')
        .doc(ride['leaderId'])
        .get();
    final leaderMap = leaderData.data();
    final ridesCount = leaderMap?['ridesCompleted'] ?? 0;

    if (!context.mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppSurfaceCard(
              radius: 30,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppIconBadge(
                        icon: Icons.directions_car_filled_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ride details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    label: 'From',
                    value: ride['source'],
                    color: AppColors.primary,
                    icon: Icons.my_location_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'To',
                    value: ride['destination'],
                    color: AppColors.accent,
                    icon: Icons.place_rounded,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat(
                      'EEEE, d MMM yyyy',
                    ).format(_rideDate(ride)),
                    color: AppColors.secondary,
                    icon: Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 18),
                  AppSurfaceCard(
                    color: AppColors.surfaceSoft,
                    radius: 24,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            ride['leaderName'].toString().isNotEmpty
                                ? ride['leaderName'].toString()[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride['leaderName'],
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$ridesCount rides completed',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const AppPill(
                          label: 'Open',
                          foregroundColor: AppColors.success,
                          backgroundColor: Color(0xFFE7F7EC),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          label: 'Join and chat',
                          icon: Icons.chat_rounded,
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  rideId: ride.id,
                                  rideDestination: ride['destination'],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _rideDate(DocumentSnapshot ride) {
    final rawDate = ride['rideDate'];
    return DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
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

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.onTap});

  final DocumentSnapshot ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.tryParse(ride['rideDate'].toString()) ?? DateTime.now();

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIconBadge(
                    icon: Icons.local_taxi_rounded,
                    color: AppColors.primary,
                  ),
                  const Spacer(),
                  const AppPill(
                    label: 'Open',
                    foregroundColor: AppColors.success,
                    backgroundColor: Color(0xFFE7F7EC),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${ride['source']} to ${ride['destination']}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppPill(
                    label: ride['leaderName'],
                    icon: Icons.person_outline_rounded,
                  ),
                  AppPill(
                    label: DateFormat('d MMM').format(date),
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Text(
                    'Tap to review the ride and open chat',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconBadge(icon: icon, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
