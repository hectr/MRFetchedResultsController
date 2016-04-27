
Pod::Spec.new do |s|

  s.name         = "MRFetchedResultsController"
  s.version      = "0.2.0"
  s.summary      = "Extensible drop-in replacement for NSFetchedResultsController."

  s.description  = <<-DESC
                   **MRFetchedResultsController** is a drop-in replacement for `NSFetchedResultsController` that works on Mac and iOS.

                   Its purpose is to provide an alternative that makes it possible to extend `NSFetchedResultsController` functionallity without having to deal with private APIs.

                   In apps ported to Mac OS X using [Chameleon](https://github.com/BigZaphod/Chameleon), **MRFetchedResultsController** addresses the lack of an implementation of `NSFetchedResultsController` for the platform by providing an alternative that can be used in both iOS and Mac versions of the apps.
                   DESC

  s.homepage         = "https://github.com/hectr/MRFetchedResultsController"
  s.license          = "MIT"
  s.author           = { "hectr" => "h@mrhector.me" }
  s.social_media_url = 'https://twitter.com/hectormarquesra'

  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.7"

  s.source = { :git => "https://github.com/hectr/MRFetchedResultsController.git", :tag => s.version.to_s }

  s.source_files  = "MRFetchedResultsController"

  s.framework = "CoreData"

  s.requires_arc = true

end
