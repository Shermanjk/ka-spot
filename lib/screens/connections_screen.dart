import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/kaspot_service.dart';
import '../widgets/kaspot_avatar.dart';
import 'circle_chat_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _idController = TextEditingController();
  bool _busy = false;
  bool _loading = true;
  List<Map<String, dynamic>> _people = [];
  List<Map<String, dynamic>> _requests = [];
  Map<String, bool> _sharing = {};
  Map<String, bool> _incomingSharing = {};
  String? _error;
  Timer? _errorTimer;
  Timer? _refreshTimer;

  Widget _relationshipBadge(String relationship, {VoidCallback? onTap}) {
    Color bg;
    Color text;
    IconData icon;
    switch (relationship) {
      case 'Partner':
        bg = const Color(0xFFFFE4E6);
        text = const Color(0xFFE11D48);
        icon = Icons.favorite_rounded;
        break;
      case 'Family':
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF7C3AED);
        icon = Icons.family_restroom_rounded;
        break;
      case 'Friend':
      default:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        icon = Icons.people_alt_rounded;
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: text),
            const SizedBox(width: 4),
            Text(
              relationship,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    // Silent auto-refresh so incoming requests, new connections, and sent
    // invitation updates appear without manual pulling (mirrors the chat
    // screen's polling while this tab is visible).
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _busy || _loading) return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _refreshTimer?.cancel();
    _idController.dispose();
    super.dispose();
  }

  void _setError(String? msg) {
    _errorTimer?.cancel();
    if (!mounted) return;
    setState(() => _error = msg);
    if (msg != null && msg.isNotEmpty) {
      _errorTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _error = null);
      });
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (mounted && !silent) setState(() => _loading = true);
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
        if (!silent) _error = null;
      });
    } catch (e) {
      if (mounted && !silent) _setError(e.toString());
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    _errorTimer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await _load();
      if (mounted) _notify(success);
    } catch (e) {
      if (mounted) _setError(e.toString().replaceFirst('Exception: ', ''));
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
    final sentInvitations = _requests
        .where((r) =>
            r['requester_id'] == myId &&
            (r['status'] == 'pending' || r['status'] == 'rejected'))
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
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter Circle Code (e.g. KS-E7BE-D662)',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    autocorrect: false,
                    onChanged: (_) {
                      if (_error != null) _setError(null);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              final id = _idController.text.trim();
                              if (id.isEmpty) {
                                _notify('Please enter a Circle Code.');
                                return;
                              }
                              _run(
                                () => KaSpotService.sendRequest(id),
                                'Connection request sent.',
                              );
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

            // 2. Your Account Code Card (Easy copy for sharing)
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
                            'Your Circle Code (share with friends)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            KaSpotService.accountCode,
                            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final code = KaSpotService.accountCode;
                        Clipboard.setData(ClipboardData(text: code));
                        _notify('Circle Code $code copied to clipboard.');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _error == null
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey('error-$_error'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _setError(null),
                              child: const Icon(Icons.close_rounded, color: Color(0xFF991B1B), size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // 3. Incoming Requests Section
            if (incomingRequests.isNotEmpty) ...[
              _sectionHeader('Incoming Requests', incomingRequests.length),
              ...incomingRequests.map((req) => _requestCard(req)),
              const SizedBox(height: 14),
            ],

            // 4. Sent Invitations Section (pending ones can be cancelled;
            // declined ones stay visible as a muted status)
            if (sentInvitations.isNotEmpty) ...[
              _sectionHeader('Sent Invitations', sentInvitations.length),
              ...sentInvitations.map((req) => _sentInvitationCard(req)),
              const SizedBox(height: 14),
            ],

            // 5. Circle Members List
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_people.isEmpty)
              _emptyCard()
            else
              ..._people.map((person) {
                final otherId = person['other_id'] as String;
                final isSharingWithThem = _sharing[otherId] ?? false;
                final theyShareWithMe = _incomingSharing[otherId] ?? false;
                final name = person['display_name'] as String? ?? 'Member';
                final rel = person['relationship'] as String? ?? 'Friend';

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
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _relationshipBadge(
                                      rel,
                                      onTap: () => _changeCategorySheet(person),
                                    ),
                                  ],
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
                                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1E60AA)),
                                tooltip: 'Chat & Updates',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CircleChatScreen(
                                        otherId: otherId,
                                        displayName: name,
                                        avatarUrl: person['avatar_url'] as String?,
                                        theyShareWithMe: theyShareWithMe,
                                      ),
                                    ),
                                  );
                                },
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
    final name = request['counterpart_name'] as String? ?? 'KaSpot member';
    final code = request['counterpart_code'] as String? ?? '';
    final avatarUrl = request['counterpart_avatar'] as String?;

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
              KaSpotAvatar(name: name, avatarUrl: avatarUrl, size: 40, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: Color(0xFF1E60AA), size: 16),
              SizedBox(width: 6),
              Text(
                'Wants to connect with you',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _sentInvitationCard(Map<String, dynamic> request) {
    final reqId = request['id'] as String;
    final isPending = (request['status'] as String? ?? 'pending') == 'pending';
    final name = request['counterpart_name'] as String? ?? 'KaSpot member';
    final code = request['counterpart_code'] as String? ?? '';
    final avatarUrl = request['counterpart_avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          KaSpotAvatar(name: name, avatarUrl: avatarUrl, size: 38, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                if (code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    code,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPending)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'Awaiting response',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFC2410C)),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _run(() => KaSpotService.cancelRequest(reqId), 'Invitation cancelled.'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    foregroundColor: const Color(0xFF64748B),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Declined',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
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



  Future<void> _changeCategorySheet(Map<String, dynamic> person) async {
    final otherId = person['other_id'] as String;
    final name = person['display_name'] as String? ?? 'Member';
    final currentRel = person['relationship'] as String? ?? 'Friend';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Circle Category for $name',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Categorize this connection to tailor alerts and map labels',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                _relOptionTile('Partner', 'Spouse or significant other', Icons.favorite_rounded, const Color(0xFFE11D48), currentRel, () async {
                  Navigator.pop(context);
                  await _run(() => KaSpotService.setCircleRelationship(otherId, 'Partner'), 'Updated $name to Partner.');
                }),
                _relOptionTile('Family', 'Parents, children, siblings, relatives', Icons.family_restroom_rounded, const Color(0xFF7C3AED), currentRel, () async {
                  Navigator.pop(context);
                  await _run(() => KaSpotService.setCircleRelationship(otherId, 'Family'), 'Updated $name to Family.');
                }),
                _relOptionTile('Friend', 'Friends, coworkers, and trusted peers', Icons.people_alt_rounded, const Color(0xFF0284C7), currentRel, () async {
                  Navigator.pop(context);
                  await _run(() => KaSpotService.setCircleRelationship(otherId, 'Friend'), 'Updated $name to Friends.');
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _relOptionTile(String title, String desc, IconData icon, Color color, String currentRel, VoidCallback onTap) {
    final isSelected = currentRel == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color) : null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _showPersonOptions(Map<String, dynamic> person) async {
    final name = person['display_name'] as String? ?? 'Member';
    final rel = person['relationship'] as String? ?? 'Friend';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category_outlined, color: Color(0xFF1E60AA)),
              title: const Text('Change Circle Category', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Currently: $rel'),
              onTap: () {
                Navigator.pop(context);
                _changeCategorySheet(person);
              },
            ),
            const Divider(height: 1),
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
