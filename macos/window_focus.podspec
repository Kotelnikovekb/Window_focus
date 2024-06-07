#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint window_focus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'window_focus'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
window_focus is a convenient Flutter plugin that allows you to track user inactivity and obtain information about the title of the active window on Mac OS and Windows operating systems.
Key Features:

Inactivity Tracking: The plugin enables you to detect periods of user inactivity within your Flutter application. You can customize the inactivity threshold and handle inactivity events according to your needs.

Active Window Title Retrieval: window_focus provides the ability to retrieve the title of the active window of the operating system. This is useful for monitoring user activity outside of your application, such as analyzing interactions with other applications or improving the user experience.

Mac OS and Windows Support: The plugin supports both Mac OS and Windows operating systems, providing broad coverage for your application development needs.

Advantages:

Ease of Use: Integrating window_focus into your Flutter application is simple and requires minimal effort.
Customization: The plugin allows you to configure inactivity tracking parameters to suit your application requirements.
Cross-Platform Compatibility: Support for Mac OS and Windows operating systems ensures a unified interface for your application across different platforms.

                       DESC
  s.homepage         = 'https://github.com/Kotelnikovekb/window_focus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kotelnikov Yiry' => 'y@kotelnikoff.expert' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
