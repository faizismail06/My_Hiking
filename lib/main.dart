import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_export.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    PrefUtils().init();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return BlocProvider(
          create: (context) => ThemeBloc(
            ThemeState(themeType: PrefUtils().getThemeData()),
          ),
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return MaterialApp(
                theme: theme,
                title: 'myhiking',
                navigatorKey: NavigatorService.navigatorKey,
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  AppLocalizationDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                ],
                initialRoute: AppRoutes.initialRoute,
                routes: AppRoutes.routes,
                onGenerateRoute: (settings) {
                  final routeBuilder = AppRoutes.routes[settings.name];
                  if (routeBuilder != null) {
                    return MaterialPageRoute(
                      builder: routeBuilder,
                      settings: settings,
                    );
                  }

                  return MaterialPageRoute(
                    builder: AppRoutes.routes[AppRoutes.landingScreen]!,
                    settings: const RouteSettings(name: AppRoutes.landingScreen),
                  );
                },
                onUnknownRoute: (settings) {
                  return MaterialPageRoute(
                    builder: AppRoutes.routes[AppRoutes.landingScreen]!,
                    settings: const RouteSettings(name: AppRoutes.landingScreen),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:device_preview/device_preview.dart'; // Import Device Preview
// import 'core/app_export.dart';

// var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();

//   Future.wait([
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
//   ]).then((value) {
//     PrefUtils().init();
//     runApp(
//       DevicePreview(
//         enabled: !kReleaseMode, // Aktif hanya pada mode debug
//         builder: (context) => const MyApp(), // Aplikasi di dalam DevicePreview
//       ),
//     );
//   });
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Sizer(
//       builder: (context, orientation, deviceType) {
//         return BlocProvider(
//           create: (context) => ThemeBloc(
//             ThemeState(themeType: PrefUtils().getThemeData()),
//           ),
//           child: BlocBuilder<ThemeBloc, ThemeState>(
//             builder: (context, state) {
//               return MaterialApp(
//                 theme: theme,
//                 title: 'myhiking',
//                 navigatorKey: NavigatorService.navigatorKey,
//                 debugShowCheckedModeBanner: false,
//                 useInheritedMediaQuery:
//                     true, // Ini penting untuk Device Preview
//                 locale: DevicePreview.locale(
//                     context), // Locale responsif sesuai Device Preview
//                 builder: DevicePreview
//                     .appBuilder, // App builder untuk Device Preview
//                 localizationsDelegates: const [
//                   AppLocalizationDelegate(),
//                   GlobalMaterialLocalizations.delegate,
//                   GlobalWidgetsLocalizations.delegate,
//                   GlobalCupertinoLocalizations.delegate,
//                 ],
//                 supportedLocales: const [
//                   Locale('en', ''),
//                 ],
//                 initialRoute: AppRoutes.initialRoute,
//                 routes: AppRoutes.routes,
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
