import 'package:flutter/material.dart';
import '../services/in_app_notification_service.dart';
import 'kaspot_avatar.dart';

class InAppNotificationBanner extends StatelessWidget {
  const InAppNotificationBanner({super.key});

  Color _badgeColor(String? relationship) {
    switch (relationship) {
      case 'Partner':
        return const Color(0xFFE11D48); // Rose
      case 'Family':
        return const Color(0xFF7C3AED); // Purple
      case 'Friend':
      default:
        return const Color(0xFF0284C7); // Sky/Blue
    }
  }

  IconData _badgeIcon(String? relationship, InAppNotificationType type) {
    if (type == InAppNotificationType.arrival) return Icons.location_on_rounded;
    if (type == InAppNotificationType.request) return Icons.person_add_rounded;
    switch (relationship) {
      case 'Partner':
        return Icons.favorite_rounded;
      case 'Family':
        return Icons.family_restroom_rounded;
      case 'Friend':
      default:
        return Icons.chat_bubble_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InAppNotificationPayload?>(
      valueListenable: InAppNotificationService.activeNotification,
      builder: (context, payload, _) {
        if (payload == null) {
          return const SizedBox.shrink();
        }

        final rel = payload.relationship ?? 'Friend';
        final badgeColor = _badgeColor(rel);
        final icon = _badgeIcon(rel, payload.type);

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: GestureDetector(
                onTap: () {
                  payload.onTap?.call();
                  InAppNotificationService.dismiss();
                },
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    InAppNotificationService.dismiss();
                  }
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1.0 - value) * -40),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xF20F172A), // Sleek Slate-900 glass
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              KaSpotAvatar(
                                name: payload.title,
                                avatarUrl: payload.avatarUrl,
                                size: 40,
                                isCircle: true,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                                  ),
                                  child: Icon(icon, color: Colors.white, size: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        payload.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Text(
                                      'now',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  payload.body,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: InAppNotificationService.dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
