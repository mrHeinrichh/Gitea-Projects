#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_yun_ceng_kiwi.podspec` to validate before publishiflutter run -vg.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_yun_ceng_kiwi'
  s.version          = '0.0.1'
  s.summary          = '阿里游戏盾flutter组件'
  s.description      = <<-DESC
阿里游戏盾flutter组件
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.preserve_paths = 'Classes/Headers/Kiwi.h', 'Classes/libKiwi.a'
  s.vendored_libraries = 'Classes/libKiwi.a'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.static_framework = true
  
  s.xcconfig = {
      'OTHER_LDFLAGS' => '-lc++ -lKiwi',
      'USER_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/',
  }
  
  s.platform = :osx, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
