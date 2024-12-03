import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/booking/booking_confirmatiom.dart';
import 'package:domo/common/widgets/booking/customer_complete_widget.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:domo/features/bookings/models/booking_model.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final BookingsController _bookingsController = Get.put(BookingsController());

  @override
  void initState() {
    super.initState();
    // Fetch user bookings when page loads
    _bookingsController.fetchUserBookings();
  }

  // Method to show date picker for booking update
  Future<void> _showDateTimePicker(BuildContext context, BookingModel booking) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: booking.bookingDate,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.button,
      appBar: AppBar(
        title:  Text('My Bookings',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.button,
          ),
        ),
      ),
      body: Obx(() {
        // Show loading indicator while fetching bookings
        if (_bookingsController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_bookingsController.userBookings.isEmpty) {
          return const Center(
            child: Text('No bookings found'),
          );
        }

        // List of bookings
        return ListView.builder(
          padding: AppTheme.screenPadding,
          itemCount: _bookingsController.userBookings.length,
          itemBuilder: (context, index) {
            final booking = _bookingsController.userBookings[index];
            
            return FutureBuilder<ServicesModel?>(
              future: Get.find<ServiceController>().fetchServiceById(booking.serviceId),
              builder: (context, serviceSnapshot) {
                if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                if (!serviceSnapshot.hasData || serviceSnapshot.data == null) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'Service Unavailable', 
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
                                builder: (context) => CustomerBookingCompletionWidget(booking: booking)
                              );
                              break;
                            case 'shop_confirm_completion':
                              showDialog(
                                context: context, 
                                builder: (context) => ShopBookingCompletionConfirmationWidget(booking: booking)
                              );
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          // Existing update and cancel options for pending bookings
                          if (booking.status == 'pending')
                            const PopupMenuItem<String>(
                              value: 'update',
                              child: Text('Update Booking'),
                            ),
                          if (booking.status == 'pending')
                            const PopupMenuItem<String>(
                              value: 'cancel',
                              child: Text('Cancel Booking'),
                            ),
                          
                          // Customer: Initiate completion for accepted bookings
                          if (booking.status == 'accepted')
                            const PopupMenuItem<String>(
                              value: 'customer_complete',
                              child: Text('Complete Booking'),
                            ),
                          
                          // Shop: Confirm completion for completion_initiated bookings
                          if (booking.status == 'completion_initiated')
                            const PopupMenuItem<String>(
                              value: 'shop_confirm_completion',
                              child: Text('Confirm Completion'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final service = serviceSnapshot.data!;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      service.serviceName, // Use service name instead of serviceId
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
                              builder: (context) => CustomerBookingCompletionWidget(booking: booking)
                            );
                            break;
                          case 'shop_confirm_completion':
                            showDialog(
                              context: context, 
                              builder: (context) => ShopBookingCompletionConfirmationWidget(booking: booking)
                            );
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        // Existing update and cancel options for pending bookings
                        if (booking.status == 'pending')
                          const PopupMenuItem<String>(
                            value: 'update',
                            child: Text('Update Booking'),
                          ),
                        if (booking.status == 'pending')
                          const PopupMenuItem<String>(
                            value: 'cancel',
                            child: Text('Cancel Booking'),
                          ),
                        
                        // Customer: Initiate completion for accepted bookings
                        if (booking.status == 'accepted')
                          const PopupMenuItem<String>(
                            value: 'customer_complete',
                            child: Text('Complete Booking'),
                          ),
                        
                        // Shop: Confirm completion for completion_initiated bookings
                        if (booking.status == 'completion_initiated')
                          const PopupMenuItem<String>(
                            value: 'shop_confirm_completion',
                            child: Text('Confirm Completion'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}