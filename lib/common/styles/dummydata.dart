import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:domo/features/shop/model/theme_model.dart';

class DummyData {
  static List<ThemesModel> themes = [
    ThemesModel(
        id: "1",
        name: "Home Services",
        image: "assets/images/theme/automobile.png",
        isFeatured: true,
        parentId: ""),
    ThemesModel(
        id: "2",
        name: "Personal Care",
        image: "assets/images/theme/care.png",
        isFeatured: true,
        parentId: ""),
    ThemesModel(
        id: "3",
        name: "Events & Occasions",
        image: "assets/images/theme/events.png",
        isFeatured: true,
        parentId: ""),
    ThemesModel(
        id: "4",
        name: "Construction",
        image: "assets/images/theme/construction.png",
        isFeatured: true,
        parentId: ""),
    ThemesModel(
        id: "5",
        name: "Automobile",
        image: "assets/images/theme/automobile.png",
        isFeatured: true,
        parentId: ""),
    ThemesModel(
        id: "6",
        name: "Fashion",
        image: "assets/images/theme/fashion.png",
        isFeatured: true,
        parentId: ""),
  ];

  static List<SubThemesModel> subThemes = [
    // subthnemes for Home Services
    SubThemesModel(id: "1", name: "Cleaning", themeId: "1"),
    SubThemesModel(id: "2", name: "Plumbing", themeId: "1"),
    SubThemesModel(id: "3", name: "Electricals", themeId: "1"),
    SubThemesModel(id: "4", name: "Carpentry", themeId: "1"),
    SubThemesModel(id: "5", name: "Painting", themeId: "1"),
    SubThemesModel(id: "6", name: "Gardening", themeId: "1"),
    SubThemesModel(id: "7", name: "Pest Control", themeId: "1"),
    SubThemesModel(id: "8", name: "Fumigation", themeId: "1"),

    // subthnemes for Personal Care
    SubThemesModel(id: "3", name: "Hairdressing", themeId: "2"),
    SubThemesModel(id: "4", name: "Barbing", themeId: "2"),
    SubThemesModel(id: "5", name: "Fitness Training", themeId: "2"),
    SubThemesModel(id: "6", name: "Yoga", themeId: "2"),
    SubThemesModel(id: "7", name: "Spa", themeId: "2"),
    SubThemesModel(id: "8", name: "Makeup", themeId: "2"),

    // subthnemes for Events & Occasions
    SubThemesModel(id: "9", name: "Wedding Planning", themeId: "3"),
    SubThemesModel(id: "10", name: "Event Decoration", themeId: "3"),
    SubThemesModel(id: "11", name: "Catering", themeId: "3"),
    SubThemesModel(id: "12", name: "Photography", themeId: "3"),
    SubThemesModel(id: "13", name: "Videography", themeId: "3"),
    SubThemesModel(id: "14", name: "MC", themeId: "3"),
    SubThemesModel(id: "15", name: "DJ", themeId: "3"),

    // subthnemes for Construction
    SubThemesModel(id: "16", name: "Building Construction", themeId: "4"),
    SubThemesModel(id: "17", name: "Road Construction", themeId: "4"),
    SubThemesModel(id: "18", name: "Bridge Construction", themeId: "4"),
    SubThemesModel(id: "19", name: "Drainage Construction", themeId: "4"),
    SubThemesModel(id: "20", name: "Roofing", themeId: "4"),
    SubThemesModel(id: "21", name: "Tiling", themeId: "4"),
    SubThemesModel(id: "22", name: "Plastering", themeId: "4"),

    // subthnemes for Automobile
    SubThemesModel(id: "23", name: "Car Wash", themeId: "5"),
    SubThemesModel(id: "24", name: "Car Repair", themeId: "5"),
    SubThemesModel(id: "25", name: "Car Painting", themeId: "5"),
    SubThemesModel(id: "26", name: "Car Upholstery", themeId: "5"),
    SubThemesModel(id: "27", name: "Car AC Repair", themeId: "5"),
    SubThemesModel(id: "28", name: "Car Electricals", themeId: "5"),
    SubThemesModel(id: "29", name: "Car Towing", themeId: "5"),

    // subthnemes for Fashion
    SubThemesModel(id: "30", name: "Tailoring", themeId: "6"),
    SubThemesModel(id: "31", name: "Shoe Making", themeId: "6"),
    SubThemesModel(id: "32", name: "Bag Making", themeId: "6"),
    SubThemesModel(id: "33", name: "Jewelry Making", themeId: "6"),
    SubThemesModel(id: "34", name: "Fashion Designing", themeId: "6"),
    SubThemesModel(id: "35", name: "Fashion Styling", themeId: "6"),
    SubThemesModel(id: "36", name: "Fashion Illustration", themeId: "6"),
  ];

  static List<ServicesModel> services = [
    ServicesModel(
      id: "1",
      serviceName: "Deep Cleaning",
      imageAsset: "deep_cleaning.png",
      subThemeId: "1",
      rating: 4.5,
      location: "Accra",
      price: 50,
      description: "Professional deep cleaning services for homes and offices.",
      isFeatured: true,
      shopId: "123",
    ),
    ServicesModel(
      id: "2",
      serviceName: "Pipe Repair",
      imageAsset: "pipe_repair.png",
      subThemeId: "2",
      rating: 4.0,
      location: "Kumasi",
      price: 30,
      description:
          "Expert pipe repair services for residential and commercial buildings.",
      isFeatured: false,
      shopId: "124",
    ),
    ServicesModel(
      id: "3",
      serviceName: "Hair Styling",
      imageAsset: "hair_styling.png",
      subThemeId: "3",
      rating: 5.0,
      location: "Tamale",
      price: 20,
      description: "Modern hair styling services for all occasions.",
      isFeatured: true,
      shopId: "125",
    ),
    ServicesModel(
      id: "4",
      serviceName: "Wedding Planning",
      imageAsset: "wedding_planning.png",
      subThemeId: "9",
      rating: 4.5,
      location: "Tema",
      price: 100.0,
      description:
          "Professional wedding planning services for all types of weddings.",
      isFeatured: false,
      shopId: "126",
    ),
    ServicesModel(
      id: "5",
      serviceName: "Building Construction",
      imageAsset: "building_construction.png",
      subThemeId: "16",
      rating: 4.0,
      location: "Koforidua",
      price: 500,
      description:
          "Expert building construction services for residential and commercial buildings.",
      isFeatured: true,
      shopId: "127",
    ),
    ServicesModel(
      id: "6",
      serviceName: "Car Wash",
      imageAsset: "car_wash.png",
      subThemeId: "23",
      rating: 5.0,
      location: "Ho",
      price: 10,
      description: "Professional car wash services for all types of cars.",
      isFeatured: false,
      shopId: "128",
    ),
    ServicesModel(
      id: "7",
      serviceName: "Tailoring",
      imageAsset: "tailoring.png",
      subThemeId: "30",
      rating: 4.5,
      location: "Sunyani",
      price: 40,
      description: "Expert tailoring services for all types of clothing.",
      isFeatured: true,
      shopId: "129",
    ),
    //  services for Personal Care
    ServicesModel(
      id: "8",
      serviceName: "Hairdressing",
      imageAsset: "hairdressing.png",
      subThemeId: "3",
      rating: 4.5,
      location: "Accra",
      price: 50,
      description: "Professional hairdressing services for all occasions.",
      isFeatured: true,
      shopId: "123",
    ),
  ];
}
