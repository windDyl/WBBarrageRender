

Pod::Spec.new do |s|


  s.name         = "WBBarrageRender"
  s.version      = "1.0.0"
  s.summary      = "A high performance WBBarrageRender engine for iOS"


  s.description  = <<-DESC
    A high performance WBBarrageRender engine for iOS.
                   DESC

  s.homepage     = "https://github.com/windDyl/WBBarrageRender.git"


  s.license      = "MIT"


  s.author             = { "liudongyang" => "ldy2260479085@163.com" }


  s.source       = { :git => "https://github.com/windDyl/WBBarrageRender.git", :tag => "1.0.0" }

s.source_files  = "WBBarrageRender/*.{h,m}"
#s.exclude_files = "Classes/Exclude"

   s.framework  = "UIKit"

   s.requires_arc = true


end
