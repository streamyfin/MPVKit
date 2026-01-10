Pod::Spec.new do |s|
  s.name             = 'MPVKit-GPL'
  s.version          = '0.40.0-av-local'
  s.summary          = 'MPVKit with AVFoundation video output for iOS/tvOS (LOCAL DEV)'
  s.description      = <<-DESC
    Local development version of MPVKit.
  DESC

  s.homepage         = 'https://github.com/Alexk2309/MPVKit'
  s.license          = { :type => 'GPL-3.0', :text => 'GPL-3.0' }
  s.author           = { 'Alexk2309' => 'https://github.com/Alexk2309' }
  s.source           = { :git => 'https://github.com/Alexk2309/MPVKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.static_framework = true
  s.requires_arc = true

  # For local dev: point to built xcframework
  s.vendored_frameworks = 'dist/MPVKit-combined/xcframework/MPVKit.xcframework'

  # System frameworks
  s.frameworks = [
    'AVFoundation',
    'AudioToolbox',
    'CoreAudio',
    'CoreVideo',
    'CoreFoundation',
    'CoreMedia',
    'Metal',
    'VideoToolbox'
  ]

  # System libraries
  s.libraries = [
    'bz2',
    'iconv',
    'expat',
    'resolv',
    'xml2',
    'z',
    'c++'
  ]

  s.pod_target_xcconfig = {
    'VALID_ARCHS' => 'arm64 x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'i386'
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'i386'
  }
  
  s.xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }
end

