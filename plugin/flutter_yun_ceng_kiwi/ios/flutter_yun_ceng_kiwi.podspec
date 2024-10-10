#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_yun_ceng.podspec' to validate before publishing.
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
  s.ios.vendored_frameworks = 'Frameworks/Kiwi.framework'
  s.vendored_frameworks = 'Kiwi.framework'
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.static_framework = true

  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
