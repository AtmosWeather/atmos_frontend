import 'package:atmos_frontend/core/auth/auth_state.dart';
import 'package:atmos_frontend/features/auth/presentation/widgets/auth_popup.dart';
import 'package:atmos_frontend/features/weather/data/weather_api_client.dart';
import 'package:atmos_frontend/features/weather/data/weather_repository.dart';
import 'package:atmos_frontend/features/weather/domain/weather_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atmos_frontend/core/services/news_api_service.dart';
import 'package:atmos_frontend/features/planner/data/planner_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 2; // Start on Home/Weather (center tab)

  // Tab titles for the AppBar
  final List<String> _tabTitles = [
    'Planner',
    'AI Assistant',
    'Atmos',
    'News',
    'Settings',
  ];

  // ── Weather state ──
  final WeatherApiClient _apiClient = WeatherApiClient();
  final WeatherRepository _repository = WeatherRepository();
  final TextEditingController _searchController = TextEditingController();

  List<String> _searchHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Detail view state
  bool _showingDetail = false;
  CurrentWeather? _currentWeather;
  List<ForecastDay> _forecast = [];
  LatLng? _tappedLocation;

  // Planner notification state
  int _pendingTaskCount = 0;
  final PlannerRepository _plannerRepo = PlannerRepository();

  // News notification state
  final NewsApiService _newsApiService = NewsApiService();
  int _unreadNewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fetchPendingTaskCount();
    _checkUnreadNews();
  }

  Future<void> _checkUnreadNews() async {
    try {
      final updates = await _newsApiService.fetchUpdates();
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('readNewsIds') ?? [];
      final unreadCount = updates.where((u) => !readIds.contains(u.id)).length;
      if (mounted) setState(() => _unreadNewsCount = unreadCount);
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    final history = await _repository.loadSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _fetchPendingTaskCount() async {
    if (!AuthState().isSignedIn) return;
    try {
      final userId = AuthState().userEmail ?? 'guest';
      final tasks = await _plannerRepo.getTasks(userId);
      final pending = tasks.where((t) => t.status != 'done').length;
      if (mounted) setState(() => _pendingTaskCount = pending);
    } catch (_) {
      // silent fail — badge just won't show
    }
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _apiClient.fetchCurrentWeather(city: city.trim());
      final forecast = await _apiClient.fetchForecast(city: city.trim());
      await _repository.addCity(weather.cityName);
      await _loadHistory();
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _forecast = forecast;
          _showingDetail = true;
          _isLoading = false;
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              e.toString().contains('City not found')
                  ? 'City not found. Please try another name.'
                  : 'Failed to fetch weather data. Check your connection.';
        });
      }
    }
  }

  Future<void> _openCityWeather(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _apiClient.fetchCurrentWeather(city: city);
      final forecast = await _apiClient.fetchForecast(city: city);
      // Move city to top
      await _repository.addCity(weather.cityName);
      await _loadHistory();
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _forecast = forecast;
          _showingDetail = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load weather for $city.';
        });
      }
    }
  }

  Future<void> _openLocationWeather(double lat, double lon) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _apiClient.fetchCurrentWeather(lat: lat, lon: lon);
      final forecast = await _apiClient.fetchForecast(lat: lat, lon: lon);
      // Save the geographical city name returned by OWM
      await _repository.addCity(weather.cityName);
      await _loadHistory();
      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _forecast = forecast;
          _showingDetail = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load weather for that location.';
        });
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _tappedLocation = point;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('View Weather'),
        content: const Text('Do you want to see the weather for this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openLocationWeather(point.latitude, point.longitude);
            },
            child: const Text('Yes', style: TextStyle(color: Color(0xFF29B6F6))),
          ),
        ],
      ),
    );
  }

  void _showFullScreenMap({LatLng? pinnedLocation, bool isInteractive = true}) {
    // Failsafe strictly ensuring no NaN coordinates are ever passed into the map options
    final safeLat = pinnedLocation?.latitude.isNaN == true ? 0.0 : (pinnedLocation?.latitude ?? 20.0);
    final safeLon = pinnedLocation?.longitude.isNaN == true ? 0.0 : (pinnedLocation?.longitude ?? 0.0);
    final centerPoint = LatLng(safeLat, safeLon);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: pinnedLocation != null ? 10.0 : 2.0,
                      minZoom: 2.0,
                      maxZoom: 18.0,
                      onTap: isInteractive ? (tapPosition, point) {
                        Navigator.pop(ctx);
                        _onMapTap(point);
                      } : null,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.atmos_frontend',
                      ),
                      if (pinnedLocation != null || _tappedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: pinnedLocation != null ? centerPoint : _tappedLocation!,
                              width: 50,
                              height: 50,
                              alignment: Alignment.topCenter,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCity(String city) async {
    await _repository.removeCity(city);
    await _loadHistory();
  }

  void _backToHistory() {
    setState(() {
      _showingDetail = false;
      _currentWeather = null;
      _forecast = [];
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Icon helper ──
  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'drizzle':
        return Icons.grain;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'sand':
      case 'ash':
      case 'squall':
      case 'tornado':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _weatherIconColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return const Color(0xFF7E57C2);
      case 'drizzle':
      case 'rain':
        return const Color(0xFF42A5F5);
      case 'snow':
        return const Color(0xFF90CAF9);
      case 'clear':
        return const Color(0xFFFFA726);
      case 'clouds':
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF78909C);
    }
  }

  List<Color> _weatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'thunderstorm':
        return [const Color(0xFF5C6BC0), const Color(0xFF7E57C2)];
      case 'drizzle':
      case 'rain':
        return [const Color(0xFF42A5F5), const Color(0xFF1565C0)];
      case 'snow':
        return [const Color(0xFF90CAF9), const Color(0xFFBBDEFB)];
      case 'clear':
        return [const Color(0xFFFFA726), const Color(0xFFFF7043)];
      case 'clouds':
        return [const Color(0xFF78909C), const Color(0xFF90A4AE)];
      default:
        return [const Color(0xFF29B6F6), const Color(0xFF4FC3F7)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final isDark = AuthState().theme == 'Dark Mode';
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final appBarColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEEEE);

        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: Scaffold(
            backgroundColor: bgColor,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: appBarColor,
              elevation: 0,
              centerTitle: false,
              title: Row(
          children: [
            if (_currentIndex == 2)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const Icon(Icons.cloud_circle, color: Color(0xFF29B6F6), size: 28),
                ],
              ),
            if (_currentIndex == 2) const SizedBox(width: 8),
            Text(
              _tabTitles[_currentIndex],
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(
            top: BorderSide(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFDDDDDD), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: appBarColor,
          selectedItemColor: const Color(0xFF29B6F6),
          unselectedItemColor: isDark ? Colors.white54 : Colors.grey,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _pendingTaskCount > 0 && AuthState().notification == 'On' && AuthState().isSignedIn
                  ? Badge(
                      backgroundColor: Colors.red,
                      label: Text('$_pendingTaskCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: const Icon(Icons.calendar_today),
                    )
                  : const Icon(Icons.calendar_today),
              label: 'Planner',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _unreadNewsCount > 0 && AuthState().notification == 'On' && AuthState().isSignedIn
                  ? Badge(
                      backgroundColor: Colors.red,
                      label: Text('$_unreadNewsCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      child: const Icon(Icons.article),
                    )
                  : const Icon(Icons.article),
              label: 'News',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    ),
  );
      },
    );
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      if (!AuthState().isSignedIn) {
        showSignInPopup(context).then((success) {
          if (!mounted) return;
          if (success) {
            if (!AuthState().acceptedTerms) {
              Navigator.pushNamed(context, '/terms').then((_) {
                if (AuthState().acceptedTerms && mounted) {
                  Navigator.pushNamed(context, '/planner').then((_) => _fetchPendingTaskCount());
                }
              });
            } else {
              Navigator.pushNamed(context, '/planner').then((_) => _fetchPendingTaskCount());
            }
          }
        });
        return;
      }
      if (!AuthState().acceptedTerms) {
        Navigator.pushNamed(context, '/terms').then((_) {
          if (AuthState().acceptedTerms && mounted) {
            Navigator.pushNamed(context, '/planner').then((_) => _fetchPendingTaskCount());
          }
        });
        return;
      }
      Navigator.pushNamed(context, '/planner').then((_) => _fetchPendingTaskCount());
      return;
    }
    if (index == 1) {
      if (!AuthState().isSignedIn) {
        showSignInPopup(context).then((success) {
          if (!mounted) return;
          if (success) {
            if (!AuthState().acceptedTerms) {
              Navigator.pushNamed(context, '/terms').then((_) {
                if (AuthState().acceptedTerms && mounted) {
                  Navigator.pushNamed(context, '/ai');
                }
              });
            } else {
              Navigator.pushNamed(context, '/ai');
            }
          }
        });
        return;
      }
      if (!AuthState().acceptedTerms) {
        Navigator.pushNamed(context, '/terms').then((_) {
          if (AuthState().acceptedTerms && mounted) {
            Navigator.pushNamed(context, '/ai');
          }
        });
        return;
      }
      Navigator.pushNamed(context, '/ai');
      return;
    }
    if (index == 2) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }
    if (index == 3) {
      Navigator.pushNamed(context, '/news').then((_) => _checkUnreadNews());
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, '/settings');
      return;
    }
  }

  Widget _buildBody() {
    return _showingDetail ? _buildWeatherDetail() : _buildSearchHistoryView();
  }


  // ════════════════════════════════════════════════════════════
  // Search History View
  // ════════════════════════════════════════════════════════════
  Widget _buildSearchHistoryView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search, color: Colors.grey, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _searchCity,
                            decoration: const InputDecoration(
                              hintText: 'Search location...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _searchCity(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF29B6F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading / Error
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: CircularProgressIndicator(color: Color(0xFF29B6F6)),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Map View (Philippines focused)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: const LatLng(20.0, 0.0),
                        initialZoom: 1.5,
                        minZoom: 1.5,
                        maxZoom: 15.0,
                        onTap: (tapPosition, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.atmos_frontend',
                        ),
                        if (_tappedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _tappedLocation!,
                                width: 40,
                                height: 40,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.black87),
                          onPressed: () => _showFullScreenMap(),
                          tooltip: 'Full Screen',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // History header
          if (_searchHistory.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Locations',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          if (_searchHistory.isNotEmpty) const SizedBox(height: 8),

          // City list
          if (_searchHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_queue, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No locations yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search for a city to see the weather',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              itemCount: _searchHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final city = _searchHistory[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openCityWeather(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE8ECF0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF29B6F6),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              city,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteCity(city);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Weather Detail View
  // ════════════════════════════════════════════════════════════
  Widget _buildWeatherDetail() {
    final weather = _currentWeather!;
    final gradient = _weatherGradient(weather.mainCondition);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: _backToHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 16, color: Colors.black54),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // City name
          Text(
            weather.cityName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            weather.description[0].toUpperCase() +
                weather.description.substring(1),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          // Current Weather Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${AuthState().units.startsWith('°F') ? (weather.temp * 9/5 + 32).round() : weather.temp.round()}°${AuthState().units.startsWith('°F') ? 'F' : 'C'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like ${AuthState().units.startsWith('°F') ? (weather.feelsLike * 9/5 + 32).round() : weather.feelsLike.round()}°${AuthState().units.startsWith('°F') ? 'F' : 'C'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _weatherIcon(weather.mainCondition),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  Icons.water_drop,
                  'Humidity',
                  '${weather.humidity}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  Icons.air,
                  'Wind',
                  AuthState().units.startsWith('°F')
                      ? '${(weather.windSpeed * 2.23694).round()} mph'
                      : '${(weather.windSpeed * 3.6).round()} kmph',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  Icons.compress,
                  'Pressure',
                  AuthState().units.startsWith('°F')
                      ? '${(weather.pressure * 0.02953).toStringAsFixed(2)} inHg'
                      : '${weather.pressure} hPa',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  Icons.visibility,
                  'Visibility',
                  AuthState().units.startsWith('°F')
                      ? '${(weather.visibility / 1609.34).toStringAsFixed(1)} mi'
                      : '${(weather.visibility / 1000).toStringAsFixed(1)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  Icons.thermostat,
                  'Min / Max',
                  '${AuthState().units.startsWith('°F') ? (weather.tempMin * 9/5 + 32).round() : weather.tempMin.round()}° / ${AuthState().units.startsWith('°F') ? (weather.tempMax * 9/5 + 32).round() : weather.tempMax.round()}°',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  Icons.cloud,
                  'Clouds',
                  '${weather.clouds}%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Location Map
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(weather.lat, weather.lon),
                      initialZoom: 11.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.atmos_frontend',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(weather.lat, weather.lon),
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.black87),
                        onPressed: () => _showFullScreenMap(
                          pinnedLocation: LatLng(weather.lat, weather.lon),
                          isInteractive: false,
                        ),
                        tooltip: 'Full Screen',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 5-Day Forecast
          if (_forecast.isNotEmpty) ...[
            const Text(
              '5-Day Forecast',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._forecast.map((day) => Column(
                  children: [
                    _buildForecastRow(day),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ],
                )),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF29B6F6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(ForecastDay day) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[day.date.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              dayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            _weatherIcon(day.mainCondition),
            color: _weatherIconColor(day.mainCondition),
            size: 24,
          ),
          const Spacer(),
          Text(
            '${AuthState().units.startsWith('°F') ? (day.tempMax * 9/5 + 32).round() : day.tempMax.round()}° / ${AuthState().units.startsWith('°F') ? (day.tempMin * 9/5 + 32).round() : day.tempMin.round()}°',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
