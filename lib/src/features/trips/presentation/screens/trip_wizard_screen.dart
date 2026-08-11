import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wonder_souls/src/config/utils/common_widgets/size.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_colors.dart';
import 'package:wonder_souls/src/config/utils/extensions/context_text.dart';
import 'package:wonder_souls/src/features/trips/model/static_data.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';
import 'package:wonder_souls/src/features/trips/presentation/screens/trip_details_screen.dart';

class TripWizardScreen extends StatefulWidget {
  final Map<String, String> destination;

  const TripWizardScreen({super.key, required this.destination});

  static const String routeName = "/TripWizardScreen";

  @override
  State<TripWizardScreen> createState() => _TripWizardScreenState();
}

class _TripWizardScreenState extends State<TripWizardScreen> {
  int _currentStep = 0; // 0 to 4

  // State Variables for Selections
  String _selectedParty = 'A Couple ❤️'; // Default selected
  DateTime? _startDate = DateTime(2023, 12, 12); // Default Dec 12, 2023
  DateTime? _endDate = DateTime(2023, 12, 14); // Default Dec 14, 2023

  final Set<String> _selectedInterests = {
    'Adventure Travel 🧗',
    'Beach Vacations 🏖️',
    'Food Trips 🍜',
    'Food Tourism 🍲',
    'Art Galleries 🎨',
  }; // Default selected interests

  String _selectedBudget = 'Luxury 💎'; // Default selected

  // Generating Overlay State
  bool _isGenerating = false;
  int _generationProgress = 0;
  Timer? _generationTimer;

  // Party Options
  final List<Map<String, String>> _partyOptions = [
    {'title': 'Only Me 🏃', 'subtitle': 'Traveling solo, just you.'},
    {'title': 'A Couple ❤️', 'subtitle': 'A romantic getaway for two.'},
    {
      'title': 'Family 👨‍👩‍👧‍👦',
      'subtitle': 'Quality time with your loved ones.',
    },
    {
      'title': 'Friends 🧑‍🤝‍🧑',
      'subtitle': 'Adventure with your closest pals.',
    },
    {'title': 'Work 💼', 'subtitle': 'Business or corporate travel.'},
  ];

  // Interest Options
  final List<String> _interestOptions = [
    'Adventure Travel 🧗',
    'City Breaks 🌇',
    'Cultural Exploration 🏛️',
    'Glamping ⛺',
    'Beach Vacations 🏖️',
    'Nature Escapes 🌲',
    'Relaxing Getaways 🍃',
    'Food Trips 🍜',
    'Food Tourism 🍲',
    'Backpacking 🎒',
    'Cruise Vacations 🚢',
    'Staycations 🏡',
    'Skiing/Snowboarding ⛷️',
    'Wine Tours 🍷',
    'Wildlife Safaris 🦁',
    'Art Galleries 🎨',
    'Historical Sites 🏰',
    'Eco-Tourism 🌲',
  ];

