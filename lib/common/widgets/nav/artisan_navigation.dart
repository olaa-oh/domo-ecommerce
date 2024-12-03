// Artisan_navigation.dart
import 'package:domo/features/bookings/views/appointments.dart';
import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/services/views/artisan_dashboard.dart';
import 'package:domo/features/personalisation/views/artisan_homepage.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/personalisation/views/you_page.dart';
import 'package:domo/features/shop/controller/shop_onboarding_controller.dart';
import 'package:flutter/material.dart';

class ArtisanMainScreen extends StatefulWidget {
  const ArtisanMainScreen({Key? key}) : super(key: key);

  @override
  State<ArtisanMainScreen> createState() => _ArtisanMainScreenState();
}

class _ArtisanMainScreenState extends State<ArtisanMainScreen> {
  int _selectedIndex = 1;
  late List<Widget> _pages;


  @override
  void initState() {
    super.initState();
    
    ShopOnboardingController shopController = ShopOnboardingController();
    
    shopController.getShopId().then((shopId) {
      shopController.getShopName().then((shopName) {
        setState(() {
          _pages = [
            AppointmentPage(
              shopId: shopId ?? '',
              shopName: shopName ?? 'My Shop',
            ), 
            const ArtisanHomepage(), 
            ArtisanDashboard(shopId: shopId ?? ''), 
          ];
        });
      });
    });

    _pages = [
      const SizedBox(), 
      const ArtisanHomepage(), 
      const SizedBox(), 
    ];
  }
  


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ArtisanNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class ArtisanNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const ArtisanNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: AppTheme.button,
      unselectedItemColor: AppTheme.darkBackground,
      selectedLabelStyle: AppTheme.textTheme.labelMedium,
      unselectedLabelStyle: AppTheme.textTheme.labelMedium,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ],
    );
  }
}