require! <[fs fs-extra livescript browserify disc]>

tinyify = true
opt = {fullPaths: false}
lc = {}

pug-cfg = do
  name: \pug
  run: (b) ->
    b.require("pug")
    b.exclude("fs")
    b.exclude("uglify-js")
    b.exclude("clean-css")
    b.exclude("constantinople")
    b.exclude("with")

html2pug-cfg = do
  name: \html2pug
  run: (b) ->
    b.require("html2pug")
    b.exclude("clean-css")
    b.exclude("source-map")
    b.exclude("stream-http")
    b.exclude("uglify-js")

fs-extra.ensure-dir-sync \built
fs-extra.ensure-dir-sync \dist/require
fs-extra.ensure-dir-sync \web/static

lsc = (name) ->
  fs.write-file-sync(
    "built/#name.js",
    livescript.compile(fs.read-file-sync("src/#name.ls")toString!,{bare:true})
  )

stat = (cfg = {}) -> new Promise (res, rej) ->
  b = browserify {fullPaths: true}
  cfg.run b
  b.bundle!
    .pipe disc!
    .pipe fs.createWriteStream "web/static/#{cfg.name}.html"
    .once \close, -> res!

bundle = (cfg = {}) -> new Promise (res, rej) ->
  b = browserify opt
  cfg.run b
  if tinyify and !cfg.notiny => b.plugin("tinyify")
  b.bundle (e, b) ->
    if cfg.name => lc[cfg.name] = b
    res b

console.log "bundling pug.full..."
bundle {name: 'pug.full', run: (b) -> b.require("pug") }
  .then ->
    console.log "bundling pug..."
    bundle pug-cfg
  .then ->
    console.log "bundling html2pug..."
    bundle html2pug-cfg
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
    console.log "discify minimized pug bundle..."
    stat pug-cfg
  .then ->
    console.log "discify minimized html2pug bundle..."
    stat html2pug-cfg
  .then ->
    console.log "concat necessary modules and generate dist files..."
    codes = <[with constantinople uglify-js clean-css pug]>.map -> lc[it]
    code = codes.join('')

    # --standalone doesnt work well with browserFs. hacky hardcoded for now
    fs.write-file-sync "dist/pug.js", code + ";window.pug=require('pug');"
    fs.write-file-sync "dist/pug.full.js", lc['pug.full'] + ";window.pug=require('pug');"
    fs.write-file-sync "dist/html2pug.js", lc['html2pug'] + ";window.html2pug=require('html2pug');"
    fs.write-file-sync "dist/require/pug.js", code
    fs.write-file-sync "dist/require/pug.full.js", lc['pug.full']
    fs.write-file-sync "dist/require/html2pug.js", lc['html2pug']

  .then ->
    console.log "done."
