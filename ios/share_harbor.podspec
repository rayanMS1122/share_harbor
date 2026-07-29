Pod::Spec.new do |s|
  s.name             = 'share_harbor'
  s.version          = '0.1.0-beta.1'
  s.summary          = 'A durable inbound share inbox for Flutter on Android and iOS.'
  s.description      = <<-DESC
A durable inbound share inbox for Flutter on Android and iOS with transactional delivery guarantees.
                       DESC
  s.homepage         = 'https://github.com/raean/share_harbor'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Raean' => 'raean@shareharbor.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'APPLICATION_EXTENSION_API_ONLY' => 'NO' }
  s.resource_bundles = {'share_harbor_privacy' => ['PrivacyInfo.xcprivacy']}
end
