# Package

version       = "0.1.0"
author        = "Steve Flenniken"
description   = "Browse nim packages in your browser."
license       = "MIT"
srcDir        = "src"
bin           = @["nimlist"]



# Dependencies

requires "nim >= 1.0.4"

task m, "Build nimlist command line application":
  exec "nim c -d:ssl --out:nimlist src/nimlist"
