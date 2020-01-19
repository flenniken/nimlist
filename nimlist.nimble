# Package

version       = "0.1.5"
author        = "Steve Flenniken"
description   = "View the nim package list in your browser."
license       = "MIT"
srcDir        = "src"
bin           = @["nimlist"]

requires "nim >= 1.0.4"

proc open_in_browser(filename: string) =
  ## Open the given file in a browser if the system has an open command.
  exec "(hash open 2>/dev/null && open $1) || echo 'open $1'" % filename

task m, "Build and run the nimlist command line application":
  exec "nim c -r -d:ssl --hints:off --out:nimlist src/nimlist"
  open_in_browser("~/.nimlist/packages.html")
