import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/services/balance_service.dart';
import 'package:expense_tracker/services/income_service.dart';
import 'package:expense_tracker/services/budget_service.dart';
import 'package:expense_tracker/screens/auth_wrapper.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/add_debt_screen.dart';

Future<FirebaseApp> _initializeFirebase() async {
  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    developer.log('Firebase initialization error: $error', name: 'App');
    developer.log('Stack trace: $stackTrace', name: 'App');
    // Re-throw the error to be handled by the FutureBuilder
    rethrow;
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    developer.log('Error initializing Firebase: $e', name: 'App');
    developer.log('Stack trace: $stackTrace', name: 'App');
    // Continue with app initialization even if Firebase fails
  }
  
  // Initialize app
  runApp(const MyApp());
}

class AppProviders extends StatelessWidget {
  final Widget child;
  
  const AppProviders({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          developer.log('Firebase initialization error: ${snapshot.error}', name: 'App');
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Failed to initialize Firebase'),
              ),
            ),
          );
        }
        
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthService()),
            ChangeNotifierProvider(create: (_) => BalanceService()),
            Provider(create: (_) => ExpenseService()),
            Provider(create: (_) => DebtService()),
            Provider(create: (_) => IncomeService()),
            Provider(create: (_) => BudgetService()),
          ],
          child: child,
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: 'NIMO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        home: const AuthWrapper(),
        routes: {
          '/add-expense': (context) => const AddExpenseScreen(),
          '/add-debt': (context) => AddDebtScreen(
                debtService: Provider.of<DebtService>(context, listen: false),
              ),
        },
      ),
    );
  }
}
