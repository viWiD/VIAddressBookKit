Pod::Spec.new do |s|
  s.name         = "VIAddressBookKit"
  s.version      = "0.1.0"
  s.summary      = "iOS Address Book Wrapper"
  s.description  = <<-DESC
    VIAddressBookKit provides a simple Swift Interface for the iOS Address Book.
    DESC
  s.homepage     = "http://github.com/viWiD/VIAddressBookKit"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = { "Nils Fischer" => "n.fischer@viwid.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/viWiD/VIAddressBookKit.git", :tag => "v0.1.0" }
  s.source_files = "VIAddressBookKit"
  s.dependency 'Evergreen'
end
