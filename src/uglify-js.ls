ret = if uglify-js? => uglify-js else {minify: -> return {code: it}}
module.exports = ret
