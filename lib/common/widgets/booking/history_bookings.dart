import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/bookings/models/booking_model.dart';

class ServiceHistoryCard extends StatelessWidget {
  final BookingModel booking;

  const ServiceHistoryCard({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
      child: InkWell(
        onTap: () {
          Get.toNamed('/service-history');
        },
        borderRadius: AppTheme.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Service icon/thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.button.withOpacity(0.1),
                  borderRadius: AppTheme.cardRadius,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.button,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Service details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed on ${DateFormat('MMMM d, yyyy').format(booking.bookingDate)}',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.button,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}