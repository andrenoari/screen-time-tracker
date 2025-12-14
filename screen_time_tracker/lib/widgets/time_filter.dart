import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/screen_time_provider.dart';
import '../theme/app_theme.dart';

class TimeFilter extends StatelessWidget {
  const TimeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              _FilterButton(
                label: 'Today',
                isSelected: provider.selectedDays == 1,
                onTap: () => provider.loadDataForDays(1),
              ),
              _FilterButton(
                label: '7 Days',
                isSelected: provider.selectedDays == 7,
                onTap: () => provider.loadDataForDays(7),
              ),
              _FilterButton(
                label: '30 Days',
                isSelected: provider.selectedDays == 30,
                onTap: () => provider.loadDataForDays(30),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.isSelected ? AppTheme.primaryGradient : null,
              color: widget.isSelected
                  ? null
                  : _isHovered
                      ? AppTheme.backgroundCardHover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white
                      : _isHovered
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
