Noir
----

__Noir__ is [miniLock](https://minilock.io) encryption with minimal decoration.
It mostly works in Google Chrome.

Visit [__45678.github.io/noir__](https://45678.github.io/noir) to start a session and try it out.

Download [__Noir.crx__](https://45678.github.io/noir/Noir.crx) for Google Chrome to keep the app on your personal computer.
When the download is complete, open [chrome://extensions](chrome://extensions) and drag __Noir.crx__ onto the Extensions page to install it.
__Noir__ will update itself automatically when new versions are available.

Or clone the __Noir__ code and run it from source:

    git clone https://github.com/45678/noir.git
    cd noir
    make bundle
    open bundle/window.html

Or host __Noir__ on your personal computer with [Pow](http://pow.cx/):

    git clone https://github.com/45678/noir.git
    cd noir
    make bundle pow
    open http://noir.dev/window.html
