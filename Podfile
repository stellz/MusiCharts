# Uncomment the next line to define a global platform for your project
platform :ios, '10.1'
# Comment the next line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!
inhibit_all_warnings!

def shared_pods
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'SwiftLint'
    pod 'SwiftKeychainWrapper'
    pod 'Action'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxDataSources'
    pod 'RxReachability'
    pod 'Spring', :git => 'https://github.com/strawb3rryx7/Spring.git'
    pod 'SDWebImage'
    pod 'MarqueeLabel/Swift'
end

target 'MusiChart' do
  # Pods for MusiChart
  shared_pods

end

target 'MusiChartTests' do
    shared_pods
    # Pods for unit testing
    pod 'RxTest'
    pod 'RxBlocking'
end

target 'MusiChartUITests' do
    shared_pods
    # Pods for UI testing
end

