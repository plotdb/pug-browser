if clean-css? => ret = clean-css
else
  ret = -> @
  ret.prototype = Object.create(Object.prototype) <<< { minify: -> {styles:it} }

module.exports = ret
