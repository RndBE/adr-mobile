double resolveAnalisaDialogWidth({
  required double screenWidth,
  required double horizontalInset,
  required double maxWidth,
}) {
  final availableWidth = screenWidth - horizontalInset;
  if (availableWidth <= 0) {
    return maxWidth;
  }

  return availableWidth.clamp(0.0, maxWidth).toDouble();
}
