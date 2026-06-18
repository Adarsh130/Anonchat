import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Mock settings states
  bool _allowDirectWhispers = true;
  bool _showOnlinePresence = true;
  bool _filterToxicLanguage = true;
  bool _notifyWhispers = true;
  bool _notifyUpvotes = true;
  String _selectedTheme = 'Pitch Black';

  void _purgeCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.online,
        content: Text('Local voice files and decryption caches successfully purged!'),
      ),
    );
  }

  void _showDeleteAccountConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Session?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This action will permanently delete your anonymous ID and conversation logs from the device. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.error)),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close settings
              ref.read(authControllerProvider.notifier).signOut(); // sign out completely
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // Section 1: Privacy Controls
            _buildSectionHeader('PRIVACY CONTROLS'),
            const SizedBox(height: 12),
            Container(
              decoration: AppColors.glassDecoration(borderRadius: 20),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Allow Direct Whispers',
                    'Allows strangers to start private chat with you from swipe matched feeds.',
                    _allowDirectWhispers,
                    (val) => setState(() => _allowDirectWhispers = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'Show Online Presence',
                    'Exposes your online status indicator dot to matching algorithms.',
                    _showOnlinePresence,
                    (val) => setState(() => _showOnlinePresence = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'Toxic Language Filter',
                    'Automatically flags and masks aggressive words in conversation logs.',
                    _filterToxicLanguage,
                    (val) => setState(() => _filterToxicLanguage = val),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // Section 2: Notifications settings
            _buildSectionHeader('NOTIFICATION TARGETS'),
            const SizedBox(height: 12),
            Container(
              decoration: AppColors.glassDecoration(borderRadius: 20),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Private Whispers',
                    'Vibrate on incoming stranger requests.',
                    _notifyWhispers,
                    (val) => setState(() => _notifyWhispers = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'Feed Upvotes',
                    'Notify when your posted confessions get upvoted.',
                    _notifyUpvotes,
                    (val) => setState(() => _notifyUpvotes = val),
                  ),
                ],
              ),
            ).animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // Section 3: Theme customizer
            _buildSectionHeader('THEME CUSTOMIZATION'),
            const SizedBox(height: 12),
            Container(
              decoration: AppColors.glassDecoration(borderRadius: 20),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Interface Accent', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: Text(_selectedTheme, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    trailing: const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      _showThemeSelectDialog();
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    title: const Text('Blocked Users', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text('0 profiles blacklisted', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    trailing: const Icon(Icons.block_flipped, color: AppColors.textSecondary, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: AppColors.surface, content: Text('Blocked list is empty.')),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fade(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 36),

            // Section 4: Critical Account Management
            _buildSectionHeader('ACCOUNT & CACHE'),
            const SizedBox(height: 12),
            Container(
              decoration: AppColors.glassDecoration(borderRadius: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.secondary, size: 20),
                    title: const Text('Purge Local Cache', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text('Clears voice logs & image caches.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    onTap: _purgeCache,
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                    title: const Text('Delete Anonymous Session', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: const Text('Irreversibly wipes your current profile.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    onTap: _showDeleteAccountConfirm,
                  ),
                ],
              ),
            ).animate().fade(delay: 450.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool val, ValueChanged<bool> onChange) {
    return SwitchListTile(
      value: val,
      onChanged: onChange,
      activeThumbColor: AppColors.secondary,
      activeTrackColor: AppColors.secondary.withValues(alpha: 0.3),
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: AppColors.background,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.5)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.border, height: 1, thickness: 1);
  }

  void _showThemeSelectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Theme', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pitch Black', 'Cyber Violet', 'Electric Cyan'].map((theme) {
            final isSelected = _selectedTheme == theme;
            return ListTile(
              title: Text(theme, style: TextStyle(
                color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary) : null,
              onTap: () {
                setState(() {
                  _selectedTheme = theme;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
