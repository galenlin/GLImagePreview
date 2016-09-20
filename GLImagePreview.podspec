#
# Be sure to run `pod lib lint GLImagePreview.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GLImagePreview'
  s.version          = '0.1.0'
  s.summary          = 'iOS图片预览'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
iOS图片预览，支持缩放效果，支持预览一组图片
                       DESC

  s.homepage         = 'https://github.com/galenlin/GLImagePreview'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'galenlin' => 'oolgloo.2012@gmail.com' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/GLImagePreview.git', :tag => s.version.to_s }
  s.social_media_url = 'https://weibo.com/galenlin'

  s.ios.deployment_target = '7.0'

  s.source_files = 'GLImagePreview/Classes/**/*'
  s.public_header_files = "GLImagePreview/Classes/*.h"
  s.private_header_files = "GLImagePreview/Classes/_*.h"

  # s.resource_bundles = {
  #   'GLImagePreview' => ['GLImagePreview/Assets/*.png']
  # }

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SDWebImage', '~> 3.8.2'
  s.dependency 'MBProgressHUD', '~> 1.0.0'
end
