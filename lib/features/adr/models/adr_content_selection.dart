class AdrContentSelection {
  final bool isLoggerSelected;
  final int activePrismaIndex;

  const AdrContentSelection.prisma([this.activePrismaIndex = 0])
    : isLoggerSelected = false;

  const AdrContentSelection.logger([this.activePrismaIndex = 0])
    : isLoggerSelected = true;

  AdrContentSelection selectLogger() =>
      AdrContentSelection.logger(activePrismaIndex);

  AdrContentSelection selectPrisma(int index) =>
      AdrContentSelection.prisma(index);
}
