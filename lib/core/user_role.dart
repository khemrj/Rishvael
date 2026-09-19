/// Mirrors the backend's Role enum (ROLE_CUSTOMER, ROLE_ADMIN, ...).
/// Kept as its own file — both AuthState and every dashboard-routing
/// widget import this, without either depending on the other.
enum UserRole {
  customer,
  admin,
  business,
  moderator,
  unknown; // decode failure / unrecognized claim — never crash on this

  /// Backend sends "ROLE_CUSTOMER"; Dart enum values are "customer".
  /// One conversion point, same discipline as the wire-format enum
  /// converters already used on your Opportunity model.
  static UserRole fromWireValue(String? wireValue) {
    final normalized = wireValue?.toUpperCase().replaceFirst('ROLE_', '');
    return switch (normalized) {
      'CUSTOMER' => UserRole.customer,
      'ADMIN' => UserRole.admin,
      'BUSINESS' => UserRole.business,
      'MODERATOR' => UserRole.moderator,
      _ => UserRole.unknown,
    };
  }
}