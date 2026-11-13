import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state_emblem_data.dart';

/// Displays an avatar image for a state/zone using official state emblems.
/// 1. Uses high-speed in-memory embedded PNG data (instant, zero network, hot-reload proof).
/// 2. Falls back to local asset bundle (`assets/icons/states/`).
/// 3. Falls back to Wikipedia API thumbnail.
/// 4. Falls back to state initials badge.
class StateAvatar extends StatefulWidget {
  final String name;
  final double size;
  final BoxShape shape;
  final bool showBorder;
  final bool enableNetwork;

  const StateAvatar({
    super.key,
    required this.name,
    this.size = 28,
    this.shape = BoxShape.circle,
    this.showBorder = true,
    this.enableNetwork = true,
  });

  @override
  State<StateAvatar> createState() => _StateAvatarState();
}

class _StateAvatarState extends State<StateAvatar> {
  static final Map<String, String?> _wikipediaCache = {};
  static final Set<String> _pendingRequests = {};
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveAvatarUrl();
  }

  @override
  void didUpdateWidget(covariant StateAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _resolveAvatarUrl();
    }
  }

  void _resolveAvatarUrl() {
    final norm = _normalize(widget.name);
    if (norm.contains('hospitality')) {
      return;
    }

    final key = _resolveKey(widget.name);

    // If we have embedded memory bytes or local asset, no network needed
    if (StateEmblemData.getBytes(key) != null ||
        _localAssets.containsKey(key)) {
      return;
    }

    if (_networkImageUrls.containsKey(key)) {
      _resolvedUrl = _networkImageUrls[key];
      return;
    }

    if (_wikipediaCache.containsKey(key)) {
      _resolvedUrl = _wikipediaCache[key];
      return;
    }

    if (!widget.enableNetwork) {
      return;
    }

    // Dynamic Wikipedia fallback lookup for unmapped states
    if (!_pendingRequests.contains(key) && key.isNotEmpty && key != 'unknown') {
      _pendingRequests.add(key);
      _fetchFromWikipedia(key);
    }
  }

  Future<void> _fetchFromWikipedia(String key) async {
    try {
      final title = _getWikipediaTitle(widget.name);
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'User-Agent': 'PropCareGovernance/1.0 (contact@propcare.in)',
        },
      ));
      final response = await dio.get<Map<String, dynamic>>(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final thumb = data['thumbnail'] as Map<String, dynamic>?;
        final url = thumb?['source'] as String?;
        if (mounted) {
          setState(() {
            _wikipediaCache[key] = url;
            _resolvedUrl = url;
          });
        } else {
          _wikipediaCache[key] = url;
        }
      } else {
        _wikipediaCache[key] = null;
      }
    } catch (_) {
      _wikipediaCache[key] = null;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normalize(widget.name);
    final key = _resolveKey(widget.name);
    final isHospitality = norm.contains('hospitality');

    // 1. Dedicated Hospitality Icon Badge
    if (isHospitality) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          border: widget.showBorder
              ? Border.all(color: const Color(0xFFFDE68A), width: 1.0)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.hotel_rounded,
            size: widget.size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }

    // 2. High-speed, 100% Reliable In-Memory Embedded PNG Emblem
    final Uint8List? memoryBytes = StateEmblemData.getBytes(key);
    if (memoryBytes != null) {
      return _buildImageFrame(
        Image.memory(
          memoryBytes,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackBadge(),
        ),
      );
    }

    // 3. Local Bundled Asset Emblem (if bundled in asset manifest)
    final localAsset = _localAssets[key];
    if (localAsset != null) {
      return _buildImageFrame(
        Image.asset(
          localAsset,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackBadge(),
        ),
      );
    }

    // 4. Network Image via Wikipedia (for unbundled states)
    final imageUrl = _resolvedUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return _buildImageFrame(
        Image.network(
          imageUrl,
          headers: const {
            'User-Agent': 'PropCareGovernance/1.0 (contact@propcare.in)',
          },
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackBadge(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildFallbackBadge();
          },
        ),
      );
    }

    // 5. Fallback Initials Badge
    return _buildFallbackBadge();
  }

  Widget _buildImageFrame(Widget imageWidget) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.shape,
        color: Colors.white,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(widget.size / 2),
        border: widget.showBorder
            ? Border.all(color: const Color(0xFFE2E8F0), width: 1.0)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Padding(
          padding: EdgeInsets.all(widget.size * 0.08),
          child: imageWidget,
        ),
      ),
    );
  }

  Widget _buildFallbackBadge() {
    final initials = _getInitials(widget.name);
    final palette = _getPalette(widget.name);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.colors,
        ),
        border: widget.showBorder
            ? Border.all(color: palette.borderColor, width: 1.0)
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.outfit(
            fontSize: widget.size * 0.42,
            fontWeight: FontWeight.w700,
            color: palette.textColor,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  static String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _resolveKey(String input) {
    final norm = _normalize(input);
    if (norm.contains('andra') || norm.contains('andhra')) {
      return 'andhrapradesh';
    }
    if (norm.contains('karnataka')) return 'karnataka';
    if (norm.contains('mumbai') ||
        norm.contains('maharashtra') ||
        norm.contains('pune')) {
      return 'maharashtra';
    }
    if (norm.contains('delhi') || norm.contains('ncr')) return 'delhi';
    if (norm.contains('telangana') || norm.contains('hyderabad')) {
      return 'telangana';
    }
    if (norm.contains('tamil') || norm.contains('chennai')) return 'tamilnadu';
    if (norm.contains('kerala') || norm.contains('kochi')) return 'kerala';
    if (norm.contains('gujarat') || norm.contains('ahmedabad')) {
      return 'gujarat';
    }
    if (norm.contains('uttar') ||
        norm.contains('noida') ||
        norm.contains('lucknow')) {
      return 'uttarpradesh';
    }
    if (norm.contains('bengal') || norm.contains('kolkata')) {
      return 'westbengal';
    }
    if (norm.contains('rajasthan') || norm.contains('jaipur')) {
      return 'rajasthan';
    }
    if (norm.contains('madhya') ||
        norm.contains('bhopal') ||
        norm.contains('indore')) {
      return 'madhyapradesh';
    }
    if (norm.contains('punjab')) return 'punjab';
    if (norm.contains('haryana') ||
        norm.contains('gurgaon') ||
        norm.contains('gurugram')) {
      return 'haryana';
    }
    if (norm.contains('odisha') ||
        norm.contains('orissa') ||
        norm.contains('bhubaneswar')) {
      return 'odisha';
    }
    if (norm.contains('bihar') || norm.contains('patna')) return 'bihar';
    if (norm.contains('goa')) return 'goa';
    return norm;
  }

  static String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'IN';

    final norm = _normalize(clean);
    if (norm == 'karnataka') return 'KA';
    if (norm.contains('andra') || norm.contains('andhra')) return 'AP';
    if (norm.contains('maharashtra') ||
        norm.contains('mumbai') ||
        norm.contains('pune')) {
      return 'MH';
    }
    if (norm.contains('telangana') || norm.contains('hyderabad')) return 'TS';
    if (norm.contains('tamil') || norm.contains('chennai')) return 'TN';
    if (norm.contains('ncr') || norm.contains('delhi')) return 'DL';
    if (norm.contains('kerala') || norm.contains('kochi')) return 'KL';
    if (norm.contains('gujarat')) return 'GJ';
    if (norm.contains('bengal') || norm.contains('kolkata')) return 'WB';
    if (norm.contains('rajasthan')) return 'RJ';
    if (norm.contains('uttar') || norm == 'up') return 'UP';
    if (norm.contains('madhya') || norm == 'mp') return 'MP';
    if (norm.contains('punjab')) return 'PB';
    if (norm.contains('haryana')) return 'HR';
    if (norm.contains('odisha') || norm.contains('orissa')) return 'OD';
    if (norm.contains('bihar')) return 'BR';
    if (norm.contains('goa')) return 'GA';
    if (norm.contains('hospitality')) return 'HP';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.length >= 2
        ? clean.substring(0, 2).toUpperCase()
        : clean.toUpperCase();
  }

  static String _getWikipediaTitle(String name) {
    final norm = _normalize(name);
    if (norm.contains('andra') || norm.contains('andhra')) {
      return 'Andhra_Pradesh';
    }
    if (norm.contains('karnataka')) return 'Karnataka';
    if (norm.contains('mumbai')) return 'Mumbai';
    if (norm.contains('maharashtra')) return 'Maharashtra';
    if (norm.contains('telangana')) return 'Telangana';
    if (norm.contains('tamil')) return 'Tamil_Nadu';
    if (norm.contains('ncr') || norm.contains('delhi')) return 'Delhi';
    if (norm.contains('kerala')) return 'Kerala';
    if (norm.contains('gujarat')) return 'Gujarat';
    if (norm.contains('bengal')) return 'West_Bengal';
    if (norm.contains('rajasthan')) return 'Rajasthan';
    if (norm.contains('uttar')) return 'Uttar_Pradesh';
    if (norm.contains('madhya')) return 'Madhya_Pradesh';
    if (norm.contains('punjab')) return 'Punjab';
    if (norm.contains('haryana')) return 'Haryana';
    if (norm.contains('odisha') || norm.contains('orissa')) return 'Odisha';
    if (norm.contains('bihar')) return 'Bihar';
    return name.trim().replaceAll(' ', '_');
  }

  static ({List<Color> colors, Color borderColor, Color textColor}) _getPalette(
    String name,
  ) {
    final norm = _normalize(name);
    if (norm.contains('karnataka')) {
      return (
        colors: [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        borderColor: const Color(0xFF7DD3FC),
        textColor: const Color(0xFF0369A1),
      );
    }
    if (norm.contains('andra') || norm.contains('andhra')) {
      return (
        colors: [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        borderColor: const Color(0xFFFCD34D),
        textColor: const Color(0xFFB45309),
      );
    }
    if (norm.contains('mumbai') || norm.contains('maharashtra')) {
      return (
        colors: [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
        borderColor: const Color(0xFFD8B4FE),
        textColor: const Color(0xFF7E22CE),
      );
    }
    if (norm.contains('ncr') || norm.contains('delhi')) {
      return (
        colors: [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        borderColor: const Color(0xFF93C5FD),
        textColor: const Color(0xFF1D4ED8),
      );
    }
    if (norm.contains('telangana')) {
      return (
        colors: [const Color(0xFFCCFBF1), const Color(0xFF99F6E4)],
        borderColor: const Color(0xFF5EEAD4),
        textColor: const Color(0xFF0F766E),
      );
    }
    if (norm.contains('tamil')) {
      return (
        colors: [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
        borderColor: const Color(0xFFFCA5A5),
        textColor: const Color(0xFFB91C1C),
      );
    }
    if (norm.contains('kerala')) {
      return (
        colors: [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
        borderColor: const Color(0xFF86EFAC),
        textColor: const Color(0xFF15803D),
      );
    }

    return (
      colors: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
      borderColor: const Color(0xFFCBD5E1),
      textColor: const Color(0xFF475569),
    );
  }

  // ── Bundled Local State Emblems ─────────────────────────────────────────
  static const Map<String, String> _localAssets = {
    'andhrapradesh': 'assets/icons/states/andhra_pradesh.png',
    'andrapradesh': 'assets/icons/states/andhra_pradesh.png',
    'andhra': 'assets/icons/states/andhra_pradesh.png',
    'ap': 'assets/icons/states/andhra_pradesh.png',
    'karnataka': 'assets/icons/states/karnataka.png',
    'ka': 'assets/icons/states/karnataka.png',
    'maharashtra': 'assets/icons/states/maharashtra.png',
    'mumbai': 'assets/icons/states/maharashtra.png',
    'pune': 'assets/icons/states/maharashtra.png',
    'mh': 'assets/icons/states/maharashtra.png',
    'delhi': 'assets/icons/states/delhi.png',
    'ncr': 'assets/icons/states/delhi.png',
    'newdelhi': 'assets/icons/states/delhi.png',
    'dl': 'assets/icons/states/delhi.png',
    'telangana': 'assets/icons/states/telangana.png',
    'hyderabad': 'assets/icons/states/telangana.png',
    'ts': 'assets/icons/states/telangana.png',
    'tg': 'assets/icons/states/telangana.png',
    'tamilnadu': 'assets/icons/states/tamil_nadu.png',
    'chennai': 'assets/icons/states/tamil_nadu.png',
    'tn': 'assets/icons/states/tamil_nadu.png',
    'kerala': 'assets/icons/states/kerala.png',
    'kochi': 'assets/icons/states/kerala.png',
    'kl': 'assets/icons/states/kerala.png',
    'gujarat': 'assets/icons/states/gujarat.png',
    'ahmedabad': 'assets/icons/states/gujarat.png',
    'gj': 'assets/icons/states/gujarat.png',
    'uttarpradesh': 'assets/icons/states/uttar_pradesh.png',
    'up': 'assets/icons/states/uttar_pradesh.png',
    'westbengal': 'assets/icons/states/west_bengal.png',
    'wb': 'assets/icons/states/west_bengal.png',
    'rajasthan': 'assets/icons/states/rajasthan.png',
    'rj': 'assets/icons/states/rajasthan.png',
    'madhyapradesh': 'assets/icons/states/madhya_pradesh.png',
    'mp': 'assets/icons/states/madhya_pradesh.png',
    'punjab': 'assets/icons/states/punjab.png',
    'pb': 'assets/icons/states/punjab.png',
    'haryana': 'assets/icons/states/haryana.png',
    'hr': 'assets/icons/states/haryana.png',
    'odisha': 'assets/icons/states/odisha.png',
    'od': 'assets/icons/states/odisha.png',
    'bihar': 'assets/icons/states/bihar.png',
    'br': 'assets/icons/states/bihar.png',
    'goa': 'assets/icons/states/goa.png',
    'ga': 'assets/icons/states/goa.png',
    'india': 'assets/icons/states/india.png',
  };

  // ── Network Fallback URLs ──────────────────────────────────────────────
  static const Map<String, String> _networkImageUrls = {
    'westbengal':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Seal_of_West_Bengal.svg/330px-Seal_of_West_Bengal.svg.png',
    'rajasthan':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/55/Emblem_of_India.svg/330px-Emblem_of_India.svg.png',
    'madhyapradesh':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ae/Emblem_of_Madhya_Pradesh.svg/330px-Emblem_of_Madhya_Pradesh.svg.png',
    'punjab':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Seal_of_State_of_Punjab.png/330px-Seal_of_State_of_Punjab.png',
    'haryana':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/36/Emblem_of_Haryana.svg/330px-Emblem_of_Haryana.svg.png',
    'odisha':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/10/Seal_of_Odisha.svg/330px-Seal_of_Odisha.svg.png',
    'bihar':
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e9/Seal_of_Bihar.svg/330px-Seal_of_Bihar.svg.png',
    'goa':
        'https://thumb.wikimedia.org/wikipedia/en/thumb/2/26/Emblem_of_Goa.svg/330px-Emblem_of_Goa.svg.png',
  };
}
