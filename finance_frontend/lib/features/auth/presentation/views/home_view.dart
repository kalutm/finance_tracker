import 'package:finance_frontend/features/accounts/presentation/views/accounts_wrapper.dart';
import 'package:finance_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:finance_frontend/features/categories/presentation/views/categories_wrapper.dart';
import 'package:finance_frontend/features/settings/presentation/views/settings_view.dart';
import 'package:finance_frontend/features/transactions/presentation/views/transactions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    const TransactionsView(), // This is where the feed goes
    const AccountsWrapper(),
    const CategoriesWrapper(),
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
        // Title is dynamic based on selected index
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onPrimary),
        ),
        // Simplified actions bar
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'Log Out',
            onPressed: () => context.read<AuthCubit>().logOut(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete_user') {
                 context.read<AuthCubit>().deleteCurrentUser();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_user',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      // Dynamic Body Content
      body: _widgetOptions.elementAt(_selectedIndex),

      // Refactored Drawer
      drawer: Drawer(
        child: Column(
          children: [
            // User-friendly Drawer Header 
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'Finance Tracker',
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary),
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
              onTap: _onItemTapped
            ),
            _buildDrawerItem(
              context, 
              title: 'Accounts', 
              icon: Icons.account_balance_rounded, 
              index: 1, 
              onTap: _onItemTapped
            ),
            _buildDrawerItem(
              context, 
              title: 'Categories', 
              icon: Icons.category_rounded, 
              index: 2, 
              onTap: _onItemTapped
            ),
            _buildDrawerItem(
              context, 
              title: 'Settings', 
              icon: Icons.settings_rounded, 
              index: 3, 
              onTap: _onItemTapped
            ),
            
            const Spacer(),
            
            // Logout at the bottom
            ListTile(
              leading: Icon(Icons.logout_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              title: Text('Logout', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                context.read<AuthCubit>().logOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper function for clean drawer items
  Widget _buildDrawerItem(BuildContext context, {required String title, required IconData icon, required int index, required Function(int) onTap}) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon, 
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.8)
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      onTap: () => onTap(index),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Transactions';
      case 1: return 'Accounts Overview';
      case 2: return 'Categories';
      case 3: return 'Settings';
      default: return 'Finance Tracker';
    }
  }
}