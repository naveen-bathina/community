import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_unity_network/core/config/app_config.dart';
import 'package:legal_unity_network/core/theme/app_theme.dart';

/// Official insignia / emblem for the Legal Union.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBadgeBorder;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool useAssetImage;

  const AppLogo({
    super.key,
    this.size = 64,
    this.showBadgeBorder = true,
    this.backgroundColor,
    this.iconColor,
    this.useAssetImage = false,
  });

  const AppLogo.asset({
    super.key,
    this.size = 64,
    this.showBadgeBorder = true,
    this.backgroundColor,
    this.iconColor,
  }) : useAssetImage = true;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppTheme.primaryBlue;
    final effectiveIconColor = iconColor ?? Colors.amber.shade400;

    if (useAssetImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: effectiveBg.withValues(alpha: 0.35),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildVectorLogo(effectiveBg, effectiveIconColor),
          ),
        ),
      );
    }

    return _buildVectorLogo(effectiveBg, effectiveIconColor);
  }

  Widget _buildVectorLogo(Color effectiveBg, Color effectiveIconColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            effectiveBg,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveBg.withValues(alpha: 0.35),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: showBadgeBorder
            ? Border.all(
                color: Colors.amber.shade300,
                width: size > 60 ? 3 : 2,
              )
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Legal balance scales motif
            Icon(
              Icons.balance_rounded,
              size: size * 0.58,
              color: effectiveIconColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standardized Brand Header displaying the logo, official union title, and motto.
class AppBrandHeader extends StatelessWidget {
  final double logoSize;
  final bool showMotto;
  final bool showSubtitle;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const AppBrandHeader({
    super.key,
    this.logoSize = 72,
    this.showMotto = true,
    this.showSubtitle = true,
    this.alignment = CrossAxisAlignment.center,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 16),
        Text(
          AppConfig.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.3,
              ),
          textAlign: textAlign,
        ),
        if (showMotto) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300, width: 0.8),
            ),
            child: Text(
              AppConfig.appMotto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.brown.shade800,
                letterSpacing: 0.8,
              ),
              textAlign: textAlign,
            ),
          ),
        ],
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          Text(
            AppConfig.appSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                  height: 1.4,
                ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}

/// Dialog to share union invite details with colleague advocates.
class InviteAdvocatesDialog extends StatelessWidget {
  const InviteAdvocatesDialog({super.key});

  static String get inviteMessage =>
      'Colleague Advocates,\n\n'
      'Join ${AppConfig.appName} — the official democratic platform for verified legal practitioners. '
      'Connect with counsel across State Bar Councils, participate in annual Union elections, '
      'and access verified case referrals.\n\n'
      'Download the app & verify enrollment: ${AppConfig.websiteUrl}\n\n'
      '"${AppConfig.appMotto}"';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const AppLogo(size: 36, showBadgeBorder: false),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Invite Colleagues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help expand the legal fraternity! Share this official invitation with fellow advocates:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                inviteMessage,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Invitation'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: inviteMessage));
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation copied to clipboard! Share with colleagues.'),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      ],
    );
  }
}
