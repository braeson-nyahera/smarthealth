import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final UserProfile? existingProfile;

  const ProfileSetupScreen({
    super.key,
    required this.onComplete,
    this.existingProfile,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  late PageController _pageController;

  DiabetesState _selectedDiabetesState = DiabetesState.none;
  int _currentStep = 0;
  bool _isSubmitting = false;

  final List<String> _stepTitles = [
    'Basic Information',
    'Health Information',
    'Physical Measurements',
    'Review & Complete',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize PageController
    _pageController = PageController(initialPage: 0);

    // Initialize animations
    _animationController = AnimationController(
      duration: AppTheme.animationMedium,
      vsync: this,
    );

    _progressController = AnimationController(
      duration: AppTheme.animationSlow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Load existing profile if available
    if (widget.existingProfile != null) {
      _loadExistingProfile();
    }

    _animationController.forward();
  }

  void _loadExistingProfile() {
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

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      final nextStep = _currentStep + 1;
      _pageController.animateToPage(
        nextStep,
        duration: AppTheme.animationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      final previousStep = _currentStep - 1;
      _pageController.animateToPage(
        previousStep,
        duration: AppTheme.animationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateProgress() {
    _progressController.animateTo((_currentStep + 1) / _stepTitles.length);
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
        debugPrint('Profile saved successfully: $profile');
        widget.onComplete();
      } else {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.error,
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable swiping
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                    _animationController.reset();
                    _animationController.forward();
                    _updateProgress();
                  },
                  children: [
                    _buildAgeStep(),
                    _buildDiabetesStep(),
                    _buildMeasurementsStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryHealthGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXL),
          bottomRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Complete Your Profile',
            style: AppTheme.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Help us personalize your health experience',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _stepTitles[_currentStep],
            style: AppTheme.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index <= _currentStep;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isActive
                          ? AppTheme.primaryMedical
                          : AppTheme.borderSubtle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTheme.bodyMedium.copyWith(
                      color:
                          isActive ? Colors.white : AppTheme.textSecondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressController.value,
                backgroundColor: AppTheme.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryMedical,
                ),
                minHeight: 4,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cake_rounded,
                size: 64,
                color: AppTheme.primaryMedical,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'What\'s your age?',
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'This helps us provide age-appropriate health insights and recommendations.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 150) {
                    return 'Please enter a valid age (1-150)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiabetesStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.medical_information_rounded,
                size: 64,
                color: AppTheme.primaryMedical,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Diabetes Status',
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'This information helps us provide more relevant health monitoring and insights.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              ...DiabetesState.values.map((state) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDiabetesState = state;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _selectedDiabetesState == state
                                    ? AppTheme.primaryMedical
                                    : AppTheme.borderSubtle,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          color:
                              _selectedDiabetesState == state
                                  ? AppTheme.primaryMedical.withOpacity(0.1)
                                  : AppTheme.surfacePure,
                        ),
                        child: Row(
                          children: [
                            Radio<DiabetesState>(
                              value: state,
                              groupValue: _selectedDiabetesState,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDiabetesState = value!;
                                });
                              },
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Text(
                                UserProfile(
                                  diabetesState: state,
                                ).diabetesStateDisplay,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight:
                                      _selectedDiabetesState == state
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementsStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.monitor_weight_rounded,
                size: 64,
                color: AppTheme.primaryMedical,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Physical Measurements',
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'These measurements help calculate your BMI and provide better health insights.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Enter your weight',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 20 || weight > 300) {
                    return 'Please enter a valid weight (20-300 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'Enter your height',
                  prefixIcon: Icon(Icons.height_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final profile = UserProfile(
      age: int.tryParse(_ageController.text),
      diabetesState: _selectedDiabetesState,
      weight: double.tryParse(_weightController.text),
      height: double.tryParse(_heightController.text),
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: AppTheme.success,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Review Your Profile',
                style: AppTheme.headingLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Please review your information before completing your profile setup.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              _buildReviewCard(
                'Age',
                '${profile.age ?? '--'} years',
                Icons.cake_rounded,
              ),
              _buildReviewCard(
                'Diabetes Status',
                profile.diabetesStateDisplay,
                Icons.medical_information_rounded,
              ),
              _buildReviewCard(
                'Weight',
                '${profile.weight ?? '--'} kg',
                Icons.monitor_weight_rounded,
              ),
              _buildReviewCard(
                'Height',
                '${profile.height ?? '--'} cm',
                Icons.height_rounded,
              ),
              if (profile.bmi != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMedical.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryMedical.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Calculated BMI',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryMedical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        profile.bmi!.toStringAsFixed(1),
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.primaryMedical,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profile.bmiCategory,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryMedical,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfacePure,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryMedical),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppTheme.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  _isSubmitting
                      ? null
                      : _currentStep == _stepTitles.length - 1
                      ? _submitProfile
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMedical,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child:
                  _isSubmitting
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        _currentStep == _stepTitles.length - 1
                            ? 'Complete Profile'
                            : 'Next',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
