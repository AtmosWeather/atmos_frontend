import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/services/news_api_service.dart';
import '../widgets/weather_update_form.dart';

class WeatherUpdatesAdminPage extends StatefulWidget {
  const WeatherUpdatesAdminPage({super.key});

  @override
  State<WeatherUpdatesAdminPage> createState() => _WeatherUpdatesAdminPageState();
}

class _WeatherUpdatesAdminPageState extends State<WeatherUpdatesAdminPage> {
  final NewsApiService _apiService = NewsApiService();
  List<WeatherUpdate> _updates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchUpdates();
      setState(() {
        _updates = data.reversed.toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load updates: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForm([WeatherUpdate? update]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WeatherUpdateForm(initialUpdate: update),
    );
    if (result == true) {
      _fetchUpdates();
    }
  }

  Future<void> _archiveUpdate(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Update'),
        content: const Text('Are you sure you want to archive this update? It will be hidden but preserved in the database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archive', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteUpdate(id);
        _fetchUpdates();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archive failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF29B6F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Atmos',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF29B6F6),
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Manage Weather Updates',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _updates.isEmpty
                  ? const Center(child: Text('No weather updates found. Add one!'))
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _updates.length,
                  itemBuilder: (context, index) {
                    final item = _updates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.imageUrl.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(item.imageUrl.split(',').last),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, size: 60, color: Colors.grey),
                                )
                              : Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, size: 60, color: Colors.grey),
                                ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.date}\n${item.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showForm(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.archive, color: Colors.grey),
                              onPressed: () => _archiveUpdate(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
