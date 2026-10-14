import 'package:flutter/material.dart';

/// Data class representing an item in the [InteractiveNavBar].
class InteractiveNavItem {
  const InteractiveNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// When > 0, a red badge is shown on the icon bubble.
  final int badgeCount;
}

/// Custom animated pop-out navigation bar.
///
/// When a tab is selected, it physically pops upward with a spring curve
/// and casts a soft 3D ambient glow shadow, creating a tactile "hovering" effect.
class InteractiveNavBar extends StatelessWidget {
  const InteractiveNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<InteractiveNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: _NavTabItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final InteractiveNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBadge = item.badgeCount > 0;
    final badgeLabel = item.badgeCount > 99 ? '99+' : '${item.badgeCount}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pop-Out Animated Icon Bubble with optional red badge
            AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              offset: Offset(0, isSelected ? -0.15 : 0),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF1E5EBF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.transparent,
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x382196F3),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        scale: isSelected ? 1.06 : 1.0,
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),

                  // Red unread badge — top-right corner of the bubble
                  if (hasBadge)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        scale: hasBadge ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            badgeLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            // Tab label with color transition
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF1E5EBF) : const Color(0xFF64748B),
                letterSpacing: -0.2,
              ),
              child: Text(item.label),
            ),

            // Active precision beacon dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(top: 2),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
