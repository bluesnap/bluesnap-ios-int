Pod::Spec.new do |s|
  s.name         = "BluesnapSDK"
  s.version      = "1.5.2"
  s.summary      = "An iOS SDK for Bluesnap "
  s.description  = <<-DESC
  Integrate payment methods into your iOS native apps quickly and easily.
  Bluesnap iOS SDK supports credit card and apple pay, currency conversions and more.
                  DESC
  s.homepage     = "http://www.bluesnap.com"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author             = { "snpori" => "oribsnap@gmail.com" }
  s.platform = :ios
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.source       = { :git => "https://github.com/bluesnap/bluesnap-ios.git", :tag => "#{s.version}" }
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0',
                            'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
                            'ONLY_ACTIVE_ARCH' => 'NO' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.resources =[ 'BluesnapSDK/**/Media.xcassets' ,  'BluesnapSDK/**/Assets.car']
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'AddressBook', 'UIKit' ,
  s.weak_frameworks                = 'Contacts'
  s.requires_arc = true


  s.source_files  = ["BluesnapSDK/**/*.swift",  "BluesnapSDK/Kount-Bridging-Header.h", "Frameworks/**/KDataCollector.h", "Frameworks/**/KountAnalyticsViewController.h"]
  s.public_header_files =  ["BluesnapSDK/Kount-Bridging-Header.h" , "Frameworks/**/KDataCollector.h", "Frameworks/**/KountAnalyticsViewController.h"]
  s.ios.vendored_frameworks = ['Frameworks/FATFrameworks/CardinalMobile.framework',"Frameworks/XCFrameworks/KountDataCollector.xcframework" ]
  s.resource_bundles = {
  'BluesnapUI' => [
         'BluesnapSDK/**/*.xib',
         'BluesnapSDK/**/*.storyboard',
         'BluesnapSDK/**/Media.xcassets',
         'BluesnapSDK/**/Assets.car',
         'BluesnapSDK/**/*.strings' 

  ]}


end
