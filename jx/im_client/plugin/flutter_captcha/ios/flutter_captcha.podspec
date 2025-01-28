#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_captcha.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_captcha'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin which provide the captcha services with GEETEST.'
  s.description      = <<-DESC
A new Flutter plugin which provide the captcha services with GEETEST.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  s.vendored_frameworks = 'sdk/*.framework'
  s.frameworks = 'WebKit'
  s.ios.resource = 'sdk/Captcha.bundle'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',  'OTHER_LDFLAGS' => '-all_load' }
  s.swift_version = '5.0'
end
