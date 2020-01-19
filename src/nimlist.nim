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

type
  # name, url, vc, desc, license, web, tags, id
  Package = object
    name: string
    url: string
    vc: string
    desc: string
    license: string
    web: string
    tags: seq[string]
    id: int # the package index

  PackagesUsingTag = object
    id: int # the tag index
    pNames: seq[string] # list of package names that use a tag.


proc createPackageList(filename: string): OrderedTable[string, Package] =
  ## Create a package list from the json package list file.

  result = initOrderedTable[string, Package]()

  # Read the json data from the cached file.
  var stream = newFileStream(filename, fmRead)
  var nodeTree = parseJson(stream, filename)

  var id = 0
  for node in nodeTree.elems:
    var name, url, vc, desc, license, web: string
    var tags = newSeq[string]()
    for key, value in node.pairs:
      # name, url, vc, desc, license, web, tags
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
      of "tags":
        for node in value.elems:
          let tag = node.str
          tags.add(tag)
      else:
        discard

    if url == web:
      web = ""
    else:
      let optionalWebPart = "<a class=\"web\" href=\"$1\"> (docs)</a>"
      web = optionalWebPart % web
    # name, url, vc, desc, license, web, tags
    let package = Package(name: name, url: url, vc: vc, desc: desc, license: license,
                          web: web, tags: tags, id: id)
    result[name] = package
    id += 1


proc createTag2nameList(packageList: OrderedTable[string, Package]):
                       OrderedTable[string, PackagesUsingTag] =
  ## Create a tag to package name table from the package list.

  result = initOrderedTable[string, PackagesUsingTag]()
  var id = 0
  for name, package in packageList.pairs:
    for tag in package.tags:
      if not result.hasKey(tag):
        result[tag] = PackagesUsingTag(id: id, pNames: newSeq[string]())
        id += 1
      result[tag].pNames.add(name)

  # Sort the the tag2nameList table by the number of packages that use
  # the tag.
  result.sort(proc (x,y: (string, PackagesUsingTag)): int =
    result = cmp(x[1].pNames.len, y[1].pNames.len), SortOrder.Descending)


proc writeHtmlFile(packageList: OrderedTable[string, Package],
       tag2nameList: OrderedTable[string, PackagesUsingTag], htmlFilename: string) =
  ## Write the package list as html to the given file.

  let header = """
  <!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Nim Package List</title>
    <style>
  #packages {
  }
  .package {
  }
  .ptags {
    font-size: small;
    font-style: italic;
  }
  #tags {
  }
  .tag {
  }
    </style>
  </head>
  <body>
  <h3>Nim Packages</h3>
  <p>Nim package list. See the package <a href="#tags">tags</a> at the bottom.</p>
  <div id="packages">
  """

  # name = 1, url = 2, vc = 3, desc = 4, license = 5, web = 6

  let packageBlock = """
  <div id="p$7" class="package">
  <a class="url" href="$2">$1</a> --
  $4 $6 $8
  </div>
  """

  let middleBlock = """
  </div>
  <h3>Tags</h3>
  <div id="tags">
  """

  let footer = """
  </div>
  </body>
  </html>
  """

  var file = open(htmlFilename, fmWrite)
  defer: file.close()
  file.writeLine(header)

  # Write the packages one per line.
  for name, p in packageList.pairs:
    var theTags: string
    if p.tags.len > 0:
      var htmlTags = newSeq[string]()
      for tag in p.tags:
        htmlTags.add("<a href=\"#t$1\">$2</a>" % [$tag2nameList[tag].id, tag])
      theTags = "<span class=\"ptags\">[$1]</span>" % htmlTags.join(", ")
    var section = packageBlock % [p.name, p.url, p.vc, p.desc, p.license, p.web, $p.id, theTags]
    file.writeLine(section)

  file.writeLine(middleBlock)

  let tagBlock = """
  <div id="t$1" class="tag">
  <span>$2</span> <span>$3</span> <span class="tags2">$4</span>
  </div>
  """

  # Write the tag block.
  for tag, pUsingName in tag2nameList.pairs:
    var names = newSeq[string]()
    for name in pUsingName.pNames:
      var package = packageList[name]
      let aName = "<a href=\"#p$1\">$2</a>"
      names.add(aName % [$package.id, name])
    var section = tagBlock % [$pUsingName.id, tag, $pUsingName.pNames.len, names.join(" ")]
    file.writeLine(section)

  file.writeLine(footer)


proc downloadPackageJson(jsonFilename: string) =

  # The url of the nim packages json.
  const packagesUrl = "https://raw.githubusercontent.com/nim-lang/packages/master/packages.json"
  # Download a new json file when it is x minutes old.
  const minutesOld = 60 * 24

  # Determine whether we need to download the package list file.
  var download = false
  if not fileExists(jsonFilename):
    download = true
  else:
    # Download the package list if it is old.
    let jsonTime = getLastModificationTime(jsonFilename)
    let now = getTime()
    let dur = initDuration(minutes=minutesOld)
    if now - jsonTime > dur:
      download = true

  if download:
    echo "Downloading package list..."
    var client = newHttpClient()
    let tempFilename = jsonFilename & ".temp"
    client.downloadFile(packagesUrl, tempFilename)
    moveFile(tempFilename, jsonFilename)


proc main() =
  ## Download the nim package list to the user's .nimlist folder then
  ## make an html file out of it.

  # Create the .nimlist folder if necessary.
  let nimListDir = joinPath(getHomeDir(), ".nimlist")
  discard existsOrCreateDir(nimListDir)

  # Download the package list json if necessary.
  let jsonFilename = joinPath(nimListDir, "packages.json")
  downloadPackageJson(jsonFilename)

  # Parse the package list.
  var packageList = createPackageList(jsonFilename)
  var tag2nameList = createTag2nameList(packageList)

  # Write the package list as html.
  let htmlFilename = joinPath(nimListDir, "packages.html")
  writeHtmlFile(packageList, tag2nameList, htmlFilename)

  # Open the html file in the default browser.
  echo """
Open the html file in your browser:
open $1
""" % [htmlFilename]


when isMainModule:
  try:
    main()
  except:
    let message = getCurrentExceptionMsg()
    echo "Error: " & message
    echo "Stack at time of error:"
    raise
