source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'

use_frameworks!

def common_pods

  # Networking

  pod 'Alamofire'
  pod 'atlantis-proxyman', :configurations => ['Debug']
  pod 'SDWebImage'
  pod 'Kingfisher'

  # Social

  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Drive'

  # Firebase

  pod 'Firebase'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'

  # Data

  pod 'ObjectMapper'
  pod 'SwiftyXMLParser'
  pod 'SwiftyJSON'

  # UI

  pod 'SkyFloatingLabelTextField', :git => 'https://github.com/Skyscanner/SkyFloatingLabelTextField.git'
  pod 'MBProgressHUD'
  pod 'MediaBrowser', :git => 'https://github.com/ayuzhin/MediaBrowser.git'
  pod 'SwiftRater'
  pod 'Siren'
  pod 'WhatsNewKit'
  pod 'PhoneNumberKit'
  pod 'SwiftMessages', '9.0.4'
  pod 'MGSwipeTableCell'
  pod 'ReCaptcha'

  # Utils

  pod 'FilesProvider', :git => 'https://github.com/ayuzhin/FileProvider.git'
  pod 'FileKit'
  pod 'IQKeyboardManagerSwift'
  pod 'KeychainSwift'
  pod 'SwiftGen', '~> 6.4.0'
  pod 'SwiftFormat/CLI', '~> 0.49', :configurations => ['Debug']

end

class ::Pod::Generator::Acknowledgements
  def footnote_title
    ""
  end
  def footnote_text
    ""
  end
end

target 'Documents' do
  workspace 'ONLYOFFICE-Documents'
  project 'Documents/Documents.xcodeproj'
  
  common_pods
  
  pod 'DocumentConverter', :path => '../editors-ios/DocumentConverter.podspec'
  pod 'SpreadsheetEditor', :path => '../editors-ios/SpreadsheetEditor.podspec'
  pod 'DocumentEditor', :path => '../editors-ios/DocumentEditor.podspec'
  pod 'PresentationEditor', :path => '../editors-ios/PresentationEditor.podspec'

  target 'DocumentsTests' do
    inherit! :complete
    inherit! :search_paths
  end
end

target 'Documents-Alpha' do
  workspace 'ONLYOFFICE-Documents'
  project 'Documents/Documents.xcodeproj'
  
  common_pods
  
  pod 'DocumentConverter', :path => '../editors-ios/DocumentConverter.podspec'
  pod 'SpreadsheetEditor', :path => '../editors-ios/SpreadsheetEditor.podspec'
  pod 'DocumentEditor', :path => '../editors-ios/DocumentEditor.podspec'
  pod 'PresentationEditor', :path => '../editors-ios/PresentationEditor.podspec'
end

target 'Documents-develop' do
  workspace 'ONLYOFFICE-Documents-develop'
  project 'Documents/Documents-develop.xcodeproj'
  
  common_pods
end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r(
    'Pods/Target Support Files/Pods-Documents/Pods-Documents-acknowledgements.plist',
    'Documents/Settings.bundle/Acknowledgements.plist',
    :remove_destination => true
  )

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end

end
