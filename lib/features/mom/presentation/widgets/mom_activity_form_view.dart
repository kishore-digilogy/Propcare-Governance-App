import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/mom_activity_model.dart';
import '../../data/models/mom_by_site_model.dart';
import '../bloc/mom_bloc.dart';
import '../bloc/mom_event.dart';

const _kBlue = Color(0xFF1A73E8);
const _kSlate = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kAmber = Color(0xFFD97706);
const _kGreen = Color(0xFF16A34A);
const _kDarkText = Color(0xFF0F172A);

/// View displaying the MOM Form & Action Points (Matching Image 10 & Action Points).
class MomActivityFormView extends StatefulWidget {
  final MomSiteItemModel site;
  final List<MomActivityModel> activities;
  final MomActivityModel activity;

  const MomActivityFormView({
    super.key,
    required this.site,
    required this.activities,
    required this.activity,
  });

  @override
  State<MomActivityFormView> createState() => _MomActivityFormViewState();
}

class _MomActivityFormViewState extends State<MomActivityFormView> {
  int _selectedSubTab = 0; // 0 = MOM, 1 = Action Points
  int _visitSelectorStyle = 0; // 0 = Dropdown (Default), 1 = Wrapped Badges, 2 = Card Tiles

  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final TextEditingController _meetingAttendeesController;
  late final TextEditingController _clientAttendeesController;

  @override
  void initState() {
    super.initState();
    _initFormData();
  }

