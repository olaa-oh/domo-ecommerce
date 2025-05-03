import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/booking/booking_artisan_card.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AppointmentPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const AppointmentPage({
    Key? key, 
    required this.shopId, 
    required this.shopName
  }) : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  late BookingsController _bookingsController;
  late Future<List<BookingModel>> _bookingsFuture;
  
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
  List<BookingModel> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _bookingsController = Get.put(BookingsController());
    _fetchBookings();
    
    // Listen to search query changes
    _searchController.addListener(() {
      _searchQuery.value = _searchController.text.toLowerCase();
      setState(() {}); // Refresh UI when search query changes
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


    Future<List<BookingModel>> _fetchBookings() {
      setState(() {
        _bookingsFuture = _bookingsController.fetchBookingsForShop(widget.shopId);
      });
      
      // Store fetched bookings for filtering
      _bookingsFuture.then((bookings) {
        setState(() {
          _allBookings = bookings;
          _organizeBookingsByDate();
        });
      });
      
      return _bookingsFuture;
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
    List<BookingModel> filteredList = _allBookings;
    
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
      return RefreshIndicator(
        onRefresh: _fetchBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: Text(
                _searchQuery.value.isNotEmpty
                  ? 'No bookings match your search'
                  : _selectedDay != null
                    ? 'No bookings on ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'
                    : 'No bookings found',
                style: AppTheme().light.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppTheme.screenPadding,
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return BookingCard(
            booking: bookings[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings for ${widget.shopName}',
          style: AppTheme().light.textTheme.headlineSmall,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
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
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading bookings',
                    style: AppTheme().light.textTheme.bodyLarge?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchBookings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          _allBookings = snapshot.data ?? [];
          
          if (_allBookings.isEmpty) {
            return RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Center(
                    child: Text(
                      'No bookings found',
                      style: AppTheme().light.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
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
        },
      ),
    );
  }
}