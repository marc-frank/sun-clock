# Adds the WidgetKit extension (ios/SunClockWidget) to ios/Runner.xcodeproj:
# a "SunClockWidget" app-extension target embedded in Runner, SharedStore
# shared with Runner, and the App Group entitlements. Safe to run again.
# CI runs it before every iOS build (there is no Mac to keep the Xcode
# project edited by hand); to work in Xcode, run it once:
#   ruby tool/ios/add_widget_target.rb
# It needs the xcodeproj gem (comes with CocoaPods).

require 'xcodeproj'

root = File.expand_path('../..', __dir__)
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

if project.targets.any? { |t| t.name == 'SunClockWidget' }
  puts 'SunClockWidget target already present'
  exit 0
end

version = File.read(File.join(root, 'pubspec.yaml'))[/^version:\s*([^\s+]+)\+?(\d*)/, 0]
name, build = version.sub('version:', '').strip.split('+')

runner = project.targets.find { |t| t.name == 'Runner' }
ext = project.new_target(:app_extension, 'SunClockWidget', :ios, '16.0', nil, :swift)

group = project.main_group.new_group('SunClockWidget', 'SunClockWidget')
sources = %w[SunCalc.swift SharedStore.swift WidgetViews.swift SunClockWidget.swift]
refs = sources.map { |f| group.new_reference(f) }
group.new_reference('Info.plist')
group.new_reference('SunClockWidget.entitlements')
ext.add_file_references(refs)

# The app stores what the widget reads.
shared = refs.find { |r| r.path == 'SharedStore.swift' }
runner.add_file_references([shared])
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
runner_group&.new_reference('Runner.entitlements')

ext.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.sunriseclock.sunClock.SunClockWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'SunClockWidget/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = 'SunClockWidget/SunClockWidget.entitlements'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['MARKETING_VERSION'] = name
  s['CURRENT_PROJECT_VERSION'] = build.to_s.empty? ? '1' : build
  s['SKIP_INSTALL'] = 'YES'
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks']
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
end

runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Embed the extension in the app, before Flutter's "Thin Binary" script so
# Xcode sees no dependency cycle.
runner.add_dependency(ext)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
file = embed.add_file_reference(ext.product_reference)
file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

project.save
puts "Added SunClockWidget #{name} (#{build})"
