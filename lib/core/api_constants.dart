class ApiConstants {
  // ✅ Production server URL
  static const String baseUrl = 'https://pcstech.in/gym_api';

  // Timeout duration for all API requests
  static const Duration timeout = Duration(seconds: 15);

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
