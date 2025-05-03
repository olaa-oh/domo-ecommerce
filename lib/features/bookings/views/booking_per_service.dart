import 'package:domo/common/widgets/booking/booking_artisan_card.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/models/booking_model.dart';

class BookingPerService extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const BookingPerService({
    Key? key, 
    required this.serviceId, 
    required this.serviceName
  }) : super(key: key);

  @override
  _BookingPerService createState() => _BookingPerService();
}

class _BookingPerService extends State<BookingPerService> {
  final BookingsController _bookingsController = Get.put(BookingsController());
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _bookingsController.fetchBookingsForService(widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings for ${widget.serviceName}'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No bookings found for this service',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return BookingCard(
                  booking: booking,
                );
              },
            );
          }
        },
      ),
    );
  }
}   