/**
 * Tính khoảng cách giữa hai tọa độ GPS theo công thức Haversine (đơn vị: mét)
 * @param {number} lat1 Vĩ độ điểm 1
 * @param {number} lon1 Kinh độ điểm 1
 * @param {number} lat2 Vĩ độ điểm 2
 * @param {number} lon2 Kinh độ điểm 2
 * @returns {number} Khoảng cách tính bằng mét
 */
function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Bán kính Trái Đất (mét)
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  const distance = R * c;
  return Math.round(distance * 10) / 10; // làm tròn 1 chữ số thập phân
}

/**
 * Kiểm tra xem vị trí có nằm trong hàng rào địa lý (Geofence) không
 */
function isWithinGeofence(userLat, userLon, targetLat, targetLon, radiusMeters = 50.0) {
  const distance = calculateDistanceMeters(userLat, userLon, targetLat, targetLon);
  return {
    isInside: distance <= radiusMeters,
    distance,
    radiusMeters,
  };
}

module.exports = {
  calculateDistanceMeters,
  isWithinGeofence,
};
