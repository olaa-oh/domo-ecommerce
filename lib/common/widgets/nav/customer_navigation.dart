// customer_navigation.dart
import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/features/bookings/views/bookings.dart';
import 'package:domo/features/home/views/customer_homepage.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/personalisation/views/you_page.dart';
import 'package:domo/features/favorites/views/favorite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({Key? key}) : super(key: key);

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 1;
  final userId = Get.find<AppRouter>().userId.value;
  final List<Widget> _pages = [
    const BookingsPage(),
     const CustomerHomepage(), 
     Wishlist(), 
  ];

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
      bottomNavigationBar: CustomerNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class CustomerNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomerNavBar({
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
          icon: Icon(Icons.bookmark_border_outlined),
          activeIcon: Icon(Icons.bookmark),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border_outlined),
          activeIcon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
      ],
    );
  }
}
