import 'package:flutter/material.dart';
import 'package:snoozemate/core/presentation/widgets/app_bar.dart';
import 'package:snoozemate/features/home/presentation/widgets/home_body.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeBody(context: context),
    );
  }
}
