#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mix_stack.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mix_stack'
  s.version          = '1.3.3'
  s.summary          = 'MixStack for connect Flutter and Native navigation.'
  s.description      = <<-DESC
MixStack for connect Flutter and Native navigation.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Yuewen' => 'pepsin@me.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
