import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/module_provider.dart';

class ModuleSummaryWidget extends StatelessWidget {
  final String moduleId;

  const ModuleSummaryWidget({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Ce widget n'est plus utilisé
  }
}