  // Budget Options
  final List<Map<String, String>> _budgetOptions = [
    {'title': 'Cheap 🪙', 'subtitle': 'Budget-friendly, economical travel.'},
    {
      'title': 'Balanced ⚖️',
      'subtitle': 'Moderate spending for a balanced trip.',
    },
    {'title': 'Luxury 💎', 'subtitle': 'High-end, indulgent experiences.'},
    {'title': 'Flexible 👐', 'subtitle': 'No budget restrictions.'},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _startGeneration() {
    setState(() {
      _isGenerating = true;
      _generationProgress = 0;
    });

    _generationTimer = Timer.periodic(const Duration(milliseconds: 25), (
      timer,
    ) {
      setState(() {
        if (_generationProgress < 100) {
          _generationProgress++;
        } else {
          timer.cancel();
          _isGenerating = false;
          _navigateToItinerary();
        }
      });
    });
  }

  void _navigateToItinerary() {
    final cityName = widget.destination['city'] ?? 'Tokyo';
    final isTokyo = cityName.toLowerCase().contains('tokyo');

    // Create custom trip details based on selections
    final trip = Trip(
      id: cityName,
      name: '$cityName Explorer',
      location: cityName,
      country: widget.destination['country'] ?? '',
      imageUrl: widget.destination['imageUrl'] ?? '',
      startDate: _startDate != null
          ? "${_getMonthName(_startDate!.month)} ${_startDate!.day}, ${_startDate!.year}"
          : 'May 15, 2025',
      endDate: _endDate != null
          ? "${_getMonthName(_endDate!.month)} ${_endDate!.day}, ${_endDate!.year}"
          : 'May 22, 2025',
      days: _endDate != null && _startDate != null
          ? _endDate!.difference(_startDate!).inDays + 1
          : 7,
      places: isTokyo ? StaticData.getTokyoPlaces() : [],
    );

    // Replace wizard with TripDetailsScreen
    Navigator.pushReplacementNamed(
      context,
      TripDetailsScreen.routeName,
      arguments: trip,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _generationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.onSurface),
          onPressed: _previousStep,
        ),
        title: _currentStep == 4
            ? Text(
                'Review Summary',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              )
            : null,
        centerTitle: true,
        bottom: _currentStep < 4
            ? PreferredSize(
                preferredSize: Size.fromHeight(6.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3.r),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 4,
                      color: context.primary,
                      backgroundColor: Colors.grey[200],
                      minHeight: 4.h,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Step Page View Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: _buildCurrentStepContent(),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
          ),

          // Generating Itinerary Modal Overlay
          if (_isGenerating) _buildGeneratingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    String text = _currentStep == 4 ? 'Build My Itinerary' : 'Continue';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: context.surface),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
        ),
        onPressed: _currentStep == 4 ? _startGeneration : _nextStep,
        child: Text(
          text,
          style: context.text.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1WhoIsGoing();
      case 1:
        return _buildStep2Dates();
      case 2:
        return _buildStep3Tastes();
      case 3:
        return _buildStep4Budget();
      case 4:
        return _buildStep5ReviewSummary();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Who is going? ---
  Widget _buildStep1WhoIsGoing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who is going? 💼',
          style: context.text.titleLarge?.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
        8.h.height,
        Text(
          'Let\'s get started by selecting who you\'re traveling with.',
          style: context.text.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        20.h.height,
        ..._partyOptions.map((opt) {
          final isSelected = _selectedParty == opt['title'];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedParty = opt['title']!;
                });
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? context.primary : Colors.grey[200]!,
                    width: isSelected ? 1.5.w : 1.w,
                  ),
                  color: context.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title']!,
                            style: context.text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: context.onSurface,
                            ),
                          ),
                          4.h.height,
                          Text(
                            opt['subtitle']!,
                            style: context.text.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Step 2: Date Selection (Custom Calendar Grid) ---
  Widget _buildStep2Dates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When will your adventure begin and end? 📅',
          style: context.text.titleLarge?.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
        8.h.height,
        Text(
          'Choose the dates for your trip. This helps us plan the perfect itinerary for your travel period.',
          style: context.text.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        24.h.height,
        _buildCalendarMonth(
          'December 2023',
          12,
          2023,
          31,
          5,
        ), // Dec 2023 starts on Friday (5)
        24.h.height,
        _buildCalendarMonth(
          'January 2024',
          1,
          2024,
          31,
          1,
        ), // Jan 2024 starts on Monday (1)
      ],
    );
  }

  Widget _buildCalendarMonth(
    String monthTitle,
    int month,
    int year,
    int totalDays,
    int startWeekday,
  ) {
    final weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final blankDays = startWeekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthTitle,
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: context.onSurface,
          ),
        ),
        16.h.height,
        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdays.map((day) {
            return SizedBox(
              width: 38.w,
              child: Center(
                child: Text(
                  day,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        8.h.height,
        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 0,
          ),
          itemCount: totalDays + blankDays,
          itemBuilder: (context, index) {
            if (index < blankDays) {
              return const SizedBox.shrink();
            }

            final day = index - blankDays + 1;
            final currentDayDate = DateTime(year, month, day);

            // Determine Selection Style
            bool isSelectedStart =
                _startDate != null && _isSameDay(_startDate!, currentDayDate);
            bool isSelectedEnd =
                _endDate != null && _isSameDay(_endDate!, currentDayDate);
            bool isBetween =
                _startDate != null &&
                _endDate != null &&
                currentDayDate.isAfter(_startDate!) &&
                currentDayDate.isBefore(_endDate!);

            Color? cellColor;
            BorderRadius? borderRadius;
            TextStyle? textStyle = context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            );

            if (isSelectedStart) {
              cellColor = context.primary;
              borderRadius = BorderRadius.horizontal(
                left: Radius.circular(20.r),
              );
              textStyle = textStyle?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              );
            } else if (isSelectedEnd) {
              cellColor = context.primary;
              borderRadius = BorderRadius.horizontal(
                right: Radius.circular(20.r),
              );
              textStyle = textStyle?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              );
            } else if (isBetween) {
              cellColor = context.primary.withAlpha(40);
              textStyle = textStyle?.copyWith(
                color: context.primary,
                fontWeight: FontWeight.bold,
              );
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_startDate == null ||
                      (_startDate != null && _endDate != null)) {
                    _startDate = currentDayDate;
                    _endDate = null;
                  } else if (_startDate != null &&
                      currentDayDate.isBefore(_startDate!)) {
                    _startDate = currentDayDate;
                  } else {
                    _endDate = currentDayDate;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: borderRadius,
                  shape: (isSelectedStart && _endDate == null)
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                ),
                child: Center(child: Text(day.toString(), style: textStyle)),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // --- Step 3: Interests ---
  Widget _buildStep3Tastes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tailor your adventure to your tastes 🌟',
          style: context.text.titleLarge?.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
        8.h.height,
        Text(
          'Select your travel preferences to customize your trip plan.',
          style: context.text.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        24.h.height,
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _interestOptions.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                });
              },
              selectedColor: context.primary,
              checkmarkColor: Colors.white,
              labelStyle: context.text.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : context.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
              backgroundColor: context.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected ? context.primary : Colors.grey[300]!,
                  width: 1.w,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 4: Budget Selection ---
  Widget _buildStep4Budget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your trip budget 💰',
          style: context.text.titleLarge?.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: context.onSurface,
          ),
        ),
        8.h.height,
        Text(
          'Let us know your budget preference, and we\'ll craft an itinerary that suits your financial comfort.',
          style: context.text.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        24.h.height,
        ..._budgetOptions.map((opt) {
          final isSelected = _selectedBudget == opt['title'];
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedBudget = opt['title']!;
                });
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? context.primary : Colors.grey[200]!,
                    width: isSelected ? 1.5.w : 1.w,
                  ),
                  color: context.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title']!,
                            style: context.text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: context.onSurface,
                            ),
                          ),
                          4.h.height,
                          Text(
                            opt['subtitle']!,
                            style: context.text.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- Step 5: Review Summary ---
  Widget _buildStep5ReviewSummary() {
    final formattedDates = _startDate != null && _endDate != null
        ? "${_getMonthName(_startDate!.month)} ${_startDate!.day} to ${_getMonthName(_endDate!.month)} ${_endDate!.day}, ${_startDate!.year}"
        : 'Not selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destination Summary Card
        _buildSummaryItem(
          label: 'Destination',
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: widget.destination['imageUrl'] ?? '',
                  width: 60.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                ),
              ),
              12.w.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination['city'] ?? '',
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    4.h.height,
                    Text(
                      widget.destination['country'] ?? '',
                      style: context.text.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          onEdit: () =>
              setState(() => _currentStep = 0), // Jump to first or navigate
        ),
        16.h.height,

        // Party Summary Card
        _buildSummaryItem(
          label: 'Party',
          child: Text(
            _selectedParty,
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          onEdit: () => setState(() => _currentStep = 0),
        ),
        16.h.height,

        // Dates Summary Card
        _buildSummaryItem(
          label: 'Trip Dates',
          child: Text(
            formattedDates,
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          onEdit: () => setState(() => _currentStep = 1),
        ),
        16.h.height,

        // Interests Summary Card
        _buildSummaryItem(
          label: '${_selectedInterests.length} Interests',
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedInterests.map((interest) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  interest,
                  style: context.text.bodySmall?.copyWith(
                    color: context.onSurface,
                    fontSize: 12.sp,
                  ),
                ),
              );
            }).toList(),
          ),
          onEdit: () => setState(() => _currentStep = 2),
        ),
        16.h.height,

        // Budget Summary Card
        _buildSummaryItem(
          label: 'Budget',
          child: Text(
            _selectedBudget,
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15.sp,
            ),
          ),
          onEdit: () => setState(() => _currentStep = 3),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required Widget child,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: context.primary,
                  size: 18.sp,
                ),
                onPressed: onEdit,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          8.h.height,
          child,
        ],
      ),
    );
  }

  // --- Step 6: Generating Overlay Widget ---
  Widget _buildGeneratingOverlay() {
    return Container(
      color: Colors.black.withAlpha(150),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70.w,
                    height: 70.w,
                    child: CircularProgressIndicator(
                      value: _generationProgress / 100,
                      color: context.primary,
                      backgroundColor: Colors.grey[200],
                      strokeWidth: 6.w,
                    ),
                  ),
                  Text(
                    '$_generationProgress%',
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: context.onSurface,
                    ),
                  ),
                ],
              ),
              24.h.height,

              // Generating Text
              Text(
                'Generating Itinerary...',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: context.onSurface,
                ),
              ),
              12.h.height,

              // Description
              Text(
                'Please wait while our AI works its magic to create the perfect trip plan tailored to your preferences.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
