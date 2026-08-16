import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/sagiro_design_tokens.dart';

/// SagiroCard — Premium Tonal Glass Container Component.
class SagiroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color glowColor;

  const SagiroCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.onTap,
    this.hasGlow = false,
    this.glowColor = SagiroColors.primaryCyan,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.cardColor(context);
    final border = borderColor ?? AppTheme.borderColor(context);

    final container = Container(
      padding: padding ?? const EdgeInsets.all(SagiroSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: hasGlow ? SagiroElevation.subtleGlow(glowColor) : SagiroElevation.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
    return container;
  }
}

/// SagiroButton — Standard Action Button (Primary Cyan, Ghost, Danger).
enum SagiroButtonVariant { primary, secondary, ghost, danger }

class SagiroButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SagiroButtonVariant variant;
  final bool isLoading;
  final double? width;

  const SagiroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SagiroButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case SagiroButtonVariant.primary:
        bg = SagiroColors.primaryCyan;
        fg = Colors.white;
        break;
      case SagiroButtonVariant.secondary:
        bg = AppTheme.cardColor(context);
        fg = AppTheme.textPrimaryColor(context);
        border = BorderSide(color: AppTheme.borderColor(context));
        break;
      case SagiroButtonVariant.ghost:
        bg = Colors.transparent;
        fg = SagiroColors.primaryCyan;
        break;
      case SagiroButtonVariant.danger:
        bg = SagiroColors.semanticDanger;
        fg = Colors.white;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: SagiroRadius.borderMd,
            side: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: SagiroSpacing.lg),
        ),
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}

/// SagiroChip — Standardized Category & Status Tag Chip.
class SagiroChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  const SagiroChip({
    super.key,
    required this.label,
    this.icon,
    this.color = SagiroColors.primaryCyan,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? color : color.withOpacity(0.12);
    final fg = isSelected ? Colors.white : color;

    return InkWell(
      onTap: onTap,
      borderRadius: SagiroRadius.borderPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: SagiroRadius.borderPill,
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SagiroTextField — Focus-Illuminated Search & Text Field.
class SagiroTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const SagiroTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: SagiroRadius.borderLg,
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: textPrimary, fontSize: 14),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: SagiroColors.primaryCyan, size: 20) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// SagiroSectionHeader — Upper-case Section Header.
class SagiroSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SagiroSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.textMutedColor(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// SagiroStatCard — Monospaced Currency Summary Card.
class SagiroStatCard extends StatelessWidget {
  final String title;
  final String amountText;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;

  const SagiroStatCard({
    super.key,
    required this.title,
    required this.amountText,
    required this.icon,
    required this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return SagiroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountText,
            style: SagiroTypography.currencyMedium(context, color: textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// SagiroTransactionTile — Standardized Transaction Timeline Row.
class SagiroTransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String amountText;
  final bool isCredit;
  final String dateText;
  final String? accountText;
  final String? sourceText;
  final VoidCallback? onTap;

  const SagiroTransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amountText,
    required this.isCredit,
    required this.dateText,
    this.accountText,
    this.sourceText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final textMuted = AppTheme.textMutedColor(context);
    final amountColor = isCredit ? SagiroColors.secondaryEmerald : textPrimary;

    return SagiroCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit
                  ? SagiroColors.secondaryEmerald.withOpacity(0.15)
                  : SagiroColors.primaryCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
              color: isCredit ? SagiroColors.secondaryEmerald : SagiroColors.primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      category,
                      style: TextStyle(color: textSecondary, fontSize: 11.5),
                    ),
                    if (accountText != null) ...[
                      Text(' • ', style: TextStyle(color: textMuted)),
                      Text(
                        accountText!,
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : ""}$amountText',
                style: SagiroTypography.currencySmall(context, color: amountColor),
              ),
              const SizedBox(height: 2),
              Text(
                dateText,
                style: TextStyle(color: textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SagiroStatusBadge — Operational Status Badge Component.
class SagiroStatusBadge extends StatelessWidget {
  final String label;
  final bool isHealthy;

  const SagiroStatusBadge({
    super.key,
    required this.label,
    this.isHealthy = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? SagiroColors.semanticSuccess : SagiroColors.semanticWarning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: SagiroRadius.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// SagiroEmptyState — Reusable Empty State Container.
class SagiroEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SagiroEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Padding(
      padding: const EdgeInsets.all(SagiroSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 54, color: SagiroColors.primaryCyan.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            SagiroButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: SagiroButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// SagiroLoadingState — Standard Progress Indicator.
class SagiroLoadingState extends StatelessWidget {
  final String? message;

  const SagiroLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: SagiroColors.primaryCyan),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// SagiroErrorState — Error State Container.
class SagiroErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SagiroErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SagiroCard(
      borderColor: SagiroColors.semanticDanger.withOpacity(0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: SagiroColors.semanticDanger, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            SagiroButton(
              label: 'Retry',
              onPressed: onRetry,
              variant: SagiroButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// SagiroReviewCard — Reusable Needs Review & Duplicate Review Action Card.
class SagiroReviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amountText;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  const SagiroReviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.onConfirm,
    required this.onEdit,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return SagiroCard(
      borderColor: SagiroColors.semanticWarning.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SagiroStatusBadge(label: 'Needs Review', isHealthy: false),
              Text(
                amountText,
                style: SagiroTypography.currencySmall(context, color: AppTheme.textPrimaryColor(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SagiroButton(
                  label: 'Confirm',
                  onPressed: onConfirm,
                  variant: SagiroButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SagiroButton(
                  label: 'Edit',
                  onPressed: onEdit,
                  variant: SagiroButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: SagiroColors.semanticDanger),
                onPressed: onDiscard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
