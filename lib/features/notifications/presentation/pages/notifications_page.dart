import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../activities/presentation/pages/activities_page.dart';
import '../../../activities/presentation/pages/activity_execution_page.dart';
import '../../../issues/presentation/pages/issues_page.dart';
import '../../../sites/presentation/pages/all_sites_page.dart';
import '../../../sites/presentation/pages/site_detail_page.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/models/notification_item_model.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../widgets/notification_card_item.dart';

const _kBlue = Color(0xFF2563EB);
const _kSlate = Color(0xFF64748B);

class NotificationsPage extends StatelessWidget {
  final NotificationsBloc? bloc;

  const NotificationsPage({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!..add(const LoadNotifications()),
        child: const _NotificationsView(),
      );
    }

    return BlocProvider(
      create: (_) => NotificationsBloc(
        dataSource: NotificationsRemoteDataSourceImpl(),
      )..add(const LoadNotifications()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      context.read<NotificationsBloc>().add(const LoadMoreNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            final unread = (state is NotificationsLoaded) ? state.unreadCount : 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Notifications',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '$unread unread',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<NotificationsBloc>().add(const MarkAllNotificationsAsRead());
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.done_all_rounded, size: 15, color: _kBlue),
                  label: Text(
                    'Mark all read',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.actionMessage!,
                  style: GoogleFonts.outfit(),
                ),
                backgroundColor: _kBlue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _kBlue),
            );
          }

          if (state is NotificationsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is NotificationsLoaded) {
            return Column(
              children: [
                // Filter Tabs Bar
                _buildFilterTabsBar(context, state),

                // Notifications List
                Expanded(
                  child: RefreshIndicator(
                    color: _kBlue,
                    onRefresh: () async {
                      context.read<NotificationsBloc>().add(
                            const LoadNotifications(refresh: true),
                          );
                    },
                    child: state.filteredItems.isEmpty
                        ? _buildEmptyState(context, state.activeFilter)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.filteredItems.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.filteredItems.length) {
                                return _buildLoadMoreIndicator(context, state);
                              }

                              final item = state.filteredItems[index];
                              return NotificationCardItem(
                                key: ValueKey(item.id),
                                item: item,
                                onTap: () => _handleNotificationTap(context, item),
                                onMarkAsRead: () {
                                  context.read<NotificationsBloc>().add(
                                        MarkNotificationAsRead(item.id),
                                      );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFilterTabsBar(BuildContext context, NotificationsLoaded state) {
    final filters = [
      ('ALL', 'All', state.allItems.length),
      ('UNREAD', 'Unread', state.unreadCategoryCount),
      ('GOVERNANCE', 'Governance', state.governanceCount),
      ('ISSUE', 'Issues', state.issuesCount),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final isSelected = state.activeFilter.toUpperCase() == f.$1;
            final isUnreadTab = f.$1 == 'UNREAD';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<NotificationsBloc>().add(
                          ChangeNotificationFilter(f.$1),
                        );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isUnreadTab ? const Color(0xFFEFF6FF) : const Color(0xFF0F172A))
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isUnreadTab ? _kBlue : const Color(0xFF0F172A))
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          f.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isUnreadTab ? _kBlue : Colors.white)
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (f.$3 > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isUnreadTab
                                      ? _kBlue
                                      : Colors.white.withValues(alpha: 0.2))
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${f.$3}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? (isUnreadTab ? Colors.white : Colors.white)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context, NotificationsLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _kBlue),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            context.read<NotificationsBloc>().add(const LoadMoreNotifications());
          },
          icon: const Icon(Icons.arrow_downward_rounded, size: 16, color: _kBlue),
          label: Text(
            'Load More (${state.allItems.length} loaded)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    final isUnreadFilter = filter.toUpperCase() == 'UNREAD';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 36,
                    color: _kBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isUnreadFilter ? 'All caught up!' : 'No notifications found',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isUnreadFilter
                      ? 'You have read all pending notifications and alerts.'
                      : 'New governance activities, TAT alerts, and assignments will appear here.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _kSlate,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isUnreadFilter) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<NotificationsBloc>().add(
                            const ChangeNotificationFilter('ALL'),
                          );
                    },
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: Text(
                      'View all notifications',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load notifications',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.outfit(fontSize: 12.5, color: _kSlate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationsBloc>().add(
                      const LoadNotifications(refresh: true),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
              label: Text(
                'Try Again',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationItemModel item) {
    // 1. Mark as read on tap if currently unread
    if (item.unread) {
      context.read<NotificationsBloc>().add(
            MarkNotificationAsRead(item.id),
          );
    }

    // 2. Resolve activity target from activityId or href
    String? activityId = (item.activityId != null && item.activityId!.trim().isNotEmpty)
        ? item.activityId!.trim()
        : null;

    if (activityId == null && item.href != null) {
      final actMatch = RegExp(r'/activit(?:ies|y)/([a-zA-Z0-9_-]+)').firstMatch(item.href!);
      if (actMatch != null) {
        activityId = actMatch.group(1);
      }
    }

    // 3. Resolve site target from siteId or href
    String? siteId = (item.siteId != null && item.siteId!.trim().isNotEmpty)
        ? item.siteId!.trim()
        : null;

    if (siteId == null && item.href != null) {
      final siteMatch = RegExp(r'/sites/([a-zA-Z0-9_-]+)').firstMatch(item.href!);
      if (siteMatch != null) {
        siteId = siteMatch.group(1);
      }
    }

    // Target 1: Specific Activity Detail / Execution Page
    if (activityId != null && activityId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityExecutionPage(
            activityId: activityId!,
            siteName: item.message.isNotEmpty ? item.message : null,
          ),
        ),
      );
      return;
    }

    // Target 2: Specific Site Detail Page
    if (siteId != null && siteId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SiteDetailPage(siteId: siteId!),
        ),
      );
      return;
    }

    final cat = item.category.trim().toLowerCase();
    final type = item.type.trim().toLowerCase();
    final title = item.title.trim().toLowerCase();
    final href = (item.href ?? '').toLowerCase();

    // Target 3: Governance / Activity fallback
    if (cat == 'governance' ||
        type == 'assignment' ||
        type == 'governance' ||
        title.contains('activity') ||
        title.contains('governance') ||
        href.contains('activities')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActivitiesPage(isTeam: false),
        ),
      );
      return;
    }

    // Target 4: Site allocation / mapping fallback
    if (cat == 'site' ||
        type == 'site' ||
        type == 'mapping' ||
        title.contains('site') ||
        title.contains('mapped') ||
        href.contains('sites')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AllSitesPage(),
        ),
      );
      return;
    }

    // Target 5: Issues / TAT alert fallback
    if (cat == 'issue' ||
        type == 'tat' ||
        type == 'issue' ||
        title.contains('issue') ||
        title.contains('tat') ||
        href.contains('issues')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const IssuesPage(),
        ),
      );
      return;
    }
  }
}