  @override
  void didUpdateWidget(covariant MomActivityFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity.id != widget.activity.id) {
      _initFormData();
    }
  }

  void _initFormData() {
    final act = widget.activity;

    final toText = act.mom.to.isNotEmpty
        ? act.mom.to.join(', ')
        : 'kishorekumar@digilogy.co';
    _toController = TextEditingController(text: toText);

    final ccText = act.mom.cc.isNotEmpty ? act.mom.cc.join(', ') : '';
    _ccController = TextEditingController(text: ccText);

    final subjectText = act.mom.subject.isNotEmpty
        ? act.mom.subject
        : act.generateDefaultSubject(widget.site.siteName);
    _subjectController = TextEditingController(text: subjectText);

    _bodyController = TextEditingController(text: act.mom.body);
    _meetingAttendeesController =
        TextEditingController(text: act.mom.meetingAttendees);
    _clientAttendeesController =
        TextEditingController(text: act.mom.clientAttendees);
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _meetingAttendeesController.dispose();
    _clientAttendeesController.dispose();
    super.dispose();
  }

  void _sendMomEmail() {
    final toList = _toController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one recipient in "To".'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final ccList = _ccController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = {
      'to': toList,
      'cc': ccList,
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'meetingAttendees': _meetingAttendeesController.text.trim(),
      'clientAttendees': _clientAttendeesController.text.trim(),
      'points': widget.activity.mom.points.map((p) => p.toJson()).toList(),
    };

    context.read<MomBloc>().add(
          SendMomEmailAction(
            activityId: widget.activity.id,
            payload: payload,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final isSent = act.isSent;
    final activities = widget.activities;

    // Available roles
    final availableRoles = <String>{};
    for (final a in activities) {
      final r = a.role.isNotEmpty ? a.role : a.roleLabel;
      if (r.isNotEmpty) availableRoles.add(r);
    }
    final currentRole = act.role.isNotEmpty ? act.role : act.roleLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 650;

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 24 : 16,
            vertical: 16,
          ),
          children: [
            // ── Breadcrumb: <- All sites ────────────────────────────────────
            InkWell(
              onTap: () {
                context.read<MomBloc>().add(const BackToMomSitesList());
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'All sites',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Site Title & Subtitle ──────────────────────────────────────
            Text(
              widget.site.siteName,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kDarkText,
                letterSpacing: -0.3,
              ),
            ),
            if (_buildSiteCodeAndZone(widget.site, act).isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _buildSiteCodeAndZone(widget.site, act),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _kSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              'Pick A Visit To Send Or Review MOM.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _kSlate,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),

            // ── Visit Selection (Dropdown / Badges / Cards) ─────────────────
            if (activities.isNotEmpty) ...[
              _buildVisitSelectorSection(act, activities),
              const SizedBox(height: 12),

              // ── Summary Strip: Governance | Role | Visit date | Status ────
              _buildSummaryStrip(act, isSent),
              const SizedBox(height: 16),
            ],

            // ── 3 Metric Cards Row (All, Pending, Completed) ───────────────
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    title: 'All',
                    count: activities.length,
                    icon: Icons.mail_outline_rounded,
                    activeColor: _kBlue,
                    isSelected: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Pending',
                    count: activities.where((a) => a.isPending).length,
                    icon: Icons.access_time_rounded,
                    activeColor: _kAmber,
                    bgColor: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFDE68A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailMetricCard(
                    title: 'Completed',
                    count: activities.where((a) => a.isSent).length,
                    icon: Icons.check_circle_outline_rounded,
                    activeColor: _kGreen,
                    bgColor: const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFFBBF7D0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Sub-row: Green Sent Pill / Amber Pill on Left, Role Dropdown on Right ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSent
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSent
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSent
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                        size: 15,
                        color: isSent ? _kGreen : _kAmber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSent
                            ? 'SENT ON ${act.formattedSentAt.isNotEmpty ? act.formattedSentAt : act.formattedVisitDate}'
                            : 'MOM PENDING',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isSent ? _kGreen : _kAmber,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Role Dropdown [ EHS ⌵ ]
                if (availableRoles.isNotEmpty)
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableRoles.contains(currentRole)
                            ? currentRole
                            : availableRoles.first,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _kSlate,
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kDarkText,
                        ),
                        items: availableRoles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (newRole) {
                          if (newRole != null) {
                            context
                                .read<MomBloc>()
                                .add(SelectMomRole(newRole));
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Main Card (Activity Title + Sub-tabs + Content) ────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isWide ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Header: "EHS Audit Visit" + "Sent" badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          act.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: _kDarkText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSent
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isSent ? 'Sent' : 'Draft',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSent ? _kGreen : _kAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Sub-tabs: [ MOM ] and [ Action Points X/Y ]
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSubTabButton(
                          title: 'MOM',
                          isSelected: _selectedSubTab == 0,
                          onTap: () => setState(() => _selectedSubTab = 0),
                        ),
                        const SizedBox(width: 4),
                        _buildSubTabButton(
                          title: act.totalPoints > 0
                              ? 'Action Points ${act.completedPoints}/${act.totalPoints}'
                              : 'Action Points',
                          isSelected: _selectedSubTab == 1,
                          onTap: () => setState(() => _selectedSubTab = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sub-tab Content
                  if (_selectedSubTab == 0)
                    _buildMomSubTabContent(act, isSent)
                  else
                    _buildActionPointsSubTabContent(act, isWide),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }

  String _buildSiteCodeAndZone(MomSiteItemModel site, MomActivityModel act) {
    final code = site.siteCode.isNotEmpty ? site.siteCode : act.siteCode;
    final zone = site.zoneName.isNotEmpty ? site.zoneName : act.zoneName;
    if (code.isNotEmpty && zone.isNotEmpty) {
      return '$code · $zone';
    } else if (code.isNotEmpty) {
      return code;
    }
    return zone;
  }

  Widget _buildVisitSelectorSection(
    MomActivityModel act,
    List<MomActivityModel> activities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  size: 15,
                  color: _kBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Select Visit (${activities.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDarkText,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyleToggleItem(
                    label: 'Dropdown',
                    icon: Icons.arrow_drop_down_circle_outlined,
                    index: 0,
                  ),
                  _buildStyleToggleItem(
                    label: 'Badges',
                    icon: Icons.label_outline_rounded,
                    index: 1,
                  ),
                  _buildStyleToggleItem(
                    label: 'Cards',
                    icon: Icons.grid_view_rounded,
                    index: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_visitSelectorStyle == 0)
          _buildDropdownSelector(act, activities)
        else if (_visitSelectorStyle == 1)
          _buildWrappedBadgesSelector(act, activities)
        else
          _buildCardTilesSelector(act, activities),
      ],
    );
  }

  Widget _buildStyleToggleItem({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _visitSelectorStyle == index;
    return InkWell(
      onTap: () => setState(() => _visitSelectorStyle = index),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? _kBlue : _kSlate,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kBlue : _kSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector(
    MomActivityModel act,
    List<MomActivityModel> activities,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activities.any((a) => a.id == act.id) ? act.id : activities.first.id,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _kBlue,
            size: 20,
          ),
          borderRadius: BorderRadius.circular(12),
          items: activities.map((a) {
            final isItemSent = a.isSent;
            final isCurrent = a.id == act.id;
            return DropdownMenuItem<String>(
              value: a.id,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isItemSent ? _kGreen : _kAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${a.title} (${a.code})',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? _kBlue : _kDarkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    a.formattedVisitDate,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: _kSlate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isItemSent
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isItemSent ? _kGreen : _kAmber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isItemSent ? 'Sent' : 'Pending',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isItemSent ? _kGreen : _kAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newId) {
            if (newId != null && newId != act.id) {
              final selected = activities.firstWhere((a) => a.id == newId);
              context.read<MomBloc>().add(SelectMomActivityDirectly(selected));
            }
          },
        ),
      ),
    );
  }

  Widget _buildWrappedBadgesSelector(
    MomActivityModel act,
    List<MomActivityModel> activities,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activities.map((a) {
        final isSelected = a.id == act.id;
        final isItemSent = a.isSent;
        return InkWell(
          onTap: () {
            if (!isSelected) {
              context.read<MomBloc>().add(SelectMomActivityDirectly(a));
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _kBlue : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isItemSent ? _kGreen : _kAmber,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${a.title} (${a.code})',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : _kDarkText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardTilesSelector(
    MomActivityModel act,
    List<MomActivityModel> activities,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final itemWidth = isMobile
            ? (constraints.maxWidth - (activities.length > 1 ? 10 : 0)) /
                    (activities.length > 1 ? 2 : 1) -
                1
            : 220.0;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: activities.map((a) {
            final isSelected = a.id == act.id;
            final isItemSent = a.isSent;
            return SizedBox(
              width: itemWidth.clamp(140.0, 360.0),
              child: InkWell(
                onTap: () {
                  if (!isSelected) {
                    context.read<MomBloc>().add(SelectMomActivityDirectly(a));
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _kBlue : _kBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            a.code,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? _kBlue : _kSlate,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isItemSent
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isItemSent ? 'Sent' : 'Pending',
                              style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isItemSent ? _kGreen : _kAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: _kDarkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.formattedVisitDate,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: _kSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryStrip(MomActivityModel act, bool isSent) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem('Governance', act.title),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryItem(
                        'Role',
                        act.role.isNotEmpty ? act.role : act.roleLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Visit date',
                        act.formattedVisitDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryStatusItem(isSent),
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSummaryItem('Governance', act.title),
              ),
              Expanded(
                flex: 2,
                child: _buildSummaryItem(
                  'Role',
                  act.role.isNotEmpty ? act.role : act.roleLabel,
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildSummaryItem(
                  'Visit date',
                  act.formattedVisitDate,
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildSummaryStatusItem(isSent),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isNotEmpty ? value : '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kDarkText,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStatusItem(bool isSent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSent ? _kGreen : _kAmber,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isSent ? 'Sent' : 'Pending',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSent ? _kGreen : _kAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? _kBlue : _kSlate,
          ),
        ),
      ),
    );
  }

  // ── MOM Sub-tab Content (To, Cc, Subject, Body, Attendees) ────────────────
  Widget _buildMomSubTabContent(MomActivityModel act, bool isSent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // To *
        _fieldLabel('To *'),
        _readonlyOrEditableField(
          controller: _toController,
          isReadonly: isSent,
          hint: 'e.g. client@example.com',
        ),
        const SizedBox(height: 14),

        // Cc
        _fieldLabel('Cc'),
        _readonlyOrEditableField(
          controller: _ccController,
          isReadonly: isSent,
          hint: 'Add comma-separated emails',
        ),
        const SizedBox(height: 14),

        // Subject *
        _fieldLabel('Subject *'),
        _readonlyOrEditableField(
          controller: _subjectController,
          isReadonly: isSent,
          hint: 'Subject line',
        ),
        const SizedBox(height: 14),

        // Body
        _fieldLabel('Body'),
        _readonlyOrEditableField(
          controller: _bodyController,
          isReadonly: isSent,
          maxLines: 4,
          hint: 'E.G. Dear HR / L&D,',
        ),
        const SizedBox(height: 14),

        // Meeting Attendees
        _fieldLabel('Meeting Attendees'),
        _readonlyOrEditableField(
          controller: _meetingAttendeesController,
          isReadonly: isSent,
          maxLines: 2,
          hint: 'Names Of People Who Attended This Meeting',
        ),
        const SizedBox(height: 14),

        // Client Attendees
        _fieldLabel('Client Attendees'),
        _readonlyOrEditableField(
          controller: _clientAttendeesController,
          isReadonly: isSent,
          maxLines: 2,
          hint: 'Names Of Client Attendees',
        ),
        const SizedBox(height: 22),

        // Actions if pending
        if (!isSent) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Draft saved locally.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save Draft',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDarkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendMomEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Send MOM',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _kDarkText,
        ),
      ),
    );
  }

  Widget _readonlyOrEditableField({
    required TextEditingController controller,
    required bool isReadonly,
    int maxLines = 1,
    String hint = '',
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadonly,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _kDarkText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: _kSlate.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: isReadonly ? const Color(0xFFF8FAFC) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    );
  }

  // ── Action Points Sub-tab (Metric Cards + Status Toggle Table) ────────────
  Widget _buildActionPointsSubTabContent(MomActivityModel act, bool isWide) {
    final points = act.mom.points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Inner Metric Cards (All, Pending, Completed)
        Row(
          children: [
            // All
            Expanded(
              child: _ActionPointMiniCard(
                title: 'All',
                count: act.totalPoints,
                activeColor: _kDarkText,
                bgColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(width: 10),

            // Pending
            Expanded(
              child: _ActionPointMiniCard(
                title: 'Pending',
                count: act.pendingPoints,
                activeColor: _kAmber,
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                icon: Icons.access_time_rounded,
              ),
            ),
            const SizedBox(width: 10),

            // Completed
            Expanded(
              child: _ActionPointMiniCard(
                title: 'Completed',
                count: act.completedPoints,
                activeColor: _kGreen,
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Action Points List / Table
        if (points.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No Action Points recorded for this visit.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: _kSlate,
              ),
            ),
          )
        else if (isWide)
          _buildActionPointsTable(act, points)
        else
          _buildActionPointsMobileCards(act, points),
      ],
    );
  }

  Widget _buildActionPointsTable(
    MomActivityModel act,
    List<MomPointModel> points,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 890,
            child: Column(
              children: [
            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'S.No',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: Text(
                      'Action Point',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      'Department',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Target',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: Text(
                      'Status',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rows
            for (final entry in points.asMap().entries) ...[
              if (entry.key > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
              Builder(
                builder: (context) {
                  final idx = entry.key;
                  final p = entry.value;
                  final isDone = p.isDone;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // S.No
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: _kSlate,
                            ),
                          ),
                        ),

                        // Action Point
                        SizedBox(
                          width: 300,
                          child: Text(
                            p.point.isNotEmpty ? p.point : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kDarkText,
                            ),
                          ),
                        ),

                        // Department
                        SizedBox(
                          width: 130,
                          child: Text(
                            p.department.isNotEmpty ? p.department : 'Operations',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kDarkText,
                            ),
                          ),
                        ),

                        // Target
                        SizedBox(
                          width: 120,
                          child: Text(
                            p.targetDate.isNotEmpty ? p.targetDate : '—',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: _kSlate,
                            ),
                          ),
                        ),

                        // Status Toggle Buttons: [ Pending ] [ Completed ]
                        SizedBox(
                          width: 250,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _statusToggleButton(
                                label: 'Pending',
                                isActive: !isDone,
                                activeColor: _kAmber,
                                onTap: isDone
                                    ? () {
                                        context.read<MomBloc>().add(
                                              UpdateMomPointStatusAction(
                                                activityId: act.id,
                                                pointId: p.id,
                                                status: 'OPEN',
                                              ),
                                            );
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              _statusToggleButton(
                                label: 'Completed',
                                isActive: isDone,
                                activeColor: _kGreen,
                                onTap: !isDone
                                    ? () {
                                        context.read<MomBloc>().add(
                                              UpdateMomPointStatusAction(
                                                activityId: act.id,
                                                pointId: p.id,
                                                status: 'DONE',
                                              ),
                                            );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
  }

  // ── Mobile Responsive Action Point Cards ──────────────────────────────────
  Widget _buildActionPointsMobileCards(
    MomActivityModel act,
    List<MomPointModel> points,
  ) {
    return Column(
      children: List.generate(points.length, (idx) {
        final p = points[idx];
        final isDone = p.isDone;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
              width: isDone ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: #Index + Department + Target
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${idx + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kSlate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (p.department.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.department,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (p.targetDate.isNotEmpty) ...[
                    const Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: _kSlate,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.targetDate,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _kSlate,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Action Point Text
              Text(
                p.point.isNotEmpty ? p.point : 'Action point observation',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _kDarkText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Status Toggle Buttons Row
              Row(
                children: [
                  Text(
                    'Status:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSlate,
                    ),
                  ),
                  const Spacer(),
                  _statusToggleButton(
                    label: 'Pending',
                    isActive: !isDone,
                    activeColor: _kAmber,
                    onTap: isDone
                        ? () {
                            context.read<MomBloc>().add(
                                  UpdateMomPointStatusAction(
                                    activityId: act.id,
                                    pointId: p.id,
                                    status: 'OPEN',
                                  ),
                                );
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _statusToggleButton(
                    label: 'Completed',
                    isActive: isDone,
                    activeColor: _kGreen,
                    onTap: !isDone
                        ? () {
                            context.read<MomBloc>().add(
                                  UpdateMomPointStatusAction(
                                    activityId: act.id,
                                    pointId: p.id,
                                    status: 'DONE',
                                  ),
                                );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statusToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : _kSlate,
          ),
        ),
      ),
    );
  }
}

// ── Detail Metric Card ───────────────────────────────────────────────────────
class _DetailMetricCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color activeColor;
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;

  const _DetailMetricCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.activeColor,
    this.bgColor = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0),
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? activeColor : borderColor,
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? activeColor : _kSlate,
                ),
              ),
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : _kSlate,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isSelected ? activeColor : _kDarkText,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Point Mini Card ───────────────────────────────────────────────────
class _ActionPointMiniCard extends StatelessWidget {
  final String title;
  final int count;
  final Color activeColor;
  final Color bgColor;
  final Color borderColor;
  final IconData? icon;

  const _ActionPointMiniCard({
    required this.title,
    required this.count,
    required this.activeColor,
    required this.bgColor,
    required this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 14,
                  color: activeColor,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}
