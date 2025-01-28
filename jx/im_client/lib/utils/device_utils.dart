/*
 * 判断语音视频控件是否占用
 */

String getMacDeviceName(String modelName) {
  switch (modelName) {
    case "Mac13,1":
      return "Mac Studio (M1 Max, 2021)";
    case "Mac13,2":
      return "Mac Studio (M1 Ultra, 2022)";
    case "Mac14,2":
      return "MacBook Air (M2, 2022)";
    case "Mac14,3":
      return "Mac mini (2023) M2";
    case "Mac14,5":
      return "MBPro (14-inch, 2023) M2 Max";
    case "Mac14,6":
      return "MBPro (16-inch, 2023) M2 Max";
    case "Mac14,7":
      return "MacBook Pro (13-inch, M2, 2022)";
    case "Mac14,9":
      return "MBPro (14-inch, 2023) M2 Pro";
    case "Mac14,10":
      return "MBPro (16-inch, 2023) M2 Pro";
    case "Mac14,12":
      return "Mac mini (2023) M2 Pro";
    case "Mac15,3":
      return "MBPro (14-inch, 2023) M3";
    case "Mac15,4":
      return "iMac (24-inch, 2023) M3";
    case "Mac15,5":
      return "iMac (24-inch, 2023) M3";
    case "Mac15,6":
      return "MBPro (14-inch, 2023) M3 Pro";
    case "Mac15,7":
      return "MBPro (16-inch, 2023) M3 Pro";
    case "Mac15,8":
      return "MBPro (14-inch, 2023) M3 Max";
    case "Mac15,9":
      return "MBPro (16-inch, 2020) M3 Max";
    case "Mac15,10":
      return "MBPro (14-inch, 2023) M3 Max";
    case "Mac15,11":
      return "MBPro (16-inch, 2023) M3 Max";
    case "MacBookPro16,4":
      return "MBPro (16-inch, AMD Radeon Pro 5600M)";
    case "MacBookPro16,3":
      return "MBPro (13-inch 2020)";
    case "MacBookPro16,2":
      return "MBPro (13-inch 2020)";
    case "MacBookPro16,1":
      return "MBPro (16-inch Late 2019)";
    case "MacBookPro15,4":
      return "MBPro (13-inch Mid 2019)";
    case "MacBookPro15,3":
      return "MBPro (15-inch Mid 2019)";
    case "MacBookPro15,2":
      return "MBPro (13-inch Mid 2018)";
    case "MacBookPro15,1":
      return "MBPro (15-inch Mid 2018)";
    case "MacBookPro14,3":
      return "MBPro (15-inch Mid 2017)";
    case "MacBookPro14,2":
      return "MBPro (13-inch Mid 2017)";
    case "MacBookPro14,1":
      return "MBPro (13-inch Mid 2017)";
    case "MacBookPro13,3":
      return "MBPro (15-inch Late 2016)";
    case "MacBookPro13,2":
      return "MBPro (13-inch Late 2016)";
    case "MacBookPro13,1":
      return "MBPro (15-inch Late 2016)";
    case "MacBookPro12,1":
      return "MBPro (13-inch Early 2015)";
    case "MacBookPro11,5":
      return "MBPro (15-inch Mid 2015)";
    case "MacBookPro11,4":
      return "MBPro (15-inch Mid 2015)";
    case "MacBookPro11,3":
      return "MBPro (15-inch Mid 2014)";
    case "MacBookPro11,2":
      return "MBPro (15-inch Late 2013)";
    case "MacBookPro11,1":
      return "MBPro (13-inch Late 2013)";
    case "MacBookPro10,2":
      return "MBPro (13-inch Early 2013)";
    case "MacBookPro10,1":
      return "MBPro (15-inch Early 2013)";
    case "MacBookPro10.1":
      return "MBPro (15-inch Retina 2012)";
    case "MacBookPro9,2":
      return "MBPro (13-inch Mid 2012)";
    case "MacBookPro9,1":
      return "MBPro (15-inch Mid 2012)";
    case "MacBookPro8,3":
      return "MBPro (17-inch Late 2011)";
    case "MacBookPro8,2":
      return "MBPro (15-inch Late 2011)";
    case "MacBookPro8,1":
      return "MBPro (13-inch Late 2011)";
    case "MacBookPro7,1":
      return "MBPro (13-inch Early 2010)";
    case "MacBookPro6,2":
      return "MBPro (15-inch Early 2010)";
    case "MacBookPro6,1":
      return "MBPro (17-inch Early 2010)";
    case "MacBookPro5,5":
      return "MBPro (13-inch Mid 2009)";
    case "MacBookPro5,4":
      return "MBPro (15-inch Mid 2009)";
    case "MacBookPro5,3":
      return "MBPro (15-inch Mid 2009)";
    case "MacBookPro5,2":
      return "MBPro (17-inch Early 2009)";
    case "MacBookPro5,1":
      return "MBPro (15-inch Late 2008)";
    case "MacBookPro4,1":
      return "MBPro (15-inch Early 2008)";
    case "MacBookPro3,1":
      return "MBPro (15-inch Late 2007)";
    case "MacBookPro2,2":
      return "MBPro (15-inch Late 2006)";
    case "MacBookPro2,1":
      return "MBPro (17-inch Late 2006)";
    case "MacBookPro1,2":
      return "MBPro (17-inch 2006)";
    case "MacBookPro1,1":
      return "MBPro (15-inch 2006)";
    case "MacBookAir9,1":
      return "MacBook Air 2020";
    case "MacBookAir8,2":
      return "MacBook Air (TT Retina, 2019)";
    case "MacBookAir8,1":
      return "MacBook Air (Late 2018)";
    case "MacBookAir7,2":
      return "MacBook Air (Mid 2017)";
    case "MacBookAir7,1":
      return "MacBook Air (11-inch Early 2015)";
    case "MacBookAir6,2":
      return "MacBook Air (13-inch Early 2014)";
    case "MacBookAir6,1":
      return "MacBook Air (11-inch Mid 2013)";
    case "MacBookAir5,2":
      return "MacBook Air (13-inch Mid 2012)";
    case "MacBookAir5,1":
      return "MacBook Air (11-inch Mid 2012)";
    case "MacBookAir4,2":
      return "MacBook Air (13-inch Mid 2012)";
    case "MacBookAir4,1":
      return "MacBook Air (11-inch Mid 2012)";
    case "MacBookAir3,2":
      return "MacBook Air (13-inch Late 2010)";
    case "MacBookAir3,1":
      return "MacBook Air (11-inch Late 2010)";
    case "MacBookAir2,1":
      return "MacBook Air (13-inch Late 2008)";
    case "MacBookAir1,1":
      return "MacBook Air (13-inch Early 2008)";
    case "MacBook10,1":
      return "MacBook (Mid 2017)";
    case "MacBook9,1":
      return "MacBook (Early 2016)";
    case "MacBook8,2":
      return "MacBook (Early 2015)";
    case "MacBook8,1":
      return "MacBook (Early 2015)";
    case "MacBook7,1":
      return "MacBook (Mid 2010)";
    case "MacBook6,1":
      return "MacBook (Late 2009)";
    case "MacBook5,2":
      return "MacBook (13-inch C2D Early 2009)";
    case "MacBook5,1":
      return "MacBook (13-inch C2D Late 2008 Aluminum)";
    case "MacBook4,1":
      return "MacBook (13-inch C2D Early 2008)";
    case "MacBook3,1":
      return "MacBook (13-inch C2D Late 2007)";
    case "MacBook2,1":
      return "MacBook (13-inch C2D Late 2006)";
    case "MacBook1,1":
      return "MacBook (13-inch Core Duo 2006)";
    case "MacPro7,1":
      return "Mac Studio -2019";
    case "MacPro6,1":
      return "Mac Studio (Late 2013)";
    case "MacPro5,1":
      return "Mac Studio (Mid 2010)";
    case "MacPro4,1":
      return "Mac Studio (Nehalem 2009)";
    case "MacPro3,1":
      return "Mac Studio (Eight Core 2008)";
    case "MacPro2,1":
      return "Mac Studio (Eight Core 2007)";
    case "MacPro1,1":
      return "Mac Studio (Quad Core 2006)";
    case "iMac20,2":
      return "iMac (Retina 5K, 27-Inch, 2020)";
    case "iMac20,1":
      return "iMac (Retina 5K, 27-Inch, 2020)";
    case "iMac19,1":
      return "iMac (27-Inch 5k, 2019)";
    case "iMac18,3":
      return "iMac (27-Inch 5k Mid-2017)";
    case "iMac18,2":
      return "iMac (21.5-Inch 4k Mid-2017)";
    case "iMac18,1":
      return "iMac (21.5-Inch Mid-2017)";
    case "iMac17,1":
      return "iMac (27-Inch 5k, Late 2015)";
    case "iMac16,2":
      return "iMac (21.5-Inch Late 2015)";
    case "iMac16,1":
      return "iMac (21.5-Inch Late 2015)";
    case "iMac15,2":
      return "iMac (27-Inch 5k, Late 2014)";
    case "iMac15,1":
      return "iMac (5K, 27-inch, Late 2014)";
    case "iMac14,4":
      return "iMac (21.5-inch Mid 2014)";
    case "iMac14,3":
      return "iMac (21.5-inch Late 2013)";
    case "iMac14,2":
      return "iMac (27-inch Late 2013)";
    case "iMac14,1":
      return "iMac (21.5-inch Late 2013)";
    case "iMac13,3":
      return "iMac (iMac Late 2012)";
    case "iMac13,2":
      return "iMac (27-Inch Late 2012)";
    case "iMac13,1":
      return "iMac (21.5-inch Late 2012)";
    case "iMac12,2":
      return "iMac (27-inch Mid 2011)";
    case "iMac12,1":
      return "iMac (21.5-inch Mid 2011)";
    case "iMac11,3":
      return "iMac (27-inch Mid 2010)";
    case "iMac11,2":
      return "iMac (21.5-inch Mid 2010)";
    case "iMac11,1":
      return "iMac (27-inch Late 2009)";
    case "iMac10,1":
      return "iMac (iMac Late 2009)";
    case "iMac9,1":
      return "iMac (20-inch Mid 2009)";
    case "iMac8,1":
      return "iMac (24-inch Early 2008)";
    case "iMac7,1":
      return "iMac (24-inch Mid 2007)";
    case "iMac6,1":
      return "iMac (24-inch Late 2006)";
    case "iMac5,2":
      return "iMac (17-inch Late 2006)";
    case "iMac5,1":
      return "iMac (20-inch Late 2006)";
    case "iMac4,2":
      return "iMac (17-inch Mid 2006)";
    case "iMac4,1":
      return "iMac (20-inch Early 2006)";
    case "iMacPro1,1":
      return "iMac Pro (5k, 27-inch Late 2017)";
    case "Macmini8,1":
      return "Mac Mini (Late 2018)";
    case "Macmini7,1":
      return "Mac Mini (Late 2014)";
    case "Macmini6,2":
      return "Mac Mini (Late 2012)";
    case "Macmini6,1":
      return "Mac Mini (Late 2012)";
    case "Macmini5,3":
      return "Mac Mini (Mid 2011)";
    case "Macmini5,2":
      return "Mac Mini (Mid 2011)";
    case "Macmini5,1":
      return "Mac Mini (Mid 2011)";
    case "Macmini4,1":
      return "Mac Mini (Early 2010)";
    case "Macmini3,1":
      return "Mac Mini (Early 2009)";
    case "Macmini2,1":
      return "Mac Mini (Mid 2007)";
    case "Macmini1,1":
      return "Mac Mini (Late 2006)";
    default:
      return modelName;
  }
}

