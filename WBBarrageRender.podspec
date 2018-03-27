

Pod::Spec.new do |s|


  s.name         = "WBBarrageRender"
  s.version      = "1.0.0"
  s.summary      = "A short description of WBBarrageRender."


  s.description  = <<-DESC
    A high performance danmaku engine for iOS
                   DESC

  s.homepage     = "https://github.com/windDyl/"


  s.license      = "MIT (example)"


  s.author             = { "liudongyang" => "ldy2260479085@163.com" }


  s.source       = { :git => "https://github.com/windDyl/WBBarrageRender.git", :tag => "1.0.0" }

  s.source_files  = "WBBarrageRender"
#s.exclude_files = "Classes/Exclude"

   s.framework  = "UIKit"

   s.requires_arc = true


end
