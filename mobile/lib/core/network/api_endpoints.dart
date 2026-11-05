class ApiEndpoints {
  // Authentication
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String updateProfile = '/api/auth/update-profile';
  static const String logout = '/api/auth/logout';

  // Dashboard
  static const String adminDashboard = '/api/dashboard/admin';
  static const String employeeDashboard = '/api/dashboard/employee';

  // Tasks
  static const String tasks = '/api/tasks';
  static String taskDetails(int id) => '/api/tasks/$id';

  // Transactions
  static const String transactions = '/api/transactions';
  static String verifyTransaction(int id) => '/api/transactions/$id/verify';

  // Attendance
  static const String checkIn = '/api/attendance/check-in';
  static const String checkOut = '/api/attendance/check-out';
  static const String attendanceHistory = '/api/attendance/history';

  // Location & Tracking
  static const String startLocationSession = '/api/location/session/start';
  static const String stopLocationSession = '/api/location/session/stop';
  static const String pingLocation = '/api/location/ping';
  static const String liveEmployees = '/api/location/live-employees';
  static String locationHistory(int employeeId) => '/api/location/history/$employeeId';

  // Customers
  static const String customers = '/api/customers';
  static String customerDetails(int id) => '/api/customers/$id';
  static const String recordVisit = '/api/customers/visit';

  // Employees
  static const String employees = '/api/employees';
  static String employeeDetails(int id) => '/api/employees/$id';
  static const String updateStatus = '/api/employees/status';

  // Communication & Calling
  static String chatMessages(int userId) => '/api/chat/$userId';
  static const String sendMessage = '/api/chat/send';
  static const String initiateCall = '/api/calls/initiate';
  static String respondCall(int id) => '/api/calls/$id/respond';

  // Reports
  static const String collectionReports = '/api/reports/collections';
  static const String auditLogs = '/api/reports/audit-logs';
}
