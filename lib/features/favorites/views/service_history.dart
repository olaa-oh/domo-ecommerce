import 'package:domo/common/styles/style.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  late BookingModel booking;
  final bookingsController = Get.find<BookingsController>();
  final serviceController = Get.find<ServiceController>();
  bool isLoading = true;
  ServicesModel? service;
  String paymentMethod = 'Cash'; // Default value, you can fetch the actual value from your database
  
  @override
  void initState() {
    super.initState();
    booking = Get.arguments as BookingModel;
    _loadServiceDetails();
  }
  
  Future<void> _loadServiceDetails() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Fetch the service details
      if (booking.serviceId.isNotEmpty) {
        service = await serviceController.fetchServiceById(booking.serviceId);
      }
    } catch (e) {
      print('Error loading service details: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Service History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.button),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServiceHeader(),
                  const SizedBox(height: 24),
                  _buildDetailsSection(),
                  const SizedBox(height: 24),
                  _buildReviewSection(),
                  const SizedBox(height: 32),
                  _buildPrintButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: service != null && service!.imageAsset.isNotEmpty
                ? Image.network(
                    service!.imageAsset,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.handyman, size: 50, color: Colors.grey[400]),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          
          // Service Name and Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildRatingIndicator(booking.rating ?? 0),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Completion Date
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Completed on ${DateFormat('MMMM d, yyyy').format(booking.bookingDate)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.button,
            ),
          ),
          const SizedBox(height: 16),
          
          // Price
          _buildDetailRow(
            icon: Icons.attach_money,
            title: 'Price',
            value: '\$${booking.price.toStringAsFixed(2)}',
          ),
          const Divider(),
          
          // Payment Method
          _buildDetailRow(
            icon: Icons.payment,
            title: 'Payment Method',
            value: paymentMethod,
          ),
          const Divider(),
          
          // Location
          _buildDetailRow(
            icon: Icons.location_on,
            title: 'Location',
            value: service?.location ?? 'Not available',
          ),
          const Divider(),
          
          // Shop Name
          _buildDetailRow(
            icon: Icons.store,
            title: 'Service Provider',
            value: service?.serviceName ?? 'Not available',
          ),
          
          // Notes if any
          if (booking.notes.isNotEmpty) ...[
            const Divider(),
            _buildDetailRow(
              icon: Icons.note,
              title: 'Notes',
              value: booking.notes,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.button,
            ),
          ),
          const SizedBox(height: 16),
          
          // Rating
          Row(
            children: [
              const Text(
                'Rating:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              _buildRatingIndicator(booking.rating ?? 0),
            ],
          ),
          const SizedBox(height: 16),
          
          // Review Text
          if (booking.review != null && booking.review!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.review!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No review provided',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _printReceipt(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.button,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.print),
        label: const Text(
          'Print Receipt',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRatingIndicator(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 18,
        );
      }),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt() async {
    final pdf = pw.Document();

    final serviceImage = service != null && service!.imageAsset.isNotEmpty
        ? await networkImage(service!.imageAsset)
            .catchError((error) => null)
        : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'SERVICE RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Company logo or image placeholder
                if (serviceImage != null)
                  pw.Center(
                    child: pw.Image(
                      serviceImage,
                      width: 150,
                      height: 100,
                      fit: pw.BoxFit.cover,
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Container(
                      width: 150,
                      height: 100,
                      color: PdfColors.grey300,
                      child: pw.Center(
                        child: pw.Text(
                          'No Image',
                          style: pw.TextStyle(color: PdfColors.grey700),
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 20),
                
                // Receipt details
                pw.Divider(),
                _buildPdfDetailRow('Service', booking.serviceName),
                _buildPdfDetailRow('Date', DateFormat('MMMM d, yyyy').format(booking.bookingDate)),
                _buildPdfDetailRow('Amount Paid', '\$${booking.price.toStringAsFixed(2)}'),
                _buildPdfDetailRow('Payment Method', paymentMethod),
                _buildPdfDetailRow('Location', service?.location ?? 'Not available'),
                if (booking.notes.isNotEmpty)
                  _buildPdfDetailRow('Notes', booking.notes),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // Thank you note
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: const pw.TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'For any inquiries, please contact us.',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfDetailRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
}