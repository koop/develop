develop.svn.wordpress.org
=========================

This is the structure we plan on using for the new WordPress development repository, which will live at `develop.svn.wordpress.org`. Needless to say, it is a work in progress.


Requirements
------------
To take advantage of all of the goodies in the new repository, you'll have to install [Node.js](http://nodejs.org/) and the [Grunt CLI](http://gruntjs.com/getting-started).

To install Node, you can [download and install the package](http://nodejs.org/), or you can use a package manager, like [Homebrew](http://brew.sh/).

Once you've installed Node, you can install the Grunt CLI. Run `npm install -g grunt-cli`.


Getting Started
---------------
1. Clone this repository in a directory of your choice by running `git clone https://github.com/koop/develop.git`.
2. Navigate to the directory in your shell.
3. Run `npm install`.
4. Run `grunt setup`. This is a temporary step to pull in code that will eventually live inside of the develop repository.


Documentation
-------------

The `src` directory contains the WordPress core files. You can develop against the `src` directory like you normally would develop against trunk.

### `grunt build`
Generates the production-optimized source in the `build` directory.

### `grunt clean`
Removes the `build` directory.

### `grunt watch`
Currently in development (like everything else), and will likely be split into several tasks. Grunt can watch files as you develop and provide instant feedback. In this case, it copies changed files over to the `build` directory. 

### `grunt setup`
A temporary task that pulls in code that will eventually live inside of the repository. Checks out a copy of WordPress core into the `src` directory.

