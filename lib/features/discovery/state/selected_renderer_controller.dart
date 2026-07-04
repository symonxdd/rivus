import 'package:dart_cast/dart_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The renderer the user has picked to cast to, if any.
final NotifierProvider<SelectedRendererController, CastDevice?>
selectedRendererProvider =
    NotifierProvider<SelectedRendererController, CastDevice?>(
      SelectedRendererController.new,
    );

class SelectedRendererController extends Notifier<CastDevice?> {
  @override
  CastDevice? build() => null;

  void select(CastDevice device) => state = device;
}
