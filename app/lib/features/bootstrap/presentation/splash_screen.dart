import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../state/bootstrap_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: bootstrap.when(
          data: (_) => const LoadingView(label: 'Preparing Fasto VPN...'),
          loading: () => const LoadingView(label: 'Loading app services...'),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(bootstrapControllerProvider),
          ),
        ),
      ),
    );
  }
}
