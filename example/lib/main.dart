import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_harbor/share_harbor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShareHarborShowcaseApp());
}

class ShareHarborShowcaseApp extends StatelessWidget {
  const ShareHarborShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareHarbor Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
          onSurface: Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0x1AFFFFFF),
              width: 1,
            ),
          ),
        ),
      ),
      home: const MainInboxScreen(),
    );
  }
}

class MainInboxScreen extends StatefulWidget {
  const MainInboxScreen({super.key});

  @override
  State<MainInboxScreen> createState() => _MainInboxScreenState();
}

class _MainInboxScreenState extends State<MainInboxScreen> {
  ShareHarborApi? _harbor;
  List<ShareDelivery> _deliveries = [];
  ShareHarborHealth? _health;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initHarbor();
  }

  Future<void> _initHarbor() async {
    setState(() => _isLoading = true);
    try {
      final harbor = await ShareHarbor.open();
      _harbor = harbor;

      harbor.changes.listen((_) {
        _refreshInbox();
      });

      await _refreshInbox();
    } catch (e) {
      _showToast('Initialization Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshInbox() async {
    if (_harbor == null) return;
    try {
      final pending = await _harbor!.pending();
      final health = await _harbor!.inspect();
      setState(() {
        _deliveries = pending;
        _health = health;
      });
    } catch (e) {
      _showToast('Failed to refresh inbox: $e', isError: true);
    }
  }

  Future<void> _processDelivery(ShareDelivery delivery) async {
    if (_harbor == null) return;
    setState(() => _isLoading = true);

    try {
      final claim = await _harbor!.claim(delivery.deliveryId);
      _showToast('Claimed ${claim.deliveryId.substring(0, 8)}...');

      await Future.delayed(const Duration(milliseconds: 600));

      await _harbor!.ack(claim);
      _showToast('Successfully imported & acknowledged!');
      await _refreshInbox();
    } catch (e) {
      _showToast('Processing Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _releaseDelivery(ShareDelivery delivery) async {
    if (_harbor == null) return;
    try {
      final claim = await _harbor!.claim(delivery.deliveryId);
      await _harbor!.release(claim, reason: 'User cancelled in UI');
      _showToast('Released claim back to queue');
      await _refreshInbox();
    } catch (e) {
      _showToast('Release Error: $e', isError: true);
    }
  }

  Future<void> _purgeStorage() async {
    if (_harbor == null) return;
    try {
      final result = await _harbor!.cleanup();
      _showToast(
          'Cleaned ${result.deletedDeliveriesCount} items (${(result.reclaimedBytes / 1024).toStringAsFixed(1)} KB)');
      await _refreshInbox();
    } catch (e) {
      _showToast('Cleanup failed: $e', isError: true);
    }
  }

  void _inspectItemDetail(ShareDelivery delivery, ShareItem item) async {
    if (_harbor == null) return;
    String? payloadPath;
    try {
      payloadPath = await _harbor!.getPayloadPath(
        item,
        deliveryId: delivery.deliveryId,
      );
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ItemDetailModal(
          delivery: delivery,
          item: item,
          payloadPath: payloadPath,
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Hero Banner
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33FFFFFF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.anchor_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ShareHarbor',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Durable Inbound Share Inbox',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white),
                              onPressed: _refreshInbox,
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Health Analytics Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x4D000000),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: const Color(0x26FFFFFF)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(
                                label: 'Pending',
                                value: '${_health?.pendingCount ?? 0}',
                                icon: Icons.inbox_rounded,
                                color: Colors.amberAccent,
                              ),
                              Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white24),
                              _buildMetric(
                                label: 'Claimed',
                                value: '${_health?.claimedCount ?? 0}',
                                icon: Icons.lock_clock_rounded,
                                color: Colors.cyanAccent,
                              ),
                              Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white24),
                              _buildMetric(
                                label: 'Storage',
                                value: _formatBytes(
                                    _health?.totalStorageBytes ?? 0),
                                icon: Icons.sd_storage_rounded,
                                color: Colors.purpleAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFF1E293B),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INBOX DELIVERIES',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _purgeStorage,
                    icon: const Icon(Icons.cleaning_services_rounded,
                        size: 16),
                    label: const Text('Purge Expired'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEC4899),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _deliveries.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.all_inbox_rounded,
                          size: 64,
                          color: Color(0x33FFFFFF),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your inbox is empty',
                          style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Share photos, links, or documents from other apps (Gallery, Chrome, Files) to test ShareHarbor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final delivery = _deliveries[index];
                        return DeliveryCard(
                          delivery: delivery,
                          onImport: () => _processDelivery(delivery),
                          onRelease: () => _releaseDelivery(delivery),
                          onItemTap: (item) => _inspectItemDetail(delivery, item),
                        );
                      },
                      childCount: _deliveries.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DeliveryCard extends StatelessWidget {
  final ShareDelivery delivery;
  final VoidCallback onImport;
  final VoidCallback onRelease;
  final Function(ShareItem) onItemTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onImport,
    required this.onRelease,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: delivery.platform == 'android'
                            ? const Color(0x264ADE80)
                            : const Color(0x2638BDF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: delivery.platform == 'android'
                              ? Colors.greenAccent
                              : Colors.lightBlueAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            delivery.platform == 'android'
                                ? Icons.android
                                : Icons.apple,
                            size: 14,
                            color: delivery.platform == 'android'
                                ? Colors.greenAccent
                                : Colors.lightBlueAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            delivery.platform.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: delivery.platform == 'android'
                                  ? Colors.greenAccent
                                  : Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26F59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        delivery.state.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  delivery.receivedAtUtc.toIso8601String().length >= 19
                      ? delivery.receivedAtUtc.toIso8601String().substring(11, 19)
                      : delivery.receivedAtUtc.toIso8601String(),
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (delivery.text != null && delivery.text!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x40000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  delivery.text!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            const Text(
              'ATTACHED ITEMS (TAP FOR DETAIL & PREVIEW)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0x80FFFFFF),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            ...delivery.items.map(
              (item) => ItemTile(
                item: item,
                onTap: () => onItemTap(item),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.download_done_rounded, size: 18),
                    label: const Text('IMPORT & ACK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onRelease,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('RELEASE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ItemTile extends StatelessWidget {
  final ShareItem item;
  final VoidCallback onTap;

  const ItemTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getKindColor(item.kind);
    final icon = _getKindIcon(item.kind);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.originalName ?? item.itemId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${item.resolvedMimeType ?? "unknown"} • ${_formatBytes(item.byteLength)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0x80FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getKindColor(ShareItemKind kind) {
    switch (kind) {
      case ShareItemKind.image:
        return Colors.cyanAccent;
      case ShareItemKind.video:
        return Colors.pinkAccent;
      case ShareItemKind.text:
      case ShareItemKind.url:
        return Colors.tealAccent;
      case ShareItemKind.html:
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getKindIcon(ShareItemKind kind) {
    switch (kind) {
      case ShareItemKind.image:
        return Icons.image_rounded;
      case ShareItemKind.video:
        return Icons.movie_rounded;
      case ShareItemKind.text:
        return Icons.notes_rounded;
      case ShareItemKind.url:
        return Icons.link_rounded;
      case ShareItemKind.html:
        return Icons.html_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ItemDetailModal extends StatelessWidget {
  final ShareDelivery delivery;
  final ShareItem item;
  final String? payloadPath;

  const ItemDetailModal({
    super.key,
    required this.delivery,
    required this.item,
    this.payloadPath,
  });

  @override
  Widget build(BuildContext context) {
    final bool isImage = item.kind == ShareItemKind.image &&
        payloadPath != null &&
        File(payloadPath!).existsSync();
    final bool isUrl = item.kind == ShareItemKind.url ||
        (delivery.text != null && delivery.text!.startsWith('http'));

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                item.kind == ShareItemKind.image
                    ? Icons.image_rounded
                    : isUrl
                        ? Icons.link_rounded
                        : Icons.description_rounded,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.originalName ?? 'Shared Payload Item',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image Preview Container
          if (isImage)
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(payloadPath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Link Preview Container
          if (isUrl && delivery.text != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0x266366F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.tealAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      delivery.text!,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Metadata Table
          _buildMetaRow('Item ID', item.itemId),
          _buildMetaRow('Internal Name', item.internalName),
          _buildMetaRow('MIME Type', item.resolvedMimeType ?? 'Unknown'),
          _buildMetaRow('Byte Size', '${item.byteLength} Bytes'),
          if (payloadPath != null) _buildMetaRow('File Path', payloadPath!),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CLOSE PREVIEW'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
