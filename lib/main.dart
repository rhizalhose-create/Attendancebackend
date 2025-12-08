import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/student_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/superadmin_dashboard.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Attendance System',
      theme: ThemeData(
          primaryColor: AppTheme.primaryColor,
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryColor,
            secondary: AppTheme.secondaryColor,
            error: AppTheme.errorColor,
            surface: AppTheme.cardColor,
          ),
          scaffoldBackgroundColor: AppTheme.backgroundGradientStart,
          cardTheme: CardThemeData(
            color: AppTheme.cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingSM),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingMD),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: AppTheme.primaryButtonStyle,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              textStyle: AppTheme.buttonText.copyWith(color: AppTheme.primaryColor),
      ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: AppTheme.heading3.copyWith(color: Colors.white),
          ),
          useMaterial3: true,
        ),
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/student-dashboard': (context) => StudentDashboard(),
          '/admin-dashboard': (context) => AdminDashboard(),
          '/superadmin-dashboard': (context) => SuperAdminDashboard(),
        },
      debugShowCheckedModeBanner: false,
      ),
    );
  }
}
