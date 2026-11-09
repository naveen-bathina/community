import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_unity_network/features/profile/presentation/providers/profile_provider.dart';
import 'package:legal_unity_network/shared/models/user_model.dart';
import 'package:legal_unity_network/shared/widgets/app_top_bar_actions.dart';

class DirectoryScreen extends ConsumerWidget {
  const DirectoryScreen({super.key});

  static const List<String> practiceAreas = [
    'Family Law',
    'Corporate Law',
    'Criminal Defense',
    'Civil Litigation',
    'Property Law',
    'Tax Law',
    'Constitutional Law',
    'Mediation',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(directoryFilterProvider);
    final membersAsync = ref.watch(directoryMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advocate Directory'),
        actions: const [
          AppTopBarActions(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('directory_search_field'),
              decoration: const InputDecoration(
                hintText: 'Search by name, city, state, or firm...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(directoryFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: value);
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      'All Areas',
                      style: TextStyle(
                        color: filter.practiceArea == null
                            ? Colors.white
                            : const Color(0xFF0D3B66),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: filter.practiceArea == null,
                    onSelected: (_) {
                      ref.read(directoryFilterProvider.notifier).state =
                          filter.copyWith(clearPracticeArea: true);
                    },
                  ),
                ),
                ...practiceAreas.map((area) {
                  final isSelected = filter.practiceArea == area;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        area,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0D3B66),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(directoryFilterProvider.notifier).state =
                            filter.copyWith(
                          practiceArea: selected ? area : null,
                          clearPracticeArea: !selected,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (members) {
                if (members.isEmpty) {
                  return const Center(
                    child: Text('No approved members match your filters.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final location = [member.city, member.state]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(', ');

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(member.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (member.firmOrganization != null &&
                                member.firmOrganization!.isNotEmpty)
                              Text(member.firmOrganization!),
                            if (location.isNotEmpty) Text(location),
                            if (member.practiceAreas != null &&
                                member.practiceAreas!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 6,
                                  children: member.practiceAreas!
                                      .map(
                                        (area) => Chip(
                                          label: Text(area),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            if (member.availabilityStatus != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  member.availabilityStatus!.displayName,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  MemberProfileDetailScreen(member: member),
                            ),
                          );
                        },
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

class MemberProfileDetailScreen extends StatelessWidget {
  final UserModel member;

  const MemberProfileDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final location = [member.city, member.state]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        actions: const [
          AppTopBarActions(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 44,
              child: Icon(Icons.person, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            member.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (member.firmOrganization != null)
            Text(
              member.firmOrganization!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          if (location.isNotEmpty)
            Text(
              location,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          if (member.bio != null && member.bio!.isNotEmpty) ...[
            Text('About', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(member.bio!),
            const SizedBox(height: 16),
          ],
          if (member.practiceAreas != null &&
              member.practiceAreas!.isNotEmpty) ...[
            Text(
              'Practice Areas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: member.practiceAreas!
                  .map((a) => Chip(label: Text(a)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
