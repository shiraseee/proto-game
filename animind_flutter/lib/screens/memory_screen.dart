import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memory.dart';
import '../services/database_service.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> with AutomaticKeepAliveClientMixin {
  List<Memory> _memories = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final mems = await DatabaseService.getAllMemories();
    if (mounted) setState(() => _memories = mems);
  }

  Future<void> _deleteMemory(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Memory'),
        content: const Text('Remove this memory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.deleteMemory(id);
      _loadMemories();
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Memories'),
        content: const Text('This will erase everything Pixel knows about you. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.clearAllMemories();
      _loadMemories();
    }
  }

  String _formatDate(String timestamp) {
    final dt = DateTime.parse(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _importanceBar(double score) {
    final filled = (score * 5).round();
    return '●' * filled + '○' * (5 - filled);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Memories')),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E7),
              border: Border(bottom: BorderSide(color: Color(0xFFE8DCC8))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pixel's Memories",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_memories.length} memor${_memories.length == 1 ? 'y' : 'ies'} stored',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFA0896C),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_memories.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: _clearAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _memories.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMemories,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _memories.length,
                      itemBuilder: (context, index) =>
                          _buildMemoryCard(_memories[index]),
                    ),
                  ),
          ),

          if (_memories.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Long-press a memory to delete it',
                style: TextStyle(fontSize: 11, color: Color(0xFFC0A888)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No memories yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with Pixel to start building memories.\nKey facts will be extracted and stored here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown.shade300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return GestureDetector(
      onLongPress: () => _deleteMemory(memory.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(memory.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA0896C),
                    ),
                  ),
                  Text(
                    _importanceBar(memory.importanceScore),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7C4DFF),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
