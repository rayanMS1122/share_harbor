import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_harbor/share_harbor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShareHarborApp());
}

class ShareHarborApp extends StatelessWidget {
  const ShareHarborApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareHarbor Inbox',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2E2E2E)),
          ),
        ),
      ),
      home: const InboxScreen(),
    );
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
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
      _showSnack('Initialization error: $e', isError: true);
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
      _showSnack('Refresh error: $e', isError: true);
    }
  }

  Future<void> _processDelivery(ShareDelivery delivery) async {
    if (_harbor == null) return;
    setState(() => _isLoading = true);

    try {
      final claim = await _harbor!.claim(delivery.deliveryId);

      // Business processing
      await Future.delayed(const Duration(milliseconds: 400));

      await _harbor!.ack(claim);
      _showSnack('Imported & acknowledged');
      await _refreshInbox();
    } catch (e) {
      _showSnack('Processing failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _releaseDelivery(ShareDelivery delivery) async {
    if (_harbor == null) return;
    try {
      final claim = await _harbor!.claim(delivery.deliveryId);
      await _harbor!.release(claim, reason: 'Released in UI');
      _showSnack('Delivery released back to queue');
      await _refreshInbox();
    } catch (e) {
      _showSnack('Release failed: $e', isError: true);
    }
  }

  Future<void> _purgeStorage() async {
    if (_harbor == null) return;
    try {
      final result = await _harbor!.cleanup();
      _showSnack(
          'Cleaned ${result.deletedDeliveriesCount} items (${_formatBytes(result.reclaimedBytes)})');
      await _refreshInbox();
    } catch (e) {
      _showSnack('Cleanup failed: $e', isError: true);
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ItemDetailSheet(
          delivery: delivery,
          item: item,
          payloadPath: payloadPath,
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShareHarbor Inbox',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshInbox,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Purge Old Storage',
            onPressed: _purgeStorage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          if (_health != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  _StatusItem(
                    label: 'Pending',
                    value: '${_health!.pendingCount}',
                  ),
                  const SizedBox(width: 24),
                  _StatusItem(
                    label: 'Claimed',
                    value: '${_health!.claimedCount}',
                  ),
                  const SizedBox(width: 24),
                  _StatusItem(
                    label: 'Storage',
                    value: _formatBytes(_health!.totalStorageBytes),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: Color(0xFF2E2E2E)),

          if (_isLoading)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(),
            ),

          // Main Deliveries List
          Expanded(
            child: _deliveries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No pending share items',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share text, URLs, or files from another app',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = _deliveries[index];
                      return DeliveryTileCard(
                        delivery: delivery,
                        onImport: () => _processDelivery(delivery),
                        onRelease: () => _releaseDelivery(delivery),
                        onItemTap: (item) => _inspectItemDetail(delivery, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatusItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class DeliveryTileCard extends StatelessWidget {
  final ShareDelivery delivery;
  final VoidCallback onImport;
  final VoidCallback onRelease;
  final Function(ShareItem) onItemTap;

  const DeliveryTileCard({
    super.key,
    required this.delivery,
    required this.onImport,
    required this.onRelease,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = delivery.receivedAtUtc.toIso8601String().length >= 19
        ? delivery.receivedAtUtc.toIso8601String().substring(11, 19)
        : delivery.receivedAtUtc.toIso8601String();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    delivery.platform.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x661E3A8A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    delivery.state.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade300,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (delivery.text != null && delivery.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                delivery.text!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ],
            const SizedBox(height: 10),
            ...delivery.items.map(
              (item) => InkWell(
                onTap: () => onItemTap(item),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getIcon(item.kind),
                        size: 16,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.originalName ?? item.itemId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      Text(
                        _formatBytes(item.byteLength),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRelease,
                  child: const Text('Release'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Import & Ack'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(ShareItemKind kind) {
    switch (kind) {
      case ShareItemKind.image:
        return Icons.image;
      case ShareItemKind.video:
        return Icons.videocam;
      case ShareItemKind.url:
        return Icons.link;
      case ShareItemKind.text:
        return Icons.subject;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ItemDetailSheet extends StatelessWidget {
  final ShareDelivery delivery;
  final ShareItem item;
  final String? payloadPath;

  const ItemDetailSheet({
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.kind == ShareItemKind.image
                      ? Icons.image
                      : Icons.insert_drive_file,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.originalName ?? 'Payload Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isImage)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(payloadPath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            _row('MIME Type', item.resolvedMimeType ?? 'Unknown'),
            _row('Size', '${item.byteLength} Bytes'),
            _row('Internal ID', item.itemId),
            if (payloadPath != null) _row('Path', payloadPath!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
