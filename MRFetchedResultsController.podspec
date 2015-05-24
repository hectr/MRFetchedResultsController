
Pod::Spec.new do |s|

  s.name         = "MRFetchedResultsController"
  s.version      = "0.1.0"
  s.summary      = "Extensible drop-in replacement for NSFetchedResultsController."

  s.description  = <<-DESC
                   **MRFetchedResultsController** is a drop-in replacement for `NSFetchedResultsController` that works on Mac and iOS.

                   Its purpose is to provide an alternative that makes it possible to extend `NSFetchedResultsController` functionallity without having to deal with private APIs.
                   DESC

  s.homepage     = "https://github.com/hectr/MRFetchedResultsController"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author             = { "Héctor Marqués Ranea" => "h@mrhector.me" }

  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.7"

  s.source       = { :git => "https://github.com/hectr/MRFetchedResultsController.git", :tag => "0.1.0" }

  s.source_files  = "MRFetchedResultsController"

  s.framework  = "CoreData"

  s.requires_arc = true

end
