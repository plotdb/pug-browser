require! <[fs fs-extra LiveScript browserify uglify-js]>

tinyify = true
opt = {fullPaths: false}
lc = {}

fs-extra.ensure-dir-sync \built
fs-extra.ensure-dir-sync \dist

lsc = (name) ->
  fs.write-file-sync(
    "built/#name.js",
    LiveScript.compile(fs.read-file-sync("src/#name.ls")toString!,{bare:true})
  )

bundle = (cfg = {}) -> new Promise (res, rej) ->
  b = browserify opt
  cfg.run b
  if tinyify => b.plugin("tinyify")
  b.bundle (e, b) ->
    if cfg.name => lc[cfg.name] = b
    res b

console.log "bundling pug.full..."
bundle {name: 'pug.full', run: (b) -> b.require("pug") }
  .then ->
    console.log "bundling pug..."
    bundle do
      name: \pug
      run: (b) ->
        b.require("pug")
        b.exclude("fs")
        b.exclude("uglify-js")
        b.exclude("clean-css")
        b.exclude("constantinople")
        b.exclude("with")
  .then ->
    console.log "bundling dummy uglify-js..."
    lsc \uglify-js
    bundle do
      name: \uglify-js
      run: (b) -> b.require("./built/uglify-js.js", {expose: "uglify-js"})
  .then ->
    console.log "bundling dummy clean-css..."
    lsc \clean-css
    bundle do
      name: \clean-css
      run: (b) -> b.require("./built/clean-css.js", {expose: "clean-css"})
  .then ->
    console.log "bundling dummy constantinople..."
    lsc \constantinople
    bundle do
      name: \constantinople
      run: (b) -> b.require("./built/constantinople.js", {expose: "constantinople"})
  .then ->
    console.log "bundling dummy with..."
    lsc \with
    bundle do
      name: \with
      run: (b) -> b.require("./built/with.js", {expose: "with"})
  .then ->
    console.log "concat necessary modules..."
    codes = <[with constantinople uglify-js clean-css pug]>.map -> lc[it]
    code = codes.join('')
    fs.write-file-sync "dist/pug.js", code
    fs.write-file-sync "dist/pug.full.js", lc['pug.full']
    #console.log "minify pug.js..."
    #mincode = codes.map(-> uglify-js.minify(it).code).join('')
    #fs.write-file-sync "pug.min.js", mincode
    #console.log "minify pug.full.js..."
    #fs.write-file-sync "pug.full.min.js", uglify-js.minify(lc['pug.full']).code
  .then ->
    console.log "done."
