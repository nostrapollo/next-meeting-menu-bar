cask "next-meeting" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/nostrapollo/next-meeting-menu-bar/releases/download/v#{version}/NextMeeting.zip"
  name "NextMeeting"
  desc "Menu bar app showing countdown to your next calendar meeting"
  homepage "https://github.com/nostrapollo/next-meeting-menu-bar"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "NextMeeting.app"

  postflight do
    # Remove quarantine attribute so unsigned app can launch
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/NextMeeting.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.nostrapollo.NextMeeting.plist",
    "~/Library/Application Support/NextMeeting",
  ]

  caveats <<~EOS
    NextMeeting is an unsigned open source app.
    
    If macOS blocks it on first launch:
      1. Right-click the app → Open → Click "Open"
      
    Or run: xattr -cr /Applications/NextMeeting.app
  EOS
end