String getIOSDeviceName(String machineName) {
  switch (machineName) {
    case "i386":
      return "iPhone Simulator";
    case "x86_64":
      return "iPhone Simulator";
    case "arm64":
      return "iPhone Simulator";
    case "iPhone1,1":
      return "iPhone";
    case "iPhone1,2":
      return "iPhone 3G";
    case "iPhone2,1":
      return "iPhone 3GS";
    case "iPhone3,1":
      return "iPhone 4";
    case "iPhone3,2":
      return "iPhone 4 GSM Rev A";
    case "iPhone3,3":
      return "iPhone 4 CDMA";
    case "iPhone4,1":
      return "iPhone 4S";
    case "iPhone5,1":
      return "iPhone 5 (GSM)";
    case "iPhone5,2":
      return "iPhone 5 (GSM+CDMA)";
    case "iPhone5,3":
      return "iPhone 5C (GSM)";
    case "iPhone5,4":
      return "iPhone 5C (Global)";
    case "iPhone6,1":
      return "iPhone 5S (GSM)";
    case "iPhone6,2":
      return "iPhone 5S (Global)";
    case "iPhone7,1":
      return "iPhone 6 Plus";
    case "iPhone7,2":
      return "iPhone 6";
    case "iPhone8,1":
      return "iPhone 6s";
    case "iPhone8,2":
      return "iPhone 6s Plus";
    case "iPhone8,4":
      return "iPhone SE (GSM)";
    case "iPhone9,1":
      return "iPhone 7";
    case "iPhone9,2":
      return "iPhone 7 Plus";
    case "iPhone9,3":
      return "iPhone 7";
    case "iPhone9,4":
      return "iPhone 7 Plus";
    case "iPhone10,1":
      return "iPhone 8";
    case "iPhone10,2":
      return "iPhone 8 Plus";
    case "iPhone10,3":
      return "iPhone X Global";
    case "iPhone10,4":
      return "iPhone 8";
    case "iPhone10,5":
      return "iPhone 8 Plus";
    case "iPhone10,6":
      return "iPhone X GSM";
    case "iPhone11,2":
      return "iPhone XS";
    case "iPhone11,4":
      return "iPhone XS Max";
    case "iPhone11,6":
      return "iPhone XS Max Global";
    case "iPhone11,8":
      return "iPhone XR";
    case "iPhone12,1":
      return "iPhone 11";
    case "iPhone12,3":
      return "iPhone 11 Pro";
    case "iPhone12,5":
      return "iPhone 11 Pro Max";
    case "iPhone12,8":
      return "iPhone SE 2nd Gen";
    case "iPhone13,1":
      return "iPhone 12 Mini";
    case "iPhone13,2":
      return "iPhone 12";
    case "iPhone13,3":
      return "iPhone 12 Pro";
    case "iPhone13,4":
      return "iPhone 12 Pro Max";
    case "iPhone14,2":
      return "iPhone 13 Pro";
    case "iPhone14,3":
      return "iPhone 13 Pro Max";
    case "iPhone14,4":
      return "iPhone 13 Mini";
    case "iPhone14,5":
      return "iPhone 13";
    case "iPhone14,6":
      return "iPhone SE 3rd Gen";
    case "iPhone14,7":
      return "iPhone 14";
    case "iPhone14,8":
      return "iPhone 14 Plus";
    case "iPhone15,2":
      return "iPhone 14 Pro";
    case "iPhone15,3":
      return "iPhone 14 Pro Max";
    case "iPhone15,4":
      return "iPhone 15";
    case "iPhone15,5":
      return "iPhone 15 Plus";
    case "iPhone16,1":
      return "iPhone 15 Pro";
    case "iPhone16,2":
      return "iPhone 15 Pro Max";
    case "iPhone17,1":
      return "iPhone 16 Pro";
    case "iPhone17,2":
      return "iPhone 16 Pro Max";
    case "iPhone17,3":
      return "iPhone 16";
    case "iPhone17,4":
      return "iPhone 16 Plus";
    case "iPod1,1":
      return "1st Gen iPod";
    case "iPod2,1":
      return "2nd Gen iPod";
    case "iPod3,1":
      return "3rd Gen iPod";
    case "iPod4,1":
      return "4th Gen iPod";
    case "iPod5,1":
      return "5th Gen iPod";
    case "iPod7,1":
      return "6th Gen iPod";
    case "iPod9,1":
      return "7th Gen iPod";
    case "iPad1,1":
      return "iPad";
    case "iPad1,2":
      return "iPad 3G";
    case "iPad2,1":
      return "2nd Gen iPad";
    case "iPad2,2":
      return "2nd Gen iPad GSM";
    case "iPad2,3":
      return "2nd Gen iPad CDMA";
    case "iPad2,4":
      return "2nd Gen iPad New Revision";
    case "iPad3,1":
      return "3rd Gen iPad";
    case "iPad3,2":
      return "3rd Gen iPad CDMA";
    case "iPad3,3":
      return "3rd Gen iPad GSM";
    case "iPad2,5":
      return "iPad mini";
    case "iPad2,6":
      return "iPad mini GSM+LTE";
    case "iPad2,7":
      return "iPad mini CDMA+LTE";
    case "iPad3,4":
      return "4th Gen iPad";
    case "iPad3,5":
      return "4th Gen iPad GSM+LTE";
    case "iPad3,6":
      return "4th Gen iPad CDMA+LTE";
    case "iPad4,1":
      return "iPad Air (WiFi)";
    case "iPad4,2":
      return "iPad Air (GSM+CDMA)";
    case "iPad4,3":
      return "1st Gen iPad Air (China)";
    case "iPad4,4":
      return "iPad mini Retina (WiFi)";
    case "iPad4,5":
      return "iPad mini Retina (GSM+CDMA)";
    case "iPad4,6":
      return "iPad mini Retina (China)";
    case "iPad4,7":
      return "iPad mini 3 (WiFi)";
    case "iPad4,8":
      return "iPad mini 3 (GSM+CDMA)";
    case "iPad4,9":
      return "iPad Mini 3 (China)";
    case "iPad5,1":
      return "iPad mini 4 (WiFi)";
    case "iPad5,2":
      return "4th Gen iPad mini (WiFi+Cellular)";
    case "iPad5,3":
      return "iPad Air 2 (WiFi)";
    case "iPad5,4":
      return "iPad Air 2 (Cellular)";
    case "iPad6,3":
      return "iPad Pro (9.7 inch, WiFi)";
    case "iPad6,4":
      return "iPad Pro (9.7 inch, WiFi+LTE)";
    case "iPad6,7":
      return "iPad Pro (12.9 inch, WiFi)";
    case "iPad6,8":
      return "iPad Pro (12.9 inch, WiFi+LTE)";
    case "iPad6,11":
      return "iPad (2017)";
    case "iPad6,12":
      return "iPad (2017)";
    case "iPad7,1":
      return "iPad Pro 2nd Gen (WiFi)";
    case "iPad7,2":
      return "iPad Pro 2nd Gen (WiFi+Cellular)";
    case "iPad7,3":
      return "iPad Pro 10.5-inch 2nd Gen";
    case "iPad7,4":
      return "iPad Pro 10.5-inch 2nd Gen";
    case "iPad7,5":
      return "iPad 6th Gen (WiFi)";
    case "iPad7,6":
      return "iPad 6th Gen (WiFi+Cellular)";
    case "iPad7,11":
      return "iPad 7th Gen 10.2-inch (WiFi)";
    case "iPad7,12":
      return "iPad 7th Gen 10.2-inch (WiFi+Cellular)";
    case "iPad8,1":
      return "iPad Pro 11 inch 3rd Gen (WiFi)";
    case "iPad8,2":
      return "iPad Pro 11 inch 3rd Gen (1TB, WiFi)";
    case "iPad8,3":
      return "iPad Pro 11 inch 3rd Gen (WiFi+Cellular)";
    case "iPad8,4":
      return "iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)";
    case "iPad8,5":
      return "iPad Pro 12.9 inch 3rd Gen (WiFi)";
    case "iPad8,6":
      return "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)";
    case "iPad8,7":
      return "iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)";
    case "iPad8,8":
      return "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)";
    case "iPad8,9":
      return "iPad Pro 11 inch 4th Gen (WiFi)";
    case "iPad8,10":
      return "iPad Pro 11 inch 4th Gen (WiFi+Cellular)";
    case "iPad8,11":
      return "iPad Pro 12.9 inch 4th Gen (WiFi)";
    case "iPad8,12":
      return "iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)";
    case "iPad11,1":
      return "iPad mini 5th Gen (WiFi)";
    case "iPad11,2":
      return "iPad mini 5th Gen";
    case "iPad11,3":
      return "iPad Air 3rd Gen (WiFi)";
    case "iPad11,4":
      return "iPad Air 3rd Gen";
    case "iPad11,6":
      return "iPad 8th Gen (WiFi)";
    case "iPad11,7":
      return "iPad 8th Gen (WiFi+Cellular)";
    case "iPad12,1":
      return "iPad 9th Gen (WiFi)";
    case "iPad12,2":
      return "iPad 9th Gen (WiFi+Cellular)";
    case "iPad14,1":
      return "iPad mini 6th Gen (WiFi)";
    case "iPad14,2":
      return "iPad mini 6th Gen (WiFi+Cellular)";
    case "iPad13,1":
      return "iPad Air 4th Gen (WiFi)";
    case "iPad13,2":
      return "iPad Air 4th Gen (WiFi+Cellular)";
    case "iPad13,4":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad13,5":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad13,6":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad13,7":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad13,8":
      return "iPad Pro 12.9 inch 5th Gen";
    case "iPad13,9":
      return "iPad Pro 12.9 inch 5th Gen";
    case "iPad13,10":
      return "iPad Pro 12.9 inch 5th Gen";
    case "iPad13,11":
      return "iPad Pro 12.9 inch 5th Gen";
    case "iPad13,16":
      return "iPad Air 5th Gen (WiFi)";
    case "iPad13,17":
      return "iPad Air 5th Gen (WiFi+Cellular)";
    case "iPad13,18":
      return "iPad 10th Gen";
    case "iPad13,19":
      return "iPad 10th Gen";
    case "iPad14,3":
      return "iPad Pro 11 inch 4th Gen";
    case "iPad14,4":
      return "iPad Pro 11 inch 4th Gen";
    case "iPad14,5":
      return "iPad Pro 12.9 inch 6th Gen";
    case "iPad14,6":
      return "iPad Pro 12.9 inch 6th Gen";
    case "iPad14,8":
      return "iPad Air 6th Gen";
    case "iPad14,9":
      return "iPad Air 6th Gen";
    case "iPad14,10":
      return "iPad Air 7th Gen";
    case "iPad14,11":
      return "iPad Air 7th Gen";
    case "iPad16,3":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad16,4":
      return "iPad Pro 11 inch 5th Gen";
    case "iPad16,5":
      return "iPad Pro 12.9 inch 7th Gen";
    case "iPad16,6":
      return "iPad Pro 12.9 inch 7th Gen";
    case "Watch1,1":
      return "Apple Watch 38mm case";
    case "Watch1,2":
      return "Apple Watch 42mm case";
    case "Watch2,6":
      return "Apple Watch Series 1 38mm case";
    case "Watch2,7":
      return "Apple Watch Series 1 42mm case";
    case "Watch2,3":
      return "Apple Watch Series 2 38mm case";
    case "Watch2,4":
      return "Apple Watch Series 2 42mm case";
    case "Watch3,1":
      return "Apple Watch Series 3 38mm case (GPS+Cellular)";
    case "Watch3,2":
      return "Apple Watch Series 3 42mm case (GPS+Cellular)";
    case "Watch3,3":
      return "Apple Watch Series 3 38mm case (GPS)";
    case "Watch3,4":
      return "Apple Watch Series 3 42mm case (GPS)";
    case "Watch4,1":
      return "Apple Watch Series 4 40mm case (GPS)";
    case "Watch4,2":
      return "Apple Watch Series 4 44mm case (GPS)";
    case "Watch4,3":
      return "Apple Watch Series 4 40mm case (GPS+Cellular)";
    case "Watch4,4":
      return "Apple Watch Series 4 44mm case (GPS+Cellular)";
    case "Watch5,1":
      return "Apple Watch Series 5 40mm case (GPS)";
    case "Watch5,2":
      return "Apple Watch Series 5 44mm case (GPS)";
    case "Watch5,3":
      return "Apple Watch Series 5 40mm case (GPS+Cellular)";
    case "Watch5,4":
      return "Apple Watch Series 5 44mm case (GPS+Cellular)";
    case "Watch5,9":
      return "Apple Watch SE 40mm case (GPS)";
    case "Watch5,10":
      return "Apple Watch SE 44mm case (GPS)";
    case "Watch5,11":
      return "Apple Watch SE 40mm case (GPS+Cellular)";
    case "Watch5,12":
      return "Apple Watch SE 44mm case (GPS+Cellular)";
    case "Watch6,1":
      return "Apple Watch Series 6 40mm case (GPS)";
    case "Watch6,2":
      return "Apple Watch Series 6 44mm case (GPS)";
    case "Watch6,3":
      return "Apple Watch Series 6 40mm case (GPS+Cellular)";
    case "Watch6,4":
      return "Apple Watch Series 6 44mm case (GPS+Cellular)";
    case "Watch6,6":
      return "Apple Watch Series 7 41mm case (GPS)";
    case "Watch6,7":
      return "Apple Watch Series 7 45mm case (GPS)";
    case "Watch6,8":
      return "Apple Watch Series 7 41mm case (GPS+Cellular)";
    case "Watch6,9":
      return "Apple Watch Series 7 45mm case (GPS+Cellular)";
    case "Watch6,10":
      return "Apple Watch SE 40mm case (GPS)";
    case "Watch6,11":
      return "Apple Watch SE 44mm case (GPS)";
    case "Watch6,12":
      return "Apple Watch SE 40mm case (GPS+Cellular)";
    case "Watch6,13":
      return "Apple Watch SE 44mm case (GPS+Cellular)";
    case "Watch6,14":
      return "Apple Watch Series 8 41mm case (GPS)";
    case "Watch6,15":
      return "Apple Watch Series 8 45mm case (GPS)";
    case "Watch6,16":
      return "Apple Watch Series 8 41mm case (GPS+Cellular)";
    case "Watch6,17":
      return "Apple Watch Series 8 45mm case (GPS+Cellular)";
    case "Watch6,18":
      return "Apple Watch Ultra";
    case "Watch7,1":
      return "Apple Watch Series 9 41mm case (GPS)";
    case "Watch7,2":
      return "Apple Watch Series 9 45mm case (GPS)";
    case "Watch7,3":
      return "Apple Watch Series 9 41mm case (GPS+Cellular)";
    case "Watch7,4":
      return "Apple Watch Series 9 45mm case (GPS+Cellular)";
    case "Watch7,5":
      return "Apple Watch Ultra 2";
    default:
      return machineName;
  }
}
