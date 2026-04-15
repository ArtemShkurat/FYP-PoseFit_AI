import 'package:flutter/material.dart';
// import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomNavigationBar: const BottomNavBar(currentIndex: 0),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              const Text(
                'Hi, [Name]!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Ready for your workout?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // 🔵 MAIN BUTTON (Camera)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/camera');
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: const Text(
                    'Start Exercise Detection',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔵 OPTIONS
              Row(
                children: [
                  Expanded(
                    child: _HomeOptionCard(
                      icon: Icons.fitness_center,
                      label: 'Browse\nExercises',
                      onTap: () {
                        Navigator.pushNamed(context, '/exercises');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeOptionCard(
                      icon: Icons.history,
                      label: 'Workout\nHistory',
                      onTap: () {
                        Navigator.pushNamed(context, '/logs');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeOptionCard(
                      icon: Icons.edit_note,
                      label: 'Manual\nLog',
                      onTap: () {
                        Navigator.pushNamed(context, '/logs');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Last Workout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // 🔵 LAST WORKOUT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new, size: 40),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biceps Curl - 10kg',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '3 x 12 reps - 00/00/0000',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}