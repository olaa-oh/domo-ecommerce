import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/booking/booking_confirmatiom.dart';
import 'package:domo/common/widgets/booking/booking_review.dart';
import 'package:domo/common/widgets/booking/customer_complete_widget.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/reviews/controllers/review_controller.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final BookingsController _bookingsController = Get.put(BookingsController());
  final Map<String, bool> _reviewStatusCache = {};
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;

  // Calendar variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // View toggle variable
  bool _showCalendarView = false;

  // Filter variables
  final Map<DateTime, List<BookingModel>> _bookingsByDate = {};

  @override
  void initState() {
    super.initState();
    _bookingsController.fetchUserBookings();
    
    // Listen to search query changes
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Organize bookings by date for calendar view
  void _organizeBookingsByDate() {
    _bookingsByDate.clear();

    for (var booking in _getFilteredBookings()) {
      final bookingDateOnly = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
      );

      if (_bookingsByDate[bookingDateOnly] == null) {
        _bookingsByDate[bookingDateOnly] = [];
      }

      _bookingsByDate[bookingDateOnly]!.add(booking);
    }
  }

  // Filter bookings based on search query, date selection, etc.
  List<BookingModel> _getFilteredBookings() {
    List<BookingModel> filteredList = _bookingsController.userBookings;
    
    // Filter by selected day if in calendar view
    if (_selectedDay != null) {
      filteredList = filteredList.where((booking) {
        return booking.bookingDate.year == _selectedDay!.year &&
            booking.bookingDate.month == _selectedDay!.month &&
            booking.bookingDate.day == _selectedDay!.day;
      }).toList();
    }
    
    // Filter by search query if not empty
    if (_searchQuery.value.isNotEmpty) {
      filteredList = filteredList.where((booking) {
        // Search by service name
        final serviceNameMatch = booking.serviceName.toLowerCase().contains(_searchQuery.value);
        
        // Search by status
        final statusMatch = booking.status.toLowerCase().contains(_searchQuery.value);
        
        return serviceNameMatch || statusMatch;
      }).toList();
    }
    
    return filteredList;
  }

  // Method to show date picker for booking update
