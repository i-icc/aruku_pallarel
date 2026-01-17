import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

extension RouterX on BuildContext {
  StackRouter get router => AutoRouter.of(this);
}
