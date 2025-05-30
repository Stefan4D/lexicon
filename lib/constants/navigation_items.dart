import 'package:flutter/material.dart';
import 'package:lexicon/models/navigation_item.dart'; // Corrected import path

import 'package:lexicon/screens/all_projects_screen.dart'; // Corrected import path
import 'package:lexicon/screens/home_screen.dart'; // Corrected import path
import 'package:lexicon/screens/settings_screen.dart'; // Added import for SettingsScreen

final List<NavigationItem> navigationItems = [
  NavigationItem(
    label: 'Home',
    icon: Icons.home,
    page: const HomeScreen(),
  ), // Added const
  NavigationItem(
    label: 'All Projects',
    icon: Icons.list,
    page: const AllProjectsScreen(), // Added const
  ),
  NavigationItem(
    label: 'Settings',
    icon: Icons.settings,
    page: const SettingsScreen(), // Added SettingsScreen
  ),
];
