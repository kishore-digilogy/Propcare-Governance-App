import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/notification_item_model.dart';

class NotificationCardItem extends StatelessWidget {
  final NotificationItemModel item;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationCardItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkAsRead,
  });

  ({IconData icon, Color iconColor, Color bgColor, String label}) _resolveTypeMeta() {
    final typeUpper = item.type.toUpperCase();
    final catUpper = item.category.toUpperCase();

    if (typeUpper.contains('TAT') || item.title.toLowerCase().contains('tat')) {
      return (
        icon: Icons.timer_outlined,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
        label: 'TAT Alert',
      );
    }
    if (typeUpper.contains('ACTION') || item.title.toLowerCase().contains('action')) {
      return (
        icon: Icons.bolt_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        label: 'Action Point',
      );
    }
    if (typeUpper.contains('ISSUE') || catUpper.contains('ISSUE')) {
      return (
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFEA580C),
        bgColor: const Color(0xFFFFF7ED),
        label: 'Issue Alert',
      );
    }
    if (typeUpper.contains('ASSIGN') || item.title.toLowerCase().contains('assigned')) {
      return (
        icon: Icons.assignment_ind_outlined,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        label: 'Assignment',
      );
    }
    if (typeUpper.contains('MAP') || item.title.toLowerCase().contains('mapping')) {
      return (
        icon: Icons.supervised_user_circle_outlined,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        label: 'SPOC Mapping',
      );
    }

    return (
      icon: Icons.notifications_outlined,
      iconColor: const Color(0xFF0284C7),
      bgColor: const Color(0xFFF0F9FF),
      label: item.category.isNotEmpty ? item.category : 'Notice',
    );
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$month ${dt.day}, $hour:$minute $ampm';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _resolveTypeMeta();
    final isUnread = item.unread;
    final timeStr = _formatDateTime(item.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isUnread) onMarkAsRead();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF8FAFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              width: isUnread ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                    : const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meta.bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: meta.iconColor.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    meta.icon,
                    size: 20,
                    color: meta.iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Message, Metadata Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Category Pill, Relative Time, Unread Dot
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: meta.bgColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: meta.iconColor.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    meta.label.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: meta.iconColor,
                                    ),
                                  ),
                                ),
                              ),
                              if (item.category.isNotEmpty && item.category.toLowerCase() != meta.label.toLowerCase()) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                            color: isUnread ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: isUnread ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        height: 1.25,
                      ),
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.message,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],

                    // Action footer (Mark as read button if unread)
                    if (isUnread) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: onMarkAsRead,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 14,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mark as read',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
