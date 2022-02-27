require! <[fs fs-extra livescript terser browserify aliasify disc]>

tinyify = true
opt = {fullPaths: false}
lc = {}
aliasify-config =
  aliases:
    "uglify-js": "./built/uglify-js.js"
    "clean-css": "./built/clean-css.js"
    "constantinople": "./built/constantinople.js"
    "with": "./built/with.js"
  verbose: false
  global: true

fs-extra.ensure-dir-sync \built
fs-extra.ensure-dir-sync \dist/require
fs-extra.ensure-dir-sync \web/static

for k,v of aliasify-config.aliases =>
  [src, des] = ["src/#k.ls", "built/#k.js"]
  console.log "compile #src to #des ..."
  fs.write-file-sync(
    des, livescript.compile(fs.read-file-sync src .toString!, {bare:true})
  )

pug-cfg = do
  name: \pug
  vname: \pug
  mname: \pug
  run: (b) ->
    b.transform(aliasify, aliasify-config)
    b.require("pug")
    b.exclude("fs")

pug-full-cfg = do
  name: \pug.full
  vname: \pug
  mname: \pug
  run: (b) -> b.require("pug")

html2pug-cfg = do
  name: \html2pug
  vname: \html2pug
  mname: \html2pug
  run: (b) ->
    b.transform(aliasify, aliasify-config)
    b.require("html2pug")
    b.exclude("source-map")
    b.exclude("stream-http")

stat = (cfg = {}) -> new Promise (res, rej) ->
  console.log "discify #{cfg.name} ..."
  b = browserify {fullPaths: true}
  cfg.run b
  b.bundle!
    .pipe disc!
    .pipe fs.createWriteStream "web/static/#{cfg.name}.html"
    .once \close, -> res!

bundle = (cfg = {}) ->
  console.log "bundling #{cfg.name} ..."
  p = new Promise (res, rej) ->
    b = browserify opt
    cfg.run b
    if tinyify and !cfg.notiny => b.plugin("tinyify")
    b.bundle (e, b) ->
      if cfg.name => lc[cfg.name] = b
      res b
  p
    .then (b) ->
      fs.write-file-sync "dist/require/#{cfg.name}.js", "#{b}"
      fs.write-file-sync "dist/#{cfg.name}.js", code = "#b;window.#{cfg.vname}=require('#{cfg.mname}')"
      [opt, codes1, codes2] = [{}, {}, {}]
      opt = {compress: true, mangle: toplevel: true}
      console.log "minimize bundled #{cfg.name} ..."
      codes1["#{cfg.name}.js"] = "#{b}"
      codes2["#{cfg.name}.js"] = code
      terser.minify codes1, opt
        .then (result) ->
          fs.write-file-sync "dist/require/#{cfg.name}.min.js", result.code
        .then ->
          terser.minify codes2, opt
        .then (result) ->
          fs.write-file-sync "dist/#{cfg.name}.min.js", result.code

Promise.resolve!
  .then -> bundle pug-cfg
  .then -> bundle html2pug-cfg
  .then -> bundle pug-full-cfg
