import 'package:flutter/material.dart';

class NativeAdPlaceholder extends StatelessWidget {
  final bool show;

  const NativeAdPlaceholder({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.campaign_outlined),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ad slot placeholder (native). This area can host a Google native ad for free users.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
