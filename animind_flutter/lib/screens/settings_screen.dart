import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyController;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _keyController = TextEditingController(text: appState.apiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    await context.read<AppState>().setApiKey(_keyController.text);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear API Key'),
        content: const Text('Remove your stored API key?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _keyController.clear();
      await context.read<AppState>().setApiKey('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Key section
          _buildCard(
            children: [
              const Text(
                'Gemini API Key',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Required for Pixel to talk. Get a free key from Google AI Studio.',
                style: TextStyle(fontSize: 13, color: Color(0xFFA0896C), height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _keyController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'Paste your API key here...',
                  hintStyle: const TextStyle(color: Color(0xFF999999)),
                  filled: true,
                  fillColor: const Color(0xFFF5F0E6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _saveKey,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _saved ? const Color(0xFF4CAF50) : const Color(0xFF7C4DFF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(_saved ? 'Saved!' : 'Save Key'),
                  ),
                  if (appState.apiKey.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _clearKey,
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  // Can't open URL without url_launcher, show a snackbar instead
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visit https://aistudio.google.com/apikey'),
                    ),
                  );
                },
                child: const Text(
                  'Get a free API key →',
                  style: TextStyle(
                    color: Color(0xFF7C4DFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status section
          _buildCard(
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 10),
              _buildStatusRow(
                'API Key',
                appState.apiKey.isNotEmpty ? 'Configured' : 'Not set',
                isOk: appState.apiKey.isNotEmpty,
              ),
              const Divider(color: Color(0xFFF5F0E6)),
              _buildStatusRow('Days together', '${appState.dayCount}'),
            ],
          ),
          const SizedBox(height: 16),

          // About section
          _buildCard(
            children: [
              const Text(
                'About AniMind',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D4037),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'AniMind is a virtual pet that remembers everything you tell it. '
                'Memories are stored locally on your device and never leave it.\n\n'
                'Conversations are powered by Google\'s Gemini Flash API. '
                'Your messages are sent to the API for processing but are not stored by Google.\n\n'
                'Built with Flutter + sqflite + Gemini.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text(
              'AniMind v1.0.0 — Prototype',
              style: TextStyle(fontSize: 12, color: Color(0xFFC0A888)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool? isOk}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037)),
            ),
          ),
          if (isOk != null)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOk ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFA0896C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
