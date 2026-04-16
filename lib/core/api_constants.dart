class ApiConstants {
  // Using 10.0.2.2 for Android Emulator connecting to WAMP server.
  // Change to your machine's IP (e.g., 192.168.1.X) if testing on a real device.
  // Change to localhost if using web.
  static const String baseUrl = 'https://pcstech.in/gym_api';

  static const String login = '$baseUrl/login.php';
  static const String register = '$baseUrl/register.php';
  static const String dashboardSummary = '$baseUrl/dashboard_summary.php';
  static const String addMember = '$baseUrl/member.php';
  static const String membersList = '$baseUrl/get_members.php';
  static const String memberProfile = '$baseUrl/get_member_profile.php';
  static const String addPayment = '$baseUrl/add_payment.php';
  static const String memberPayments = '$baseUrl/get_member_payments.php';
  static const String getMonthlyRevenue = '$baseUrl/get_monthly_revenue.php';
  static const String saveRevenue = '$baseUrl/save_revenue.php';
  static const String expenseHistory = '$baseUrl/get_expense_history.php';
}
