# nimlist

Show the nim package list in your browser on one page.

Here is an example page. The page will tell you when it was
created.

[Nim Packages](https://htmlpreview.github.io/?https://raw.githubusercontent.com/flenniken/nimlist/master/packages.html)

## Install

~~~
nimble install nimlist

    Prompt: nimlist not found in any local packages.json, check internet for updated packages? [y/N]
    Answer: y
Downloading Official package list
    Success Package list downloaded.
Downloading https://github.com/flenniken/nimlist using git
  Verifying dependencies for nimlist@0.1.4
 Installing nimlist@0.1.4
   Building nimlist/nimlist using c backend
   Success: nimlist installed successfully.
~~~

## Run

~~~
nimlist

Downloading package list...
Open the html file in your browser:
open /home/steve/.nimlist/packages.html
~~~

## Open Packages.html

In your browser select file > open then browse to the html filename
above and open it to see the web page.

Or, on the mac at the terminal, you can open it with:

~~~
open /home/steve/.nimlist/packages.html
~~~