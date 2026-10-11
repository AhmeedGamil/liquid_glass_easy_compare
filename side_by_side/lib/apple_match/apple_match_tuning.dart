import 'package:flutter/widgets.dart';

/// One tunable value of an apple_match component.
class Knob {
  const Knob(
    this.id,
    this.group,
    this.label,
    this.def, {
    this.min = 0,
    this.max = 1,
    this.step = 0.01,
    this.color = false,
  });

  final String id;
  final String group;
  final String label;

  /// The tuned default: a number, or an ARGB int when [color].
  final num def;
  final double min;
  final double max;
  final double step;
  final bool color;

  Map<String, Object> toJson(num value) => {
        'id': id,
        'group': group,
        'label': label,
        'def': def,
        'value': value,
        'min': min,
        'max': max,
        'step': step,
        'kind': color ? 'color' : 'number',
      };
}

const String _glass = 'Glass material (buttons + tab bar)';
const String _button = 'Button';
const String _slider = 'Slider';
const String _switch = 'Switch';
const String _tab = 'Tab bar';

/// Every knob, with the values tuned against the native controls as
/// defaults.
const List<Knob> kKnobs = [
  Knob('glass.fillLight', _glass, 'Fill (light)', 0xADFFFFFF, color: true),
  Knob('glass.fillDark', _glass, 'Fill (dark)', 0x851C1C1E, color: true),
  Knob('glass.satLight', _glass, 'Saturation (light)', 2.0, max: 3),
  Knob('glass.satDark', _glass, 'Saturation (dark)', 1.0, max: 3),
  Knob('glass.blur', _glass, 'Blur', 8, max: 30, step: 0.5),
  Knob('glass.specThickness', _glass, 'Rim thickness', 2, max: 10, step: 0.1),
  Knob('glass.specIntensity', _glass, 'Rim intensity', 1, max: 2),
  Knob('glass.specAngle', _glass, 'Rim angle', 39, max: 360, step: 1),
  Knob('glass.specSpread', _glass, 'Rim spread', 1, max: 1),
  Knob('glass.refIndex', _glass, 'Refraction index', 1.08,
      min: 1, max: 1.5, step: 0.005),
  Knob('glass.refWidth', _glass, 'Refraction width', 12, max: 40, step: 0.5),
  Knob('button.radius', _button, 'Corner radius', 16, max: 30, step: 0.5),
  Knob('button.shadowBlur', _button, 'Shadow blur', 20, max: 40, step: 0.5),
  Knob('button.shadowOpacity', _button, 'Shadow opacity', 0.10, max: 0.5),
  Knob('button.fontSize', _button, 'Label size', 17, min: 10, max: 24, step: 0.5),
  Knob('button.fontWeight', _button, 'Label weight', 400,
      min: 100, max: 900, step: 100),
  Knob('button.prominentFill', _button, 'Prominent fill', 0xFF0088FF,
      color: true),
  Knob('slider.active', _slider, 'Active track', 0xFF0088FF, color: true),
  Knob('slider.inactiveLight', _slider, 'Track (light)', 0x2B787880,
      color: true),
  Knob('slider.inactiveDark', _slider, 'Track (dark)', 0x3B787880,
      color: true),
  Knob('slider.trackHeight', _slider, 'Track height', 6,
      min: 2, max: 12, step: 0.5),
  Knob('slider.thumbWidth', _slider, 'Thumb width', 37,
      min: 20, max: 60, step: 0.5),
  Knob('slider.thumbHeight', _slider, 'Thumb height', 24,
      min: 16, max: 40, step: 0.5),
  Knob('slider.shadowBlur', _slider, 'Thumb shadow blur', 8,
      max: 30, step: 0.5),
  Knob('slider.shadowOpacity', _slider, 'Thumb shadow opacity', 0.12,
      max: 0.5),
  Knob('slider.shadowOffset', _slider, 'Thumb shadow drop', 0,
      min: -5, max: 10, step: 0.5),
  Knob('switch.activeLight', _switch, 'On (light)', 0xFF34C759, color: true),
  Knob('switch.activeDark', _switch, 'On (dark)', 0xFF30D158, color: true),
  Knob('switch.inactiveLight', _switch, 'Off (light)', 0x6B787880,
      color: true),
  Knob('switch.inactiveDark', _switch, 'Off (dark)', 0xA3787880, color: true),
  Knob('tab.width', _tab, 'Width', 328, min: 200, max: 400, step: 1),
  Knob('tab.height', _tab, 'Height', 62, min: 44, max: 80, step: 1),
  Knob('tab.itemPadding', _tab, 'Pill inset', 4, max: 12, step: 0.5),
  Knob('tab.iconSize', _tab, 'Icon size', 28, min: 16, max: 36, step: 0.5),
  Knob('tab.labelSize', _tab, 'Label size', 10, min: 8, max: 14, step: 0.5),
  Knob('tab.labelWeight', _tab, 'Label weight', 600,
      min: 100, max: 900, step: 100),
  Knob('tab.selectedLight', _tab, 'Selected (light)', 0xFF0088FF,
      color: true),
  Knob('tab.selectedDark', _tab, 'Selected (dark)', 0xFF0091FF, color: true),
  Knob('tab.pillColor', _tab, 'Selection pill', 0x2EAEAEB2, color: true),
  Knob('tab.shadowBlur', _tab, 'Shadow blur', 24, max: 40, step: 0.5),
  Knob('tab.shadowOpacity', _tab, 'Shadow opacity', 0.12, max: 0.5),
];

/// Live values for [kKnobs]. The tuner page changes them at runtime; the
/// apple_match components read them in build and rebuild through
/// [AppleMatchTuningScope].
class AppleMatchTuning {
  static final ValueNotifier<Map<String, num>> overrides =
      ValueNotifier<Map<String, num>>(const {});

  static final Map<String, Knob> _byId = {for (final k in kKnobs) k.id: k};

  static num value(String id) => overrides.value[id] ?? _byId[id]!.def;

  static double d(String id) => value(id).toDouble();

  static Color c(String id) => Color(value(id).toInt());

  static FontWeight w(String id) =>
      FontWeight.values[((d(id) / 100).round() - 1).clamp(0, 8)];

  /// Makes [context] rebuild when any knob changes.
  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppleMatchTuningScope>();

  static List<Map<String, Object>> toJson() =>
      [for (final k in kKnobs) k.toJson(value(k.id))];

  /// Applies `{id: value}`; unknown ids are ignored.
  static void apply(Map<String, Object?> changes) {
    final Map<String, num> next = Map.of(overrides.value);
    changes.forEach((id, v) {
      if (_byId.containsKey(id) && v is num) next[id] = v;
    });
    overrides.value = next;
  }

  static void reset() => overrides.value = const {};
}

/// Rebuilds the apple_match components below it when a knob changes.
class AppleMatchTuningScope extends InheritedNotifier<ValueNotifier<Map<String, num>>> {
  AppleMatchTuningScope({super.key, required super.child})
      : super(notifier: AppleMatchTuning.overrides);
}
