import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_theme.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class ProfilePage extends StatefulWidget {
  final GoogleSignInAccount user;
  final UserProfile? existingProfile;
  final VoidCallback? onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.user,
    this.existingProfile,
    this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  DiabetesState _selectedDiabetesState = DiabetesState.none;
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Load existing profile if available
    _loadExistingProfile();
    _animationController.forward();
  }

  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      if (profile.age != null) {
        _ageController.text = profile.age.toString();
      }
      if (profile.weight != null) {
        _weightController.text = profile.weight.toString();
      }
      if (profile.height != null) {
        _heightController.text = profile.height.toString();
      }
      _selectedDiabetesState = profile.diabetesState;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Create user profile
      final profile = UserProfile(
        age: int.tryParse(_ageController.text),
        diabetesState: _selectedDiabetesState,
        weight: double.tryParse(_weightController.text),
        height: double.tryParse(_heightController.text),
      );

      // Save profile using UserProfileService
      final success = await UserProfileService.saveProfile(profile);

      if (success) {
        setState(() => _isEditing = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        widget.onProfileUpdated?.call();
      } else {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryMedical,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildHealthProfileCard(),
                  const SizedBox(height: AppTheme.spacingXL),
                  if (_isEditing) _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryMedical.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryHealthGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.2),
                child:
                    widget.user.photoUrl != null
                        ? ClipOval(
                          child: Image.network(
                            widget.user.photoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Colors.white.withOpacity(0.9),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Colors.white.withOpacity(0.9),
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.person_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.9),
                        ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName ?? 'Health User',
                    style: AppTheme.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    widget.user.email,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    child: Text(
                      'Google Account',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  color: AppTheme.primaryMedical,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Health Profile',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildHealthInfoTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoTable() {
    final profile = widget.existingProfile;
    final bmi = profile?.bmi;
    final bmiCategory = profile?.bmiCategory;

    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      children: [
        _buildTableRow('Age', _buildAgeField()),
        _buildTableRow('Diabetes Status', _buildDiabetesField()),
        _buildTableRow('Weight', _buildWeightField()),
        _buildTableRow('Height', _buildHeightField()),
        if (bmi != null && bmi > 0)
          _buildTableRow(
            'BMI',
            _buildInfoCell('${bmi.toStringAsFixed(1)} - $bmiCategory'),
          ),
      ],
    );
  }

  TableRow _buildTableRow(String label, Widget valueWidget) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          child: Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          child: valueWidget,
        ),
      ],
    );
  }

  Widget _buildAgeField() {
    if (_isEditing) {
      return TextFormField(
        controller: _ageController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: 'Enter your age',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your age';
          }
          final age = int.tryParse(value);
          if (age == null || age < 18 || age > 120) {
            return 'Please enter a valid age (18-120)';
          }
          return null;
        },
      );
    }
    return _buildInfoCell(
      _ageController.text.isEmpty
          ? 'Not specified'
          : '${_ageController.text} years',
    );
  }

  Widget _buildDiabetesField() {
    if (_isEditing) {
      return DropdownButtonFormField<DiabetesState>(
        value: _selectedDiabetesState,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
        ),
        items:
            DiabetesState.values.map((state) {
              return DropdownMenuItem(
                value: state,
                child: Text(_getDiabetesDisplayText(state)),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedDiabetesState = value);
          }
        },
      );
    }
    return _buildInfoCell(_getDiabetesDisplayText(_selectedDiabetesState));
  }

  Widget _buildWeightField() {
    if (_isEditing) {
      return TextFormField(
        controller: _weightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          hintText: 'Enter weight (kg)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your weight';
          }
          final weight = double.tryParse(value);
          if (weight == null || weight < 30 || weight > 300) {
            return 'Please enter a valid weight (30-300 kg)';
          }
          return null;
        },
      );
    }
    return _buildInfoCell(
      _weightController.text.isEmpty
          ? 'Not specified'
          : '${_weightController.text} kg',
    );
  }

  Widget _buildHeightField() {
    if (_isEditing) {
      return TextFormField(
        controller: _heightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          hintText: 'Enter height (cm)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your height';
          }
          final height = double.tryParse(value);
          if (height == null || height < 100 || height > 250) {
            return 'Please enter a valid height (100-250 cm)';
          }
          return null;
        },
      );
    }
    return _buildInfoCell(
      _heightController.text.isEmpty
          ? 'Not specified'
          : '${_heightController.text} cm',
    );
  }

  Widget _buildInfoCell(String text) {
    return Text(
      text,
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimaryDark),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isSubmitting
                    ? null
                    : () {
                      setState(() => _isEditing = false);
                      _loadExistingProfile(); // Reset form
                    },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              side: BorderSide(color: AppTheme.textSecondaryDark),
            ),
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMedical,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
            ),
            child:
                _isSubmitting
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      'Save Changes',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  String _getDiabetesDisplayText(DiabetesState state) {
    switch (state) {
      case DiabetesState.none:
        return 'No Diabetes';
      case DiabetesState.type1:
        return 'Type 1 Diabetes';
      case DiabetesState.type2:
        return 'Type 2 Diabetes';
      case DiabetesState.prediabetes:
        return 'Pre-diabetes';
    }
  }
}
