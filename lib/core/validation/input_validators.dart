class InputValidators {

  InputValidators._();

  static const _allowedUniversityDomains = [
    '@smuct.edu',
    '@smuct.ac.bd',
  ];

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';

    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isEmail) return 'Enter a valid email address';

    final normalizedEmail = email.toLowerCase();
    final isAllowedDomain = _allowedUniversityDomains.any(normalizedEmail.endsWith);

    if (!isAllowedDomain) {
      return 'Use your university email (@smuct.edu or @smuct.ac.bd)';
    }

    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
