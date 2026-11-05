import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/storage_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_shell_screen.dart';
import '../screens/employee/employee_shell_screen.dart';
import '../screens/communication/chat_screen.dart';
import '../screens/communication/call_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) {
    final token = StorageService.getToken();
    final role = StorageService.getUserRole();
    final isLoggingIn = state.uri.path == '/login';

    if (token == null || token.isEmpty) {
      return isLoggingIn ? null : '/login';
    }

    if (state.uri.path == '/') {
      if (role == 'admin') {
        return '/admin';
      } else {
        return '/employee';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminShellScreen(),
    ),
    GoRoute(
      path: '/employee',
      builder: (context, state) => const EmployeeShellScreen(),
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = int.tryParse(state.pathParameters['userId'] ?? '1') ?? 1;
        return ChatScreen(contactUserId: userId);
      },
    ),
    GoRoute(
      path: '/call/:userId',
      builder: (context, state) {
        final userId = int.tryParse(state.pathParameters['userId'] ?? '1') ?? 1;
        final name = state.uri.queryParameters['name'] ?? 'Contact';
        final type = state.uri.queryParameters['type'] ?? 'audio';
        return CallScreen(userId: userId, userName: name, callType: type);
      },
    ),
  ],
);
