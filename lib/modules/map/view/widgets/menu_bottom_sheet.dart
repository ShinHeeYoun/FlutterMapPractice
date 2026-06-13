import 'package:flutter/material.dart';

class MenuBottomSheet extends StatelessWidget {
  const MenuBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const Text(
            '메뉴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('환경 설정'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 연동할 환경 설정 로직 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('환경 설정 기능은 준비 중입니다.')),
                    );
                  },
                ),
                // 확장성을 고려하여 향후 여기에 추가 메뉴 아이템 배치 가능
              ],
            ),
          ),
        ],
      ),
    );
  }
}
