## Download the nim package list, reformat as an html page and open in
## the default browser.

import os
import times
import httpclient
import json
import streams
import strutils

const packagesUrl = "https://raw.githubusercontent.com/nim-lang/packages/master/packages.json"
# const packagesUrl = "https://flenniken.net/test.json"
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
}
  </style>
</head>
<body>
"""

# name = 1, url = 2, vc = 3, desc = 4, license = 5, web = 6

let packageBlock = """
<div class="package">
<a class="url" href="$2">$1</a> --
$4 $6
</div>
"""

let optionalWebPart = "<a class=\"web\" href=\"$1\"> ...</a>"


let footer = """
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
      web = optionalWebPart % web
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
