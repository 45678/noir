Noir
----

Noir is [miniLock](https://minilock.io) encryption with minimal decoration.
It mostly works in Google Chrome.

Get Noir to start a session:

    open https://45678.github.io/noir

Download Noir for Google Chrome to keep the app on your personal computer:

    curl https://45678.github.io/noir/Noir.crx > Noir.crx
    open Noir.crx

Or clone the Noir code and run it from source:

    git clone https://github.com/45678/noir.git
    cd noir
    make bundle
    open bundle/window.html

Or host Noir on your personal computer with [Pow](http://pow.cx/):

    git clone https://github.com/45678/noir.git
    cd noir
    make bundle pow
    open http://noir.dev/window.html
