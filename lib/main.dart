import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/phone_home.dart';

void main() {
  runApp(const FlowFitPhoneApp());
}

class FlowFitPhoneApp extends StatelessWidget {
  const FlowFitPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TFLiteActivityClassifier>(
          create: (_) => TFLiteActivityClassifier(),
        ),
        // Data layer
        ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
          create: (context) => TFLiteActivityRepository(
            context.read<TFLiteActivityClassifier>(),
          ),
          update: (_, classifier, __) => TFLiteActivityRepository(classifier),
        ),
        // Domain layer
        ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
          create: (context) =>
              ClassifyActivityUseCase(context.read<TFLiteActivityRepository>()),
          update: (_, repository, __) => ClassifyActivityUseCase(repository),
        ),
        // Presentation layer
        ChangeNotifierProxyProvider<
          ClassifyActivityUseCase,
          ActivityClassifierViewModel
        >(
          create: (context) => ActivityClassifierViewModel(
            context.read<ClassifyActivityUseCase>(),
          ),
          update: (_, useCase, __) => ActivityClassifierViewModel(useCase),
        ),
      ],
      child: MaterialApp(
        title: 'FlowFit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const PhoneHomePage(),
      ),
    );
  }
}
