import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/kaspot_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<Map<String, dynamic>> _places = [];
  bool _busy = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final rows = await KaSpotService.savedPlaces();
      if (mounted) {
        setState(() {
          _places = rows;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    String selectedCategory = 'Home';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Save a Private Place',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Places are saved securely to your account. Your circle members cannot see them.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _presetChip('Home', Icons.home_rounded, selectedCategory, (cat) {
                    setModalState(() {
                      selectedCategory = cat;
                      name.text = cat;
                    });
                  }),
                  _presetChip('Work', Icons.business_center_rounded, selectedCategory, (cat) {
                    setModalState(() {
                      selectedCategory = cat;
                      name.text = cat;
                    });
                  }),
                  _presetChip('Gym', Icons.fitness_center_rounded, selectedCategory, (cat) {
                    setModalState(() {
                      selectedCategory = cat;
                      name.text = cat;
                    });
                  }),
                  _presetChip('School', Icons.school_rounded, selectedCategory, (cat) {
                    setModalState(() {
                      selectedCategory = cat;
                      name.text = cat;
                    });
                  }),
                  _presetChip('Cafe', Icons.coffee_rounded, selectedCategory, (cat) {
                    setModalState(() {
                      selectedCategory = cat;
                      name.text = cat;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Place name',
                  hintText: 'e.g., Mom’s House, Studio, Gym',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Save with current GPS position'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || name.text.trim().isEmpty) {
      name.dispose();
      return;
    }

    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on device location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await KaSpotService.addSavedPlace(name.text, position);
      if (mounted) _notify('Place saved privately to your account.');
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      name.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _presetChip(String label, IconData icon, String selected, ValueChanged<String> onSelect) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E60AA) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notify(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _add,
            tooltip: 'Add a place',
            icon: const Icon(Icons.add_location_alt_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _add,
        backgroundColor: const Color(0xFF1E60AA),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add_rounded),
        label: const Text('Save Place', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          children: [
            // Safety reassurance card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF5FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFF1E60AA), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Private Bookmarks',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Saved places are only for your personal peace of mind. Connections never see them.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
              ),
            ],

            const SizedBox(height: 16),

            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_places.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.place_outlined, size: 40, color: Color(0xFF94A3B8)),
                    SizedBox(height: 12),
                    Text('No saved places yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 6),
                    Text(
                      'Pin your home, workplace, or favorite spot for quick navigation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ..._places.map((place) {
                final name = place['name'] as String;
                final lat = (place['latitude'] as num).toDouble();
                final lon = (place['longitude'] as num).toDouble();
                final icon = _getCategoryIcon(name);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: const Color(0xFF1E60AA), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.directions_outlined, color: Color(0xFF1E60AA)),
                        tooltip: 'Directions',
                        onPressed: () async {
                          final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
                          if (await canLaunchUrl(geoUri)) {
                            await launchUrl(geoUri);
                          } else {
                            final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
                            if (await canLaunchUrl(webUri)) {
                              await launchUrl(webUri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8)),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Place'),
                              content: Text('Are you sure you want to delete "$name"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await KaSpotService.deleteSavedPlace(place['id'] as String);
                              await _load();
                              if (mounted) _notify('Place deleted.');
                            } catch (e) {
                              if (mounted) _notify(e.toString());
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('work') || lower.contains('office')) return Icons.business_center_rounded;
    if (lower.contains('school') || lower.contains('campus')) return Icons.school_rounded;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('cafe') || lower.contains('coffee')) return Icons.coffee_rounded;
    return Icons.place_rounded;
  }
}
