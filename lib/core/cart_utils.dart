class CartUtils {
  static const int piecesPerBag = 30;
  static const double minOrderWeightKg = 30.0;

  /// Parses variant name like "250g", "1kg", etc. to return weight in KG.
  static double parseWeightFromVariant(String variantName) {
    final lower = variantName.toLowerCase();
    
    if (lower.contains('1kg') || lower.contains('1 kg')) {
      return 1.0;
    } else if (lower.contains('500g') || lower.contains('500 g')) {
      return 0.5;
    } else if (lower.contains('250g') || lower.contains('250 g')) {
      return 0.25;
    } else if (lower.contains('100g') || lower.contains('100 g')) {
      return 0.1;
    }
    
    // Default fallback if unknown format
    return 1.0; 
  }

  /// Calculates points based on weight (1 Point per KG)
  static int calculatePoints(double totalWeightKg) {
    return totalWeightKg.floor();
  }
}
