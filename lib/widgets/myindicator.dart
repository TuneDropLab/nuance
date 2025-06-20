import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CheckMarkColors {
  final Color content;
  final Color background;

  const CheckMarkColors({
    required this.content,
    required this.background,
  });
}

class CheckMarkStyle {
  final CheckMarkColors loading;
  final CheckMarkColors completed;

  const CheckMarkStyle({
    required this.loading,
    required this.completed,
  });

  static const defaultStyle = CheckMarkStyle(
    loading: CheckMarkColors(content: Colors.white, background: Colors.black),
    completed: CheckMarkColors(content: Colors.white, background: Colors.green),
  );
}

class CheckMarkIndicator extends StatefulWidget {
  final Widget child;
  final CheckMarkStyle style;
  final Future Function() onRefresh;

  const CheckMarkIndicator({
    super.key,
    required this.child,
    this.style = CheckMarkStyle.defaultStyle,
    required this.onRefresh,
  });

  @override
  State<CheckMarkIndicator> createState() => _CheckMarkIndicatorState();
}

class _CheckMarkIndicatorState extends State<CheckMarkIndicator>
    with SingleTickerProviderStateMixin {
  // Whether to render check mark instead of spinner
  bool _renderCompleteState = false;

  ScrollDirection prevScrollDirection = ScrollDirection.idle;

  @override
  Widget build(BuildContext context) {
    return CustomMaterialIndicator(
      withRotation: false,
      onRefresh: widget.onRefresh,
      durations: const RefreshIndicatorDurations(
        completeDuration: Duration(seconds: 2),
      ),
      onStateChanged: (change) {
        if (change.didChange(to: IndicatorState.complete)) {
          _renderCompleteState = true;
        } else if (change.didChange(to: IndicatorState.idle)) {
          _renderCompleteState = false;
        }
      },
      indicatorBuilder: (
        BuildContext context,
        IndicatorController controller,
      ) {
        final style = _renderCompleteState
            ? widget.style.completed
            : widget.style.loading;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.background,
            shape: BoxShape.circle,
          ),
          child: _renderCompleteState
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                )
              : SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: style.content,
                    value: controller.isDragging || controller.isArmed
                        ? controller.value.clamp(0.0, 1.0)
                        : null,
                  ),
                ),
        );
      },
      child: widget.child,
    );
  }
}
