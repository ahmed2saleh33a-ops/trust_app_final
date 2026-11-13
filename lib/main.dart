import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/notification_provider.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  // تهيئة SupabaseService
  await SupabaseService.initialize();
  
  // تهيئة خدمات الإشعارات
  try {
    await NotificationService.initialize();
    print("✅ NotificationService initialized successfully");
  } catch (e) {
    print("⚠️ NotificationService not available: $e");
  }
  
  // تعيين الاتجاهات المسموحة للشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const TrustCenterApp());
}

class TrustCenterApp extends StatelessWidget {
  const TrustCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<AuthProvider, DataProvider>(
        builder: (context, authProvider, dataProvider, _) {
          // ربط AuthProvider مع DataProvider بعد اكتمال البناء
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!authProvider.isInitialized) {
              authProvider.setDataProvider(dataProvider);
              authProvider.loadLoginState();
            }
          });
          
          return MaterialApp(
            title: 'سمايل كوزمتك',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }
                return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}