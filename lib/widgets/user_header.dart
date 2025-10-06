import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_theme.dart';

class UserHeader extends StatefulWidget {
  final GoogleSignInAccount user;
  final int selectedDays;
  final int metricsCount;
  final VoidCallback onRefresh;
  final VoidCallback? onProfileTap;

  const UserHeader({
    super.key,
    required this.user,
    required this.selectedDays,
    required this.metricsCount,
    required this.onRefresh,
    this.onProfileTap,
  });

  @override
  State<UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationSlow,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.animationCurve,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.animationCurve,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    widget.onRefresh();

    // Simulate minimum loading time for UX
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryMedical,
                    AppTheme.primaryMedical.withValues(alpha: 0.9),
                    AppTheme.wellness.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMedical.withValues(alpha: 0.15),
                    offset: const Offset(0, 12),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppTheme.primaryMedical.withValues(alpha: 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  ...AppTheme.elevationHigh,
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.02),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildUserInfo()),
                  if (widget.onProfileTap != null) ...[
                    _buildProfileButton(),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  _buildRefreshButton(),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildStats(),
            ],
          );
        }

        return Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(child: _buildUserInfo()),
            if (widget.onProfileTap != null) ...[
              _buildProfileButton(),
              const SizedBox(width: AppTheme.spacingS),
            ],
            _buildRefreshButton(),
          ],
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primaryMedical.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        child:
            widget.user.photoUrl != null
                ? ClipOval(
                  child: Image.network(
                    widget.user.photoUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.9),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.9),
                      );
                    },
                  ),
                )
                : Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.user.displayName ?? 'Health User',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatBadge(
          '${widget.selectedDays} days',
          Icons.calendar_today_rounded,
          AppTheme.activity,
        ),
        const SizedBox(width: AppTheme.spacingS),
        _buildStatBadge(
          '${widget.metricsCount} metrics',
          Icons.analytics_rounded,
          AppTheme.nutrition,
        ),
      ],
    );
  }

  Widget _buildStatBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: widget.onProfileTap,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: _handleRefresh,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: AnimatedRotation(
              turns: _isRefreshing ? 1 : 0,
              duration:
                  _isRefreshing
                      ? const Duration(milliseconds: 1000)
                      : const Duration(milliseconds: 200),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}
