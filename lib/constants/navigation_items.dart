import 'package:flutter/material.dart';
import '/models/navigation_item.dart';

import '/screens/all_projects_screen.dart';
import '/screens/project_screen.dart';
import '/screens/home_screen.dart';

final List<NavigationItem> navigationItems = [
  NavigationItem(label: 'Home', icon: Icons.home, page: HomeScreen()),
  NavigationItem(
    label: 'All Projects',
    icon: Icons.list,
    page: AllProjectsScreen(),
  ),
  NavigationItem(label: 'Project', icon: Icons.book, page: ProjectScreen()),
];
