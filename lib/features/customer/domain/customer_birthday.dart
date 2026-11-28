/// True when [birthDate] falls on the day of [now] (month and day only).
///
/// A 29 February birthday is celebrated on 28 February in non-leap years.
bool isBirthdayOn(DateTime? birthDate, DateTime now) {
  if (birthDate == null) return false;
  if (birthDate.month == now.month && birthDate.day == now.day) return true;
  final leapYear =
      (now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0;
  return birthDate.month == 2 &&
      birthDate.day == 29 &&
      !leapYear &&
      now.month == 2 &&
      now.day == 28;
}
