import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/kaspot_service.dart';
import '../widgets/kaspot_avatar.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _idController = TextEditingController();
  bool _busy = false;
  bool _loading = true;
  int _filterTab = 0; // 0 = All, 1 = Sharing, 2 = Requests

  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _requests = [];
  Map<String, bool> _sharing = {};
  Map<String, bool> _incomingSharing = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await Future.wait([
        KaSpotService.connections(),
        KaSpotService.requests(),
        KaSpotService.sharingGrants(),
        KaSpotService.incomingSharingStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _people = result[0] as List<Map<String, dynamic>>;
        _requests = result[1] as List<Map<String, dynamic>>;
        _sharing = {
          for (final row in result[2] as List<Map<String, dynamic>>)
            row['recipient_id'] as String: row['is_enabled'] as bool
        };
        _incomingSharing = result[3] as Map<String, bool>;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
      if (mounted) _notify(success);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Future<void> _setSharing(String recipientId, bool enabled) async {
    if (!enabled) {
      await KaSpotService.setSharing(recipientId, false);
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on device location services before sharing.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Location permission was not granted. Sharing remains off.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await KaSpotService.setSharing(recipientId, true);
    await KaSpotService.upsertOwnLocation(position);
  }

  @override
  Widget build(BuildContext context) {
    final myId = KaSpotService.userId;
    final incomingRequests = _requests
        .where((r) => r['recipient_id'] == myId && r['status'] == 'pending')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Circle'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // 1. Clean Invite Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF5FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Color(0xFF1E60AA), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite to your circle',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Connecting requires mutual consent.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Account ID (UUID)',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    autocorrect: false,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              final id = _idController.text.trim();
                              if (id.isEmpty) {
                                _notify('Please enter an account ID.');
                                return;
                              }
                              _run(() => KaSpotService.sendRequest(id), 'Connection request sent.');
                              _idController.clear();
                            },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send Invitation'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. Your Account ID Card (Easy copy for sharing)
            if (myId.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share_outlined, color: Color(0xFF1E60AA), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Account ID (share with friends)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          Text(
                            myId,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: myId));
                        _notify('Account ID copied to clipboard.');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
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
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C)))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3. Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${_people.length})',
                    selected: _filterTab == 0,
                    onTap: () => setState(() => _filterTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sharing (${_people.where((p) => _sharing[p['other_id']] == true).length})',
                    selected: _filterTab == 1,
                    onTap: () => setState(() => _filterTab = 1),
                  ),
                  if (incomingRequests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending (${incomingRequests.length})',
                      selected: _filterTab == 2,
                      badge: true,
                      onTap: () => setState(() => _filterTab = 2),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Incoming Requests Section
            if (incomingRequests.isNotEmpty && (_filterTab == 0 || _filterTab == 2)) ...[
              _sectionHeader('Incoming Requests', incomingRequests.length),
              ...incomingRequests.map((req) => _requestCard(req)),
              const SizedBox(height: 14),
            ],

            // 5. Circle Members List
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_people.isEmpty)
              _emptyCard()
            else
              ..._people
                  .where((person) {
                    if (_filterTab == 1) return _sharing[person['other_id']] == true;
                    return true;
                  })
                  .map((person) {
                    final otherId = person['other_id'] as String;
                    final isSharingWithThem = _sharing[otherId] ?? false;
                    final theyShareWithMe = _incomingSharing[otherId] ?? false;
                    final name = person['display_name'] as String? ?? 'Member';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              KaSpotAvatar(
                                name: name,
                                avatarUrl: person['avatar_url'] as String?,
                                size: 44,
                                isCircle: true,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theyShareWithMe ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          theyShareWithMe
                                              ? 'Sharing their location with you'
                                              : 'Not sharing their location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theyShareWithMe ? const Color(0xFF059669) : const Color(0xFF64748B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                                tooltip: 'Options',
                                onPressed: () => _showPersonOptions(person),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          Row(
                            children: [
                              Icon(
                                isSharingWithThem ? Icons.location_on_rounded : Icons.location_off_outlined,
                                color: isSharingWithThem ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSharingWithThem ? 'You are sharing your location' : 'You are not sharing with them',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSharingWithThem ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      isSharingWithThem ? 'Can see your latest updates' : 'Location hidden from this person',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: isSharingWithThem,
                                activeTrackColor: const Color(0xFF10B981),
                                onChanged: _busy
                                    ? null
                                    : (val) => _run(
                                          () => _setSharing(otherId, val),
                                          val ? 'Sharing enabled for this person.' : 'Sharing stopped.',
                                        ),
                              ),
                            ],
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

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E60AA))),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
    final reqId = request['id'] as String;
    final otherId = request['requester_id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: Color(0xFF1E60AA), size: 20),
              const SizedBox(width: 8),
              const Text('Wants to connect with you', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${otherId.length > 8 ? otherId.substring(0, 8) : otherId}…',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => _run(() => KaSpotService.respondToRequest(reqId, 'rejected'), 'Declined.'),
                child: const Text('Decline'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : () => _run(() => KaSpotService.respondToRequest(reqId, 'accepted'), 'Connected!'),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Your Circle is Empty', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          SizedBox(height: 6),
          Text(
            'Share your Account ID with family or trusted friends to connect. Location sharing is always an opt-in choice for each person.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _showPersonOptions(Map<String, dynamic> person) async {
    final name = person['display_name'] as String? ?? 'Member';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Color(0xFFDC2626)),
              title: Text('Remove $name from Circle', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _run(() => KaSpotService.removeConnection(person['id'] as String), 'Removed from circle.');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.badge = false});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E60AA) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF1E60AA) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