Future<void> _showDateTimePicker(
    BuildContext context, BookingModel booking) async {
  // Create a safe initial date that is guaranteed to be valid
  final DateTime safeInitialDate = booking.bookingDate.isBefore(DateTime.now())
      ? DateTime.now()
      : booking.bookingDate;

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: safeInitialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  if (pickedDate != null) {
    // Show time picker after date is selected
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(booking.bookingDate),
    );

    if (pickedTime != null) {
      // Combine date and time
      final DateTime newBookingDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Update booking date
      _bookingsController.updateBookingDate(
        bookingId: booking.id,
        newBookingDate: newBookingDateTime,
      );
    }
  }
}
  

  // Method to show the review dialog for completed bookings
  void _showReviewDialog(BuildContext context, BookingModel booking) async {
    final reviewController = Get.find<ReviewController>();
    final existingReview =
        await reviewController.getReviewForBooking(booking.id);

    showDialog(
      context: context,
      builder: (context) => BookingReviewWidget(
        booking: booking,
        existingReview: existingReview,
      ),
    );
  }

  // Method to check if a booking has been reviewed
  Future<bool> _hasBookingBeenReviewed(String bookingId) async {
    // Check cache first
    if (_reviewStatusCache.containsKey(bookingId)) {
      return _reviewStatusCache[bookingId]!;
    }

    // If not in cache, fetch the status
    final reviewController = Get.put(ReviewController());
    final hasReview = await reviewController.hasBookingBeenReviewed(bookingId);

    // Cache the result
    _reviewStatusCache[bookingId] = hasReview;

    return hasReview;
  }

  // Build popup menu items for a booking
  List<PopupMenuEntry<String>> _buildPopupMenuItems(BookingModel booking) {
    List<PopupMenuEntry<String>> menuItems = [];

    // Add options based on booking status
    if (booking.status == 'pending') {
      menuItems.add(const PopupMenuItem<String>(
        value: 'update',
        child: Text('Update Booking'),
      ));

      menuItems.add(const PopupMenuItem<String>(
        value: 'cancel',
        child: Text('Cancel Booking'),
      ));
    }

    if (booking.status == 'accepted') {
      menuItems.add(const PopupMenuItem<String>(
        value: 'customer_complete',
        child: Text('Complete Booking'),
      ));
    }

    if (booking.status == 'completion_initiated') {
      menuItems.add(const PopupMenuItem<String>(
        value: 'shop_confirm_completion',
        child: Text('Confirm Completion'),
      ));
    }

    // For completed bookings, check review status and add appropriate option
    if (booking.status == 'completed') {
      // Check if there's a cached status
      if (_reviewStatusCache.containsKey(booking.id)) {
        final hasReview = _reviewStatusCache[booking.id]!;
        menuItems.add(PopupMenuItem<String>(
          value: 'review',
          child: Text(hasReview ? 'Edit Review' : 'Leave Review'),
        ));
      } else {
        // Add a placeholder that will be replaced when review status is known
        menuItems.add(const PopupMenuItem<String>(
          enabled: false,
          value: 'checking',
          child: Text('Checking review status...'),
        ));

        // Fetch the review status asynchronously and update the UI when complete
        _hasBookingBeenReviewed(booking.id).then((hasReview) {
          if (mounted) {
            setState(() {
              // The setState will trigger a rebuild with the updated cache
            });
          }
        });
      }
    }

    return menuItems;
  }

  // Build search bar widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.button.withOpacity(0.1),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search services or status...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.button),
          suffixIcon: Obx(() => _searchQuery.value.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.button),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : const SizedBox.shrink()
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    _organizeBookingsByDate();

    return Column(
      children: [
        _buildSearchBar(),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              final dateOnly = DateTime(day.year, day.month, day.day);
              return _bookingsByDate[dateOnly] ?? [];
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: AppTheme.button,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.button.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.button,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonTextStyle: TextStyle(color: AppTheme.button),
              titleCentered: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildBookingsList(_getFilteredBookings()),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.value.isNotEmpty
              ? 'No bookings match your search'
              : _selectedDay != null
                  ? 'No bookings on ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'
                  : 'No bookings found',
          style: AppTheme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: AppTheme.screenPadding,
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        return FutureBuilder<ServicesModel?>(
          future:
              Get.find<ServiceController>().fetchServiceById(booking.serviceId),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }

            if (!serviceSnapshot.hasData || serviceSnapshot.data == null) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    booking.serviceName,
                    style: AppTheme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy HH:mm').format(booking.bookingDate)}',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                      Text(
                        'Status: ${booking.status}',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'update':
                          _showDateTimePicker(context, booking);
                          break;
                        case 'cancel':
                          _bookingsController.cancelBooking(booking.id);
                          break;
                        case 'customer_complete':
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  CustomerBookingCompletionWidget(
                                      booking: booking));
                          break;
                        case 'shop_confirm_completion':
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  ShopBookingCompletionConfirmationWidget(
                                      booking: booking));
                          break;
                        case 'review':
                          _showReviewDialog(context, booking);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        _buildPopupMenuItems(booking),
                  ),
                ),
              );
            }

            final service = serviceSnapshot.data!;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  service.serviceName,
                  style: AppTheme.textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy HH:mm').format(booking.bookingDate)}',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                    Text(
                      'Status: ${booking.status}',
                      style: AppTheme.textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'update':
                        _showDateTimePicker(context, booking);
                        break;
                      case 'cancel':
                        _bookingsController.cancelBooking(booking.id);
                        break;
                      case 'customer_complete':
                        showDialog(
                            context: context,
                            builder: (context) =>
                                CustomerBookingCompletionWidget(
                                    booking: booking));
                        break;
                      case 'shop_confirm_completion':
                        showDialog(
                            context: context,
                            builder: (context) =>
                                ShopBookingCompletionConfirmationWidget(
                                    booking: booking));
                        break;
                      case 'review':
                        _showReviewDialog(context, booking);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      _buildPopupMenuItems(booking),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.button,
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.button,
          ),
        ),
        actions: [
          // Toggle view icon
          IconButton(
            icon: Icon(_showCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _showCalendarView = !_showCalendarView;
                // Clear selected day when switching views
                if (!_showCalendarView) {
                  _selectedDay = null;
                }
              });
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_bookingsController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_bookingsController.userBookings.isEmpty) {
          return const Center(
            child: Text('No bookings found'),
          );
        }

        return Column(
          children: [
            // Only show search bar when not in calendar view or when explicitly searching
            if (!_showCalendarView || _isSearching.value)
              _buildSearchBar(),
            
            // Show either calendar view or list view based on toggle
            Expanded(
              child: _showCalendarView
                  ? _buildCalendarView()
                  : _buildBookingsList(_getFilteredBookings()),
            ),
          ],
        );
      }),
    );
  }
}