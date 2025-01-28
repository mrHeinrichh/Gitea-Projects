
class VideoDimensionsModel {
  final int width;
  final int height;

  VideoDimensionsModel(this.width, this.height);

  // Method to get VideoDimensions based on input number
  static int getVideoWidth(int input) {
    switch (input) {
      case 1:
        return 120;
      case 2:
        return 160;
      case 3:
        return 180;
      case 4:
      case 6:
        return 240;
      case 5:
      case 7:
        return 320;
      case 8:
        return 424;
      case 9:
        return 360;
      case 10:
      case 12:
        return 480;
      case 11:
      case 13:
        return 640;
      case 14:
        return 840;
      case 15:
      case 16:
        return 960;
      case 17:
        return 1280;
      case 19:
        return 2540;
      case 20:
        return 3840;
      case 18:
      default:
        return 1920;
    }
  }

  static int getVideoHeight(int input) {
    switch (input) {
      case 1:
      case 2:
        return 120;
      case 3:
      case 4:
      case 5:
        return 180;
      case 6:
      case 7:
      case 8:
        return 240;
      case 9:
      case 10:
      case 11:
        return 360;
      case 12:
      case 13:
      case 14:
        return 480;
      case 15:
        return 540;
      case 16:
      case 17:
        return 720;
      case 19:
        return 1440;
      case 20:
        return 2160;
      case 18:
      default:
        return 1080;
    }
  }
}
