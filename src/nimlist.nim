## Download the nim package list, reformat as an html page and open in
## the default browser.

import os
import times
import httpclient
import json
import streams
import strutils
import tables
import algorithm

const packagesUrl = "https://raw.githubusercontent.com/nim-lang/packages/master/packages.json"
# const packagesUrl = "https://flenniken.net/test.json"
const jsonFilename = "packages.json"
const tempFilename = "packages.json.temp"
const htmlFilename = "packages.html"
const minutesOld = 60 * 24
const minimumTags = 1

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
<h3>Nim Packages</h3>
<p>Nim package list. Click tags to see the list of <a href="#tags">tags</a>.</p>
<div id="packages">
"""

# name = 1, url = 2, vc = 3, desc = 4, license = 5, web = 6

let packageBlock = """
<div id="p$7" class="package">
<a class="url" href="$2">$1</a> --
$4 $6
</div>
"""

let optionalWebPart = "<a class=\"web\" href=\"$1\"> (docs)</a>"

let middleBlock = """
</div>
<h3>Tags</h3>
<div id="tags">
"""

let tagBlock = """
<div class="tag">
<span>$1</span> <span>$2</span>: $3
</div>
"""

let aName = "<a href=\"#p$1\">$2</a>"


let footer = """
</div>
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

  # count, tag name, package name
  # 30 tag1 name name name name...
  # 27 tag2 name name...
  # 10 tag3 name name...
  # 1 tag4 name
  # 1 tag5 name

  var pNum = 1
  var name2pNum = initTable[string, int]()
  var tag2nameList = initOrderedTable[string, seq[string]]()
  file.writeLine(header)
  for node in nodeTree.elems:
    var name, url, vc, desc, license, web: string
    for key, value in node.pairs:
      # name, url, vc, desc, license, web
      case key
      of "name":
        name = value.str
        name2pNum[name] = pNum
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
      of "tags":
        for node in value.elems:
          let tag = node.str
          if not tag2nameList.hasKey(tag):
            tag2nameList[tag] = newSeq[string]()
          tag2nameList[tag].add(name)
      else:
        discard
    if url == web:
      web = ""
    else:
      web = optionalWebPart % web
    var section = packageBlock % [name, url, vc, desc, license, web, $pNum]
    pNum += 1
    file.writeLine(section)

  file.writeLine(middleBlock)

  # let tagBlock = """
  # <div class="tag">
  # <span>count</span> <span>tag</span>: name name name...
  # </div>
  # """

  # Sort the the tag2nameList table by the number of packages that use
  # the tag.
  # proc sort[A, B](t: var OrderedTable[A, B]; cmp: proc (x, y: (A, B)): int)
  tag2nameList.sort(proc (x,y: (string, seq[string])): int =
    result = cmp(x[1].len, y[1].len), SortOrder.Descending)

  # Write the tag block.
  for tag, nameList in tag2nameList.pairs:
    # Skip the tags with only 1 package.
    if nameList.len <= minimumTags:
      break
    var names = newSeq[string]()
    for name in nameList:
      # let aName = "<a href=\"#p$1\">$2</a>"
      var pNum: int = name2pNum[name]
      names.add(aName % [$pNum, name])
    var section = tagBlock % [$nameList.len, tag, names.join(" ")]
    file.writeLine(section)

  file.writeLine(footer)

  # Open the html file in the default browser.
  echo "Open packages.html in your browser."

when isMainModule:
  try:
    main(jsonFilename)
  except:
    let message = getCurrentExceptionMsg()
    echo "Error: " & message
    echo "Stack at time of error:"
    raise
