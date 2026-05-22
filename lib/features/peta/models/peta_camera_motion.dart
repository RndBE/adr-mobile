const double minPetaZoom = 5;
const double maxPetaZoom = 19;

double clampPetaZoom(double zoom) {
  return zoom.clamp(minPetaZoom, maxPetaZoom).toDouble();
}
