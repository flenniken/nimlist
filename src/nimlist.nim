## Download the nim package list, reformat as an html page and open in
## the default browser.

import os
import times
import httpclient
import json
import streams
import strutils

# const packagesUrl = "https://raw.githubusercontent.com/nim-lang/packages/master/packages.json"
const packagesUrl = "https://flenniken.net/test.json"
const jsonFilename = "packages.json"
const tempFilename = "packages.json.temp"
const htmlFilename = "packages.html"
const minutesOld = 60 * 24

let header = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Nim Package List</title>
  <style>
.package {
  padding-left: 1.5em;
  text-indent: -1.5em;
}
.licenseMIT {
  display: inline-block;
  width: 1em;
  height: 1em;
  background: #F8E6AE url(mit.svg) no-repeat 0px 0px;
}
.vcgit {
  display: inline-block;
  width: 1em;
  height: 1em;
  background-image: 
    url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHdpZHRoPScxMCcgaGVpZ2h0PScxMCc+PGxpbmVhckdyYWRpZW50IGlkPSdncmFkaWVudCc+PHN0b3Agb2Zmc2V0PScxMCUnIHN0b3AtY29sb3I9JyNGMDAnLz48c3RvcCBvZmZzZXQ9JzkwJScgc3RvcC1jb2xvcj0nI2ZjYycvPiA8L2xpbmVhckdyYWRpZW50PjxyZWN0IGZpbGw9J3VybCgjZ3JhZGllbnQpJyB4PScwJyB5PScwJyB3aWR0aD0nMTAwJScgaGVpZ2h0PScxMDAlJy8+PC9zdmc+");
}
  </style>
</head>
<body>
"""

# name = 1, url = 2, vc = 3, desc = 4, license = 5, web = 6

let packageBlock = """
<div class="package">
<span class="license">$5</span>
<a class="url" href="$2">$1</a>
 -- 
<span class="desc">$4</span>
$6
</div>
"""

let footer = """
  <!-- <script src="js/scripts.js"></script> -->
</body>
</html>
"""

proc main(cachedFilename: string) =
  # cachedFilename is the file name of the cached package list file.

  # Determine whether we need to download the package list file.
  var download = false
  if not fileExists(cachedFilename):
    download = true
  else:
    # Download the package list if it is old.
    let jsonTime = getLastModificationTime(cachedFilename)
    let now = getTime()
    let dur = initDuration(minutes=minutesOld)
    if now - jsonTime > dur:
      download = true

  if download:
    echo "Downloading package list..."
    var client = newHttpClient()
    client.downloadFile(packagesUrl, tempFilename)
    moveFile(tempFilename, cachedFilename)

  # Read the json data from the cached file.
  var stream = newFileStream(cachedFilename, fmRead)
  var nodeTree = parseJson(stream, cachedFilename)

  # Write the package data as html.
  var file = open(htmlFilename, fmWrite)
  defer: file.close()
  
  file.writeLine(header)
  for node in nodeTree.elems:
    var name, url, vc, desc, license, web: string
    for key, value in node.pairs:
      # name, url, vc, desc, license, web
      case key
      of "name":
        name = value.str
      of "url":
        url = value.str
      of "method":
        vc = value.str
      of "description":
        desc = value.str
      of "license":
        license = value.str
      of "web":
        web = value.str
      else:
        discard
    if url == web:
      web = ""
    else:
      web = "<a class=\"web\" href=\"$1\"> more</a>" % web
    var section = packageBlock % [name, url, vc, desc, license, web]
    file.writeLine(section)
  file.writeLine(footer)


  # Open the html in the default browser.


when isMainModule:
  try:
    main(jsonFilename)
  except:
    let message = getCurrentExceptionMsg()
    echo "Error: " & message
    echo "Stack at time of error:"
    raise
