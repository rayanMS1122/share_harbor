import 'package:flutter/material.dart';
import 'package:share_harbor/share_harbor.dart';

void main() {
  runApp(const ShareHarborExampleApp());
}

class ShareHarborExampleApp extends StatelessWidget {
  const ShareHarborExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareHarbor Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
  String? _statusMessage;

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
        _refresh();
      });

      await _refresh();
    } catch (e) {
      setState(() => _statusMessage = 'Error initializing ShareHarbor: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_harbor == null) return;
    try {
      final pending = await _harbor!.pending();
      final health = await _harbor!.inspect();
      setState(() {
        _deliveries = pending;
        _health = health;
        _statusMessage = 'Inbox updated (${pending.length} pending)';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Failed to fetch pending items: $e');
    }
  }

  Future<void> _processDelivery(ShareDelivery delivery) async {
    if (_harbor == null) return;
    setState(() => _isLoading = true);

    try {
      final claim = await _harbor!.claim(delivery.deliveryId);
      setState(() => _statusMessage = 'Claimed delivery ${claim.deliveryId}');

      // Simulate business processing
      await Future.delayed(const Duration(seconds: 1));

      await _harbor!.ack(claim);
      setState(
          () => _statusMessage = 'Acknowledged & imported ${claim.deliveryId}');
      await _refresh();
    } catch (e) {
      setState(() => _statusMessage = 'Processing failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanup() async {
    if (_harbor == null) return;
    try {
      final result = await _harbor!.cleanup();
      setState(() {
        _statusMessage =
            'Cleaned ${result.deletedDeliveriesCount} deliveries (${result.reclaimedBytes} bytes reclaimed)';
      });
      await _refresh();
    } catch (e) {
      setState(() => _statusMessage = 'Cleanup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShareHarbor Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _cleanup,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_health != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Pending: ${_health!.pendingCount}'),
                  Text('Claimed: ${_health!.claimedCount}'),
                  Text('Storage: ${_health!.totalStorageBytes} B'),
                ],
              ),
            ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _deliveries.isEmpty
                ? const Center(
                    child: Text('No pending share deliveries in inbox.'),
                  )
                : ListView.builder(
                    itemCount: _deliveries.length,
                    itemBuilder: (context, index) {
                      final d = _deliveries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('Delivery ID: ${d.deliveryId}'),
                          subtitle: Text(
                            'Platform: ${d.platform} | Items: ${d.items.length}\nText: ${d.text ?? "None"}',
                          ),
                          trailing: ElevatedButton(
                            child: const Text('Import & ACK'),
                            onPressed: () => _processDelivery(d),
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
