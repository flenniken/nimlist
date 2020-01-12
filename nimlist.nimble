# Package

version       = "0.1.1"
author        = "Steve Flenniken"
description   = "Browse nim packages in your browser."
license       = "MIT"
srcDir        = "src"
bin           = @["nimlist"]



# Dependencies

requires "nim >= 1.0.4"

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open command.
  exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

task m, "Build nimlist command line application":
  exec "nim c -d:ssl --out:nimlist src/nimlist"
  open_in_browser("packages.html")
