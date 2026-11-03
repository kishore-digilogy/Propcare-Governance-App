import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/meta_service.dart';
import '../../../../core/widgets/custom_dropdown_button2.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../../data/models/activity_site_summary_model.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../bloc/activities_state.dart';
import '../widgets/activity_execution_view.dart';
import '../widgets/site_activities_detail_view.dart';

class ActivitiesPage extends StatefulWidget {
  final bool isTeam;
  final ActivitiesBloc? bloc;

  const ActivitiesPage({
    super.key,
    required this.isTeam,
    this.bloc,
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late final ActivitiesBloc _bloc;
  late final TextEditingController _searchController;
  final bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ??
        ActivitiesBloc(
          remoteDataSource: ActivitiesRemoteDataSourceImpl(),
        );
    _searchController = TextEditingController();

    _bloc.add(LoadActivitiesBySite(
      view: widget.isTeam ? 'below' : 'mine',
    ));
  }

  @override
  void didUpdateWidget(covariant ActivitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTeam != widget.isTeam) {
      _bloc.add(LoadActivitiesBySite(
        view: widget.isTeam ? 'below' : 'mine',
      ));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BlocConsumer<ActivitiesBloc, ActivitiesState>(
          listener: (context, state) {
            if (state is ActivitiesLoaded) {
              if (state.actionSuccessMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionSuccessMessage!),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state.actionErrorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.actionErrorMessage!),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is ActivitiesLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is ActivitiesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load activities',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _bloc.add(LoadActivitiesBySite(
                            view: widget.isTeam ? 'below' : 'mine',
                            isRefresh: true,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ActivitiesLoaded) {
              // 1. If an individual activity is selected for detail/execution
              if (state.selectedActivityDetail != null || state.isLoadingActivity) {
                if (state.isLoadingActivity) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                return ActivityExecutionView(
                  activityDetail: state.selectedActivityDetail!,
                  isSubmittingVisit: state.isSubmittingVisit,
                  isSendingMom: state.isSendingMom,
                  bloc: _bloc,
                  onBack: () {
                    _bloc.add(const CloseActivityDetail());
                  },
                );
              }

              // 2. If a site is selected, show detail view
              if (state.selectedSite != null) {
                return SiteActivitiesDetailView(
                  site: state.selectedSite!,
                  response: state.selectedSiteActivities,
                  isLoading: state.isLoadingDetail,
                  myRoleLabel: state.response.myRoleLabel,
                  bloc: _bloc,
                  onBack: () {
                    _bloc.add(const CloseSiteActivitiesDetail());
                  },
                );
              }

              // Otherwise show Main Summary & Sites list
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  return RefreshIndicator(
                    onRefresh: () async {
                      _bloc.add(LoadActivitiesBySite(
                        view: widget.isTeam ? 'below' : 'mine',
                        isRefresh: true,
                      ));
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 12 : 20,
                        vertical: isNarrow ? 14 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(state),
                          const SizedBox(height: 14),
                          _buildTopMetricCards(state),
                          const SizedBox(height: 16),
                          _buildFiltersBar(context, state),
                          if (widget.isTeam && state.response.belowRoles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildRoleFilterChips(state),
                          ],
                          const SizedBox(height: 20),
                          _buildSitesSectionHeader(state),
                          const SizedBox(height: 12),
                          _buildSitesList(state),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ActivitiesLoaded state) {
    final title = widget.isTeam ? 'Team Activities' : 'My Activities';
    final subtitle = widget.isTeam
        ? 'Team Governance By Site'
        : '${state.response.myRoleLabel} · Governance By Site';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMetricCards(ActivitiesLoaded state) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        // Mobile compact 3-metric container
        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCompactTopMetric(
                    title: 'Total',
                    value: '${state.response.total}',
                    subtitle: '${state.response.items.length} Sites',
                    icon: Icons.apartment_outlined,
                    iconColor: const Color(0xFF64748B),
                    valueColor: const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _buildCompactTopMetric(
                    title: 'Completed',
                    value: '${state.response.completed}',
                    subtitle: 'Closed',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF16A34A),
                    valueColor: const Color(0xFF16A34A),
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFFE2E8F0),
                ),
                Expanded(
                  child: _buildCompactTopMetric(
                    title: 'Pending',
                    value: '${state.response.pending}',
                    subtitle: 'Open / MOM',
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xFFD97706),
                    valueColor: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          );
        }

        final card1 = _buildTopMetricCard(
          title: 'Total Governance Activity',
          value: '${state.response.total}',
          subtitle: '${state.response.items.length} Sites',
          icon: Icons.apartment_outlined,
          iconColor: const Color(0xFF64748B),
          valueColor: const Color(0xFF0F172A),
        );

        final card2 = _buildTopMetricCard(
          title: 'Completed Governance Activity',
          value: '${state.response.completed}',
          subtitle: 'Closed · MOM Sent When Required',
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          valueColor: const Color(0xFF16A34A),
        );

        final card3 = _buildTopMetricCard(
          title: 'Pending Governance Activity',
          value: '${state.response.pending}',
          subtitle: 'Open / MOM Pending',
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFD97706),
          valueColor: const Color(0xFFD97706),
        );

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 14),
            Expanded(child: card2),
            const SizedBox(width: 14),
            Expanded(child: card3),
          ],
        );
      },
    );
  }

  Widget _buildCompactTopMetric({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTopMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context, ActivitiesLoaded state) {
    final meta = MetaService.instance.meta;

    // Build zone options
    final zoneOptions = <DropdownItemOption<String?>>[
      const DropdownItemOption(value: null, label: 'Zone'),
    ];
    if (meta.zones.isNotEmpty) {
      zoneOptions.addAll(meta.zones.map((z) => DropdownItemOption(value: z.id, label: z.name)));
    } else {
      final distinctZones = <String, String>{};
      for (final s in state.response.items) {
        if (s.zoneId != null && s.zoneName.isNotEmpty) {
          distinctZones[s.zoneId!] = s.zoneName;
        }
      }
      zoneOptions.addAll(distinctZones.entries.map((e) => DropdownItemOption(value: e.key, label: e.value)));
    }

    // Build cluster options
    final clusterOptions = <DropdownItemOption<String?>>[
      const DropdownItemOption(value: null, label: 'Cluster'),
    ];
    if (meta.clusters.isNotEmpty) {
      clusterOptions.addAll(
        meta
            .clustersForZone(state.selectedZoneId)
            .map((c) => DropdownItemOption(value: c.id, label: c.name)),
      );
    } else {
      final distinctClusters = <String, String>{};
      for (final s in state.response.items) {
        if (s.clusterId != null && s.clusterName.isNotEmpty) {
          if (state.selectedZoneId == null || s.zoneId == state.selectedZoneId) {
            distinctClusters[s.clusterId!] = s.clusterName;
          }
        }
      }
      clusterOptions.addAll(distinctClusters.entries.map((e) => DropdownItemOption(value: e.key, label: e.value)));
    }

    // Status options
    final statusOptions = const <DropdownItemOption<String?>>[
      DropdownItemOption(value: null, label: 'All statuses'),
      DropdownItemOption(value: 'LIVE', label: 'Live'),
      DropdownItemOption(value: 'INACTIVE', label: 'Inactive'),
      DropdownItemOption(value: 'PRE_TRANSITION', label: 'Pre-Transition'),
      DropdownItemOption(value: 'POST_TRANSITION', label: 'Post-Transition'),
      DropdownItemOption(value: 'DRAFT', label: 'Draft'),
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final searchField = Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              _bloc.add(SearchActivitiesQueryChanged(val));
            },
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search site, code, city...',
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        );

        final zoneDropdown = CustomDropdownButton2<String?>(
          selectedValue: state.selectedZoneId,
          options: zoneOptions,
          buttonHeight: 38,
          maxHeight: 260,
          enableSearch: true,
          onSelect: (val) {
            _bloc.add(ChangeActivitiesZoneFilter(val));
          },
        );

        final clusterDropdown = CustomDropdownButton2<String?>(
          selectedValue: state.selectedClusterId,
          options: clusterOptions,
          buttonHeight: 38,
          maxHeight: 260,
          enableSearch: true,
          onSelect: (val) {
            _bloc.add(ChangeActivitiesClusterFilter(val));
          },
        );

        final statusDropdown = CustomDropdownButton2<String?>(
          selectedValue: state.selectedStatus,
          options: statusOptions,
          buttonHeight: 38,
          maxHeight: 260,
          enableSearch: false,
          onSelect: (val) {
            _bloc.add(ChangeActivitiesStatusFilter(val));
          },
        );

        if (isMobile) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: zoneDropdown),
                  const SizedBox(width: 8),
                  Expanded(child: clusterDropdown),
                ],
              ),
              const SizedBox(height: 8),
              statusDropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: searchField),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: zoneDropdown),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: clusterDropdown),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: statusDropdown),
          ],
        );
      },
    );
  }

  Widget _buildRoleFilterChips(ActivitiesLoaded state) {
    final roles = state.response.belowRoles;
    final isAllSelected = state.selectedRole == null || state.selectedRole == 'ALL' || state.selectedRole!.isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          // "All" chip
          _buildRoleChip(
            label: 'All',
            isSelected: isAllSelected,
            isLoading: state.isLoadingDetail,
            onTap: () {
              if (state.isLoadingDetail) return;
              _bloc.add(const ChangeActivitiesRoleFilter(null));
            },
          ),
          const SizedBox(width: 8),
          ...roles.map((r) {
            final isSelected = state.selectedRole?.toUpperCase() == r.role.toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildRoleChip(
                label: r.label,
                isSelected: isSelected,
                isLoading: state.isLoadingDetail,
                onTap: () {
                  if (state.isLoadingDetail) return;
                  _bloc.add(ChangeActivitiesRoleFilter(isSelected ? null : r.role));
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required bool isSelected,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (isSelected && isLoading) ...[
              const SizedBox(width: 6),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSitesSectionHeader(ActivitiesLoaded state) {
    return Row(
      children: [
        const Icon(Icons.apartment_outlined, size: 20, color: Color(0xFF334155)),
        const SizedBox(width: 8),
        Text(
          'Sites',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${state.filteredSites.length}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        if (state.isLoadingDetail) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSitesList(ActivitiesLoaded state) {
    if (state.isLoadingDetail) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading activities...',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final sites = state.filteredSites;

    if (sites.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No sites found',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sites.map((site) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSiteCard(site),
        );
      }).toList(),
    );
  }

  Widget _buildSiteCard(ActivitySiteItemModel site) {
    final percent = site.completionPercent;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;

    if (percent == 100) {
      badgeBg = const Color(0xFFF0FDF4);
      badgeBorder = const Color(0xFFBBF7D0);
      badgeText = const Color(0xFF16A34A);
    } else if (percent >= 50) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFDE68A);
      badgeText = const Color(0xFFD97706);
    } else {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFECACA);
      badgeText = const Color(0xFFDC2626);
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final screenWidth = MediaQuery.sizeOf(ctx).width;
        final isNarrow = constraints.maxWidth < 768 || screenWidth < 768;

        final siteInfo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              site.siteName,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              site.subtitleDisplay,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final percentPill = Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeBorder),
          ),
          child: Text(
            '$percent%',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeText,
            ),
          ),
        );

        Widget metricsRow;
        if (isNarrow) {
          metricsRow = Row(
            children: [
              percentPill,
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Total',
                  value: '${site.total}',
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Completed',
                  value: '${site.completed}',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniMetric(
                  label: 'Pending',
                  value: '${site.pending}',
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          );
        } else {
          metricsRow = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              percentPill,
              const SizedBox(width: 14),
              _buildMiniMetric(
                label: 'Total',
                value: '${site.total}',
                color: const Color(0xFF0F172A),
                fixedWidth: 70,
              ),
              const SizedBox(width: 10),
              _buildMiniMetric(
                label: 'Completed',
                value: '${site.completed}',
                color: const Color(0xFF16A34A),
                fixedWidth: 75,
              ),
              const SizedBox(width: 10),
              _buildMiniMetric(
                label: 'Pending',
                value: '${site.pending}',
                color: const Color(0xFFD97706),
                fixedWidth: 65,
              ),
            ],
          );
        }

        return InkWell(
          onTap: () {
            _bloc.add(SelectSiteForActivities(site));
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isNarrow ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      siteInfo,
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      metricsRow,
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: siteInfo),
                      metricsRow,
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
    double? fixedWidth,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );

    if (fixedWidth != null) {
      return SizedBox(
        width: fixedWidth,
        child: content,
      );
    }
    return content;
  }
}
