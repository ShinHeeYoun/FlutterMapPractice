import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database_helper.dart';
import '../model/alarm_history_model.dart';
import 'alarm_history_detail_screen.dart';

class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({super.key});

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  List<AlarmHistoryModel> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    final data = await DatabaseHelper.instance.getAllCompletedHistories();
    setState(() {
      _histories = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteHistory(int id) async {
    await DatabaseHelper.instance.deleteHistory(id);
    _loadHistories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용 내역 및 통계'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? const Center(child: Text('기록된 이용 내역이 없습니다.'))
              : ListView.separated(
                  itemCount: _histories.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final history = _histories[index];
                    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(history.date);
                    
                    return Dismissible(
                      key: Key(history.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteHistory(history.id!);
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          '$dateStr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('출발: ${history.startName}'),
                              Text('도착: ${history.endName}'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _StatChip(icon: Icons.timer, label: '${(history.totalTimeSeconds / 60).toStringAsFixed(1)} 분'),
                                  _StatChip(icon: Icons.straighten, label: '${(history.distanceMeters / 1000).toStringAsFixed(2)} km'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlarmHistoryDetailScreen(history: history),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueAccent),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
