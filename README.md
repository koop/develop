A New Structure for WordPress Core
==================================

This is the structure we plan on using for the new WordPress development repository, which will live at `develop.svn.wordpress.org`. Needless to say, it is a work in progress.


**If you'd like to learn more about this project or provide feedback, please read [this post](http://wp.me/p2AvED-1AI).**

----


Requirements
------------
To take advantage of all of the goodies in the new repository, you'll have to install [Node.js](http://nodejs.org/) and the [Grunt CLI](http://gruntjs.com/getting-started).

* **Install Node.js:** You can [download and install the package](http://nodejs.org/) or use a package manager, like [Homebrew](http://brew.sh/).
* **Install the Grunt CLI:** After installing Node, run `npm install -g grunt-cli` in your shell.


Getting Started
---------------
Once you've installed Node.js and the Grunt CLI, you're ready to get started.

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

