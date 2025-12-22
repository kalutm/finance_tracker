import 'package:finance_frontend/features/accounts/presentation/views/accounts_wrapper.dart';
import 'package:finance_frontend/features/auth/presentation/components/confirmation_dialog.dart';
import 'package:finance_frontend/features/categories/presentation/views/categories_wrapper.dart';
import 'package:finance_frontend/features/settings/presentation/views/settings_view.dart';
import 'package:finance_frontend/features/transactions/presentation/views/report_and_anlytics_wrapper.dart';
import 'package:finance_frontend/features/transactions/presentation/views/transactions_view.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // 0: Transactions (Default), 1: Accounts, 2: Categories, 3: Settings
  int _selectedIndex = 0;

  // Mapping to hold our navigation destinations
  static final List<Widget> _widgetOptions = <Widget>[
    const TransactionsView(),
    const AccountsWrapper(),
    const CategoriesWrapper(),
    const Reportandanlyticswrappr(),
    const SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close the drawer after selection
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The main Scaffold now contains only the current selected page
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),

      body: _widgetOptions.elementAt(_selectedIndex),


      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Finance Tracker',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List Items
            _buildDrawerItem(
              context,
              title: 'Transactions',
              icon: Icons.receipt_long_rounded,
              index: 0,
              onTap: _onItemTapped,
            ),
            _buildDrawerItem(
              context,
              title: 'Accounts',
              icon: Icons.account_balance_rounded,
              index: 1,
              onTap: _onItemTapped,
            ),
            _buildDrawerItem(
              context,
              title: 'Categories',
              icon: Icons.category_rounded,
              index: 2,
              onTap: _onItemTapped,
            ),
            _buildDrawerItem(
              context,
              title: 'Report & Analytics',
              icon: Icons.pie_chart_outline_rounded,
              index: 3,
              onTap: _onItemTapped,
            ),
            _buildDrawerItem(
              context,
              title: 'Settings',
              icon: Icons.settings_rounded,
              index: 4,
              onTap: _onItemTapped,
            ),

            const Spacer(),

            // Logout and Delete at the bottom
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              title: Text('Logout', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                showDialog(
                    context: context,
                    builder:
                        (context) => ConfirmationDialog(
                          title: "Log out",
                          content:
                              "Are you sure that you want to log out",
                          isDelete: false,
                        ),
                  );
              },
            ),
            ListTile(
              leading: Icon(
               Icons.delete_forever, color: Colors.red
              ),
              title: Text('Delete Account', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                showDialog(
                    context: context,
                    builder:
                        (context) => ConfirmationDialog(
                          title: "Delete Account",
                          content:
                              "Are you sure you want to delete your account? This cannot be undone.",
                          isDelete: true,
                        ),
                  );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper function for clean drawer items
  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
    required Function(int) onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color:
            isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(204),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withAlpha(25),
      onTap: () => onTap(index),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Transactions';
      case 1:
        return 'Accounts';
      case 2:
        return 'Categories';
      case 3:
        return "Report & Analytics";
      case 4:
        return "Settings";
      default:
        return 'Finance Tracker';
    }
  }
}
