import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/booking/booking_artisan_card.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _bookingsController = Get.put(BookingsController());
    _fetchBookings();
  }

  Future<void> _fetchBookings() {
    setState(() {
      _bookingsFuture = _bookingsController.fetchBookingsForShop(widget.shopId);
    });
    return _bookingsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookings',
          style: AppTheme().light.textTheme.headlineSmall,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        child: FutureBuilder<List<BookingModel>>(
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

            final bookings = snapshot.data ?? [];

            if (bookings.isEmpty) {
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

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppTheme.screenPadding,
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return BookingCard(
                  booking: bookings[index],
                  serviceName: bookings[index].serviceName ?? 'Unknown Service',
                );
              },
            );
          },
        ),
      ),
    );
  }
}