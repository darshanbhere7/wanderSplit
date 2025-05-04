import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavBarItem(
                  icon: Icons.search,
                  label: 'Search',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _CenterAddButton(
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavBarItem(
                  icon: Icons.message_outlined,
                  label: 'Messages',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavBarItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  selected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey[500];
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color)
                .animate(target: selected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.18, 1.18), duration: 300.ms),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CenterAddButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = Colors.pinkAccent;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 62,
          width: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: selected ? 56 : 52,
            width: selected ? 56 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            )
                .animate(target: selected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.18, 1.18), duration: 300.ms),
          ),
        ),
      ),
    );
  }
} 