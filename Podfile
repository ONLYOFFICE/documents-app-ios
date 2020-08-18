source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'

use_frameworks!

def common_pods
  pod 'Bagel', :configurations => ['Debug']
  pod 'FilesProvider', :git => 'https://github.com/ayuzhin/FileProvider.git'
  pod 'MediaBrowser', :git => 'https://github.com/ayuzhin/MediaBrowser.git'
  pod 'SkyFloatingLabelTextField', :git => 'https://github.com/Skyscanner/SkyFloatingLabelTextField.git'
  pod 'Alamofire'
  pod 'ObjectMapper'
  pod 'FileKit'
  pod 'SwiftyXMLParser'
  pod 'MBProgressHUD'
  pod 'SDWebImage'
  pod 'SwiftRater'
  pod 'Siren'
  pod 'WhatsNewKit'
  pod 'PhoneNumberKit'
  pod 'Kingfisher'
  pod 'IQKeyboardManagerSwift'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Drive'
  pod 'Firebase'
  pod 'FirebaseInstanceID'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'KeychainSwift'
  pod 'MGSwipeTableCell'
  pod 'SwiftMessages'
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
end
