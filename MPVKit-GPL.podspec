Pod::Spec.new do |s|
  s.name             = 'MPVKit-GPL'
  s.version          = '0.40.0-av'
  s.summary          = 'MPVKit with AVFoundation video output for iOS/tvOS'
  s.description      = <<-DESC
    MPVKit fork with AVFoundation video output (vo_avfoundation) support.
    Features Picture-in-Picture, hardware-accelerated VideoToolbox decoding,
    composite OSD for subtitles, and HDR/Dolby Vision support.
  DESC

  s.homepage         = 'https://github.com/Alexk2309/MPVKit'
  s.license          = { :type => 'GPL-3.0', :text => 'GPL-3.0. See https://www.gnu.org/licenses/gpl-3.0.html' }
  s.author           = { 'Alexk2309' => 'https://github.com/Alexk2309' }
  s.source           = { :http => 'https://github.com/Alexk2309/MPVKit/releases/download/0.40.0-av/MPVKit-GPL-Frameworks.zip' }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.static_framework = true
  s.requires_arc = true

  # For remote download: zip extracts to MPVKit.xcframework
  s.vendored_frameworks = 'MPVKit.xcframework'

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

  # Compiler flags - supports arm64 + x86_64 for simulators
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
