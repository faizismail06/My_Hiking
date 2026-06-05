import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/rules_bloc.dart';

class RulesScreen extends StatefulWidget {
  final int? jalurId;

  const RulesScreen({super.key, this.jalurId});
  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event untuk load data
    context.read<RulesBloc>().add(RulesInitialEvent(widget.jalurId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RulesBloc, RulesState>(
      builder: (context, state) {
        // Print state untuk debugging
        print('Current Rules State:');
        print('Loading: ${state.isLoading}');
        print('Error: ${state.errorMessage}');
        print('Number of Rules: ${state.rules.length}');
        state.rules.forEach((rule) {
          print('Rule Description: ${rule.description}');
        });

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Tata Tertib",
                style: CustomTextStyles.titleSmallBlack90015,
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                horizontal: 32.h,
                vertical: 16.h,
              ),
              child: Column(
                children: [
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (state.errorMessage != null)
                    Center(
                      child: Text(
                        state.errorMessage!,
                        style: CustomTextStyles.bodySmallBlack90011,
                      ),
                    )
                  else if (state.rules.isEmpty)
                    const Center(
                      child: Text('Tidak ada tata tertib'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.rules.length,
                        itemBuilder: (context, index) {
                          final rule = state.rules[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Text(
                              rule.description,
                              style:
                                  CustomTextStyles.bodySmallBlack90011.copyWith(
                                height: 1.40,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
