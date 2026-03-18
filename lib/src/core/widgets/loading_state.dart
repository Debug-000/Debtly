import 'package:flutter/material.dart';

import '../design/tokens.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              color: accent.primary,
              backgroundColor: AppPalette.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Loading Debtly',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
