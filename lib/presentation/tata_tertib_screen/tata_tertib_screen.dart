import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/tata_tertib_bloc.dart';

class TataTertibScreen extends StatefulWidget {
  final int? jalurId;

  const TataTertibScreen({super.key, this.jalurId});
  @override
  State<TataTertibScreen> createState() => _TataTertibState();
}

class _TataTertibState extends State<TataTertibScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event untuk load data
    context.read<TataTertibBloc>().add(TataTertibInitialEvent(widget.jalurId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TataTertibBloc, TataTertibState>(
      builder: (context, state) {
        // Print state untuk debugging
        print('Current TataTertib State:');
        print('Loading: ${state.isLoading}');
        print('Error: ${state.errorMessage}');
        print('Number of Tata Tertib: ${state.tataTertibs.length}');
        state.tataTertibs.forEach((tataTertib) {
          print('Tata Tertib Description: ${tataTertib.description}');
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
                  else if (state.tataTertibs.isEmpty)
                    const Center(
                      child: Text('Tidak ada tata tertib'),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.tataTertibs.length,
                        itemBuilder: (context, index) {
                          final tataTertib = state.tataTertibs[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: Text(
                              tataTertib.description,
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
