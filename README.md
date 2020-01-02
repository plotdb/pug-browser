# pug-browser

Builder for Pug running in Browsers. [Live Demo](https://plotdb.github.io/pug-browser/)

## Usage

execute the following:

```
    npm install; npm run build
```

generated pug file will be available in `dist/` folder.


## Why

Client side Pug is useful for purpose like online pug editing and realtime preview. One can simply use browserify to generate a bundle js file for running Pug in browser, yet 

 * `fs` is not available in browser.
 * bundle file is quite huge.

Here is a size statistics of a bundled pug js file, generated with discify from hughsk/disc:

![module size statistics](https://raw.githubusercontent.com/plotdb/pug-browser/master/index.png)


Following are the modules to be blamed for:

 * constantinople - for checking if a expression is constant. for performance optimization. 445KB
 * uglify-js - use to minfiy js in pug-filters and pug-runtime. 400KB
 * clean-css - use to minify css in pug-filters. 394KB
 * with - for mimic `with` syntax. 149KB
 * is-expression - 123KB

And the result bundle file can be 1.4MB(tinyified) to 2MB. Removing `constantinople`, `uglify-js`, `clean-css` and `with` can reduce the file size to 170KB, nearly 1/10 in size.

## How

We use browserify to overwrite and replace above modules with following behavior, which could be found in `src/`:

 * clean-css and uglify-js - return original string without minifying.
 * constantinople - always return false for constant testing.
 * with - use language feature `with` directly.


## FileSystem

We don't provide `fs` module for browser but you can use `BrowserFS` for supporting include / extend directly in browser. Following is a sample code to make it work:

```
    script(src="https://cdnjs.cloudflare.com/ajax/libs/BrowserFS/2.0.0/browserfs.min.js")
    script.
      BrowserFS.install(window)
      BrowserFS.configure({fs: "LocalStorage"}, function() {
        window.fs = fs = require("fs");
        fs.writeFileSync("sample.pug", "h1 Hello World!");
      });
      pug = require("pug");
      result = pug.render("include sample.pug", {filename: "index.pug", basedir: "."});
```


## Discussion 

The minimized Pug.js works at least for some simple cases with include, var interpolation, mixin, &attributes and loop, yet It's more like just an experiment and removing these modules will possibly cause some major issues like in performance. We need more tests about it before actually using it in production site.

Additionally, since constantinople is for optimization, it's possible that we optionally use some nondeterministic algorithms as alternatives instead of including a whole js parser when size is a major concern.


## License

MIT License.
