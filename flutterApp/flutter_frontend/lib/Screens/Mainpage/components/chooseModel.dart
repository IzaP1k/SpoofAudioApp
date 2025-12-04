import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:toggle_switch/toggle_switch.dart';

class ModelSelector extends StatefulWidget {
  final List<Map<String, String>> models;
  final void Function(String modelName, int index) onSelected;
  final int initialSelectedIndex;

  const ModelSelector({
    super.key,
    required this.models,
    required this.onSelected,
    this.initialSelectedIndex = 0,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  late int selectedIndex;

  bool hoverLeft = false;
  bool hoverRight = false;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  @override
  void didUpdateWidget(covariant ModelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedIndex != widget.initialSelectedIndex) {
      setState(() => selectedIndex = widget.initialSelectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHoverRegion(
              index: 0,
              hover: hoverLeft,
              onHoverChange: (value) => setState(() => hoverLeft = value),
            ),
            ToggleSwitch(
              minWidth: 80.0,
              cornerRadius: 20.0,
              totalSwitches: widget.models.length,
              labels: widget.models.map((m) => m['name']!).toList(),
              activeFgColor: Colors.white,
              inactiveFgColor: Colors.black,
              inactiveBgColor: kPrimaryLightColor,
              activeBgColors: const [
                [kPrimaryColor],
                [kPrimaryColor],
              ],
              initialLabelIndex: selectedIndex,
              radiusStyle: true,
              onToggle: (index) {
                if (index == null) return;
                setState(() => selectedIndex = index);
                widget.onSelected(widget.models[index]['name']!, index);
              },
            ),
            _buildHoverRegion(
              index: 1,
              hover: hoverRight,
              onHoverChange: (value) => setState(() => hoverRight = value),
            ),
          ],
        ),

        // Tooltipy w nadrzędnym Stacku
        _buildTooltipOverlay(0, hoverLeft),
        _buildTooltipOverlay(1, hoverRight),
      ],
    );
  }

  Widget _buildHoverRegion({
    required int index,
    required bool hover,
    required void Function(bool) onHoverChange,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.info_outline, size: 26),
      ),
    );
  }

  Widget _buildTooltipOverlay(int index, bool hover) {
    if (widget.models.length <= index) return const SizedBox.shrink();

    return Positioned(
      top: -60,
      left: index == 0 ? 0 : null,
      right: index == 1 ? 0 : null,
      child: MouseRegion(
        onEnter: (_) => setState(() {
          if (index == 0) hoverLeft = true;
          if (index == 1) hoverRight = true;
        }),
        onExit: (_) => setState(() {
          if (index == 0) hoverLeft = false;
          if (index == 1) hoverRight = false;
        }),
        child: Visibility(
          visible: hover,
          child: _buildTooltip(widget.models[index]['info'] ?? "Brak opisu"),
        ),
      ),
    );
  }

  Widget _buildTooltip(String text) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
