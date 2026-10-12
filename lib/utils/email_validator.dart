/// Production-grade email validation utility for KaSpot.
///
/// Filters out malformed email syntax, known disposable/temporary burner domains,
/// common domain typos, and domain-specific rules (such as Gmail username constraints).
class EmailValidator {
  EmailValidator._();

  /// Known temporary / disposable burner email domains
  static const Set<String> disposableDomains = {
    'tempmail.com',
    'temp-mail.org',
    '10minutemail.com',
    '10minutemail.net',
    'mailinator.com',
    'guerrillamail.com',
    'guerrillamail.net',
    'guerrillamail.org',
    'guerrillamailblock.com',
    'sharklasers.com',
    'grr.la',
    'pokemail.net',
    'throwawaymail.com',
    'dispostable.com',
    'yopmail.com',
    'yopmail.fr',
    'yopmail.net',
    'trashmail.com',
    'trashmail.net',
    'trashmail.org',
    'getnada.com',
    'fakemailgenerator.com',
    'generator.email',
    'mohmal.com',
    'crazymailing.com',
    'nada.ltd',
    'inboxbear.com',
    'maildrop.cc',
    'tempail.com',
    'fakeinbox.com',
    'burnermail.io',
    'mailcatch.com',
    'mytemp.email',
    'mytempemail.com',
    'fakeemail.com',
  };

  /// Common domain typo suggestions
  static const Map<String, String> commonTypoDomains = {
    'gmial.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gmail.co': 'gmail.com',
    'hotmial.com': 'hotmail.com',
    'hotmial.co': 'hotmail.com',
    'yaho.com': 'yahoo.com',
    'yahooo.com': 'yahoo.com',
    'outloo.com': 'outlook.com',
  };

  /// Validates an email address.
  ///
  /// Returns `null` if the email is valid, or a descriptive error message if invalid.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }

    final trimmed = value.trim();

    if (!trimmed.contains('@')) {
      return 'Email must include "@" (e.g. name@gmail.com).';
    }

    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty) {
      return 'Enter a valid username before the "@".';
    }

    final username = parts[0];
    final domain = parts[1].toLowerCase();

    // Username formatting
    if (username.startsWith('.') || username.endsWith('.')) {
      return 'Username cannot start or end with a dot.';
    }
    if (username.contains('..')) {
      return 'Username cannot contain consecutive dots.';
    }

    // Domain formatting
    if (!domain.contains('.')) {
      return 'Enter a complete domain with extension (e.g. @gmail.com).';
    }
    final domainParts = domain.split('.');
    if (domainParts.any((part) => part.isEmpty)) {
      return 'Domain cannot contain empty or consecutive dots.';
    }
    if (domainParts.last.length < 2) {
      return 'Domain extension must be at least 2 characters.';
    }

    // Standard RFC-compliant email structure
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid, complete email address.';
    }

    // Check for common typos
    if (commonTypoDomains.containsKey(domain)) {
      final suggestion = commonTypoDomains[domain];
      return 'Did you mean @$suggestion? Please check your domain.';
    }

    // Filter out disposable / burner domains
    if (disposableDomains.contains(domain)) {
      return 'Temporary or disposable email addresses are not permitted.';
    }

    // Google / Gmail specific validation rules
    if (domain == 'gmail.com' || domain == 'googlemail.com') {
      // Gmail ignores dots for identity, but validates username lengths between 6 and 30
      final cleanUser = username.replaceAll('.', '');
      if (cleanUser.length < 6) {
        return 'Gmail usernames must be at least 6 characters long.';
      }
      if (cleanUser.length > 30) {
        return 'Gmail usernames cannot exceed 30 characters.';
      }

      // Check for allowed characters (letters, numbers, and plus-addressing for tags)
      final gmailPattern = RegExp(r'^[a-zA-Z0-9]+(\+[a-zA-Z0-9._-]+)?$');
      if (!gmailPattern.hasMatch(cleanUser)) {
        return 'Gmail usernames may only contain letters, numbers, and periods.';
      }
    }

    return null;
  }
}
