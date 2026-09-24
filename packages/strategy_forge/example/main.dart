import 'package:flutter/material.dart';
import 'package:strategy_forge/strategy_forge.dart';

void main() => runApp(const StrategyForgeExample());

class StrategyForgeExample extends StatelessWidget {
  const StrategyForgeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strategy Forge example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0b5b8c)),
        useMaterial3: true,
      ),
      home: const StrategyBoardPage(),
    );
  }
}

class StrategyBoardPage extends StatefulWidget {
  const StrategyBoardPage({super.key});

  @override
  State<StrategyBoardPage> createState() => _StrategyBoardPageState();
}

class _StrategyBoardPageState extends State<StrategyBoardPage> {
  late final StrategyEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StrategyEditorController(
      config: StrategyEditorConfig(
        id: 'example_board',
        name: 'Example board',
        layouts: [
          StrategyLayout(
            id: 'training_area',
            label: 'Training area',
            aspectRatio: 16 / 9,
            builder: (_) => const _TrainingArea(),
            thumbnailBuilder: (_) => const Icon(Icons.grid_on_outlined),
          ),
        ],
        tools: StrategyToolCatalog.selectByIds(const [
          'select',
          'freehand',
          'freehand_arrow',
          'dashed_arrow',
          'rectangle',
          'ellipse',
          'text',
          'team_home',
          'team_away',
          'equipment_cone',
          'target_goal',
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Strategy Forge')),
      body: SafeArea(child: StrategyEditor(controller: _controller)),
    );
  }
}

class _TrainingArea extends StatelessWidget {
  const _TrainingArea();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xffe7f3e9),
      child: CustomPaint(painter: _TrainingAreaPainter()),
    );
  }
}

class _TrainingAreaPainter extends CustomPainter {
  const _TrainingAreaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff2c7a4b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inset = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);
    canvas.drawRect(inset, paint);
    canvas.drawLine(
      Offset(size.width / 2, 16),
      Offset(size.width / 2, size.height - 16),
      paint,
    );
    canvas.drawCircle(size.center(Offset.zero), size.height * 0.16, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
