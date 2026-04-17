import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/services/news_api_service.dart';
import '../../../../core/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NewsApiService _apiService = NewsApiService();
  List<WeatherUpdate> _updates = [];
  Set<String> _readNewsIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUpdates();
  }

  Future<void> _fetchUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('readNewsIds') ?? [];
      final data = await _apiService.fetchUpdates();
      if (mounted) {
        setState(() {
          _readNewsIds = readIds.toSet();
          _updates = data.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load news updates.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markArticleAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('readNewsIds') ?? [];
    if (!readIds.contains(id)) {
      readIds.add(id);
      await prefs.setStringList('readNewsIds', readIds);
    }
    if (mounted) {
      setState(() {
        _readNewsIds.add(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final isDark = AuthState().theme == 'Dark Mode';
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                const Icon(Icons.cloud_circle, color: Color(0xFF29B6F6), size: 28),
                const SizedBox(width: 8),
                Text('Atmos', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
          body: _buildBody(isDark),
        );
      },
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchUpdates,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      );
    }

    if (_updates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.newspaper, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No news updates yet.', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUpdates,
      color: const Color(0xFF29B6F6),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF444444) : const Color(0xFFE0E0E0)),
                    ),
                    child: Icon(Icons.arrow_back, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text('Latest Alerts & News', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            const SizedBox(height: 20),
            ..._updates.asMap().entries.map((entry) {
              final update = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildNewsCard(
                  id: update.id, isDark: isDark,
                  isRead: _readNewsIds.contains(update.id),
                  avatarColor: const Color(0xFF29B6F6),
                  authorName: 'Atmos', authorRole: 'Admin',
                  date: update.date, alertTitle: update.title,
                  description: update.description, imageUrl: update.imageUrl,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard({
    required String id,
    required bool isRead,
    required bool isDark,
    required Color avatarColor,
    required String authorName,
    required String authorRole,
    required String date,
    required String alertTitle,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: avatarColor, child: const Icon(Icons.cloud, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authorName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                        Text(authorRole, style: const TextStyle(fontSize: 13, color: Color(0xFF29B6F6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF29B6F6))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                    const SizedBox(width: 6),
                    Expanded(child: Text(alertTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54, height: 1.4)),
                if (!isRead) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _markArticleAsRead(id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark as Read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF29B6F6),
                        backgroundColor: const Color(0xFFE1F5FE),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            child: imageUrl.isNotEmpty ? _buildImage(imageUrl) : _buildGradientPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image from admin
      return Image.memory(
        base64Decode(imageUrl.split(',').last),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildGradientPlaceholder(),
      );
    } else {
      // Network URL image
      return Image.network(
        imageUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildGradientPlaceholder(),
      );
    }
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF4A148C),
            Color(0xFFE65100),
            Color(0xFFFF8F00),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _MountainPainter(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A237E).withValues(alpha: 0.8),
                    const Color(0xFF4A148C).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.15, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.45, size.height * 0.2);
    path.lineTo(size.width * 0.55, size.height * 0.15);
    path.lineTo(size.width * 0.65, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height * 0.7);
    path.lineTo(size.width, size.height * 0.55);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
