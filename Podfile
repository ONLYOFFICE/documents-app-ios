source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'

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
  pod 'SwiftyDropbox'

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
  pod 'SwiftMessages'
  pod 'MGSwipeTableCell'
  pod 'ReCaptcha', :git => 'https://github.com/fjcaetano/ReCaptcha.git'
  pod "WSTagsField", :git => 'https://github.com/ayuzhin/WSTagsField.git'

  # Utils

  pod 'FilesProvider', :git => 'https://github.com/ayuzhin/FileProviderV2.git'
  pod 'FileKit'
  pod 'IQKeyboardManagerSwift'
  pod 'KeychainSwift'
  pod 'SwiftGen'
  pod 'SwiftFormat/CLI', :configurations => ['Debug']

end

class ::Pod::Generator::Acknowledgements
  def footnote_title
    ""
  end
  def footnote_text
    ""
  end
end

target 'Documents-opensource' do
  workspace 'ONLYOFFICE-Documents-opensource'
  project 'Documents/Documents-opensource.xcodeproj'
  
  common_pods
end

target 'Documents' do
  workspace 'ONLYOFFICE-Documents'
  project 'Documents/Documents.xcodeproj'
  
  common_pods
  
  if Dir.exist?('../editors-ios')
    pod 'DocumentConverter', :path => '../editors-ios/DocumentConverter.podspec'
    pod 'SpreadsheetEditor', :path => '../editors-ios/SpreadsheetEditor.podspec'
    pod 'DocumentEditor', :path => '../editors-ios/DocumentEditor.podspec'
    pod 'PresentationEditor', :path => '../editors-ios/PresentationEditor.podspec'
  end

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

def fix_xcworkspaces
  puts "Fix xcworkspaces"

  template = File.open("scripts/xcworkspace.template").read()

  project_names = [
    "Documents",
    "Documents-opensource",
    "Documents-develop"
  ]

  for project_name in project_names do
    begin
      file = File.open("ONLYOFFICE-#{project_name}.xcworkspace/contents.xcworkspacedata", "w")
      file.write(template % { :project => "Documents/#{project_name}.xcodeproj" } ) 
    rescue IOError => e
      #some error occur, dir not writable etc.
    ensure
      file.close unless file.nil?
    end
  end

end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r(
    'Pods/Target Support Files/Pods-Documents/Pods-Documents-acknowledgements.plist',
    'Documents/Settings.bundle/Acknowledgements.plist',
    :remove_destination => true
  )

  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
    end
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
        xcconfig_path = config.base_configuration_reference.real_path
        IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      config.build_settings['ENABLE_BITCODE'] = 'NO'

      target_is_resource_bundle = target.respond_to?(:product_type) && target.product_type == 'com.apple.product-type.bundle'
      target.build_configurations.each do |build_configuration|
        if target_is_resource_bundle
          build_configuration.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
          build_configuration.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
          build_configuration.build_settings['CODE_SIGNING_IDENTITY'] = '-'
          build_configuration.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = '-'
        end
      end
    end
  end

end

post_integrate do |installer|
  fix_xcworkspaces
end
