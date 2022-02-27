(function(){
  var sandbox;
  sandbox = function(opt){
    var root, container, that, wopt;
    opt == null && (opt = {});
    this.opt = opt;
    this.proxy = {};
    this.root = root = opt.root ? typeof opt.root === 'string'
      ? document.querySelector(opt.root)
      : opt.root : void 8;
    this.container = container = (that = root && root.parentNode)
      ? that
      : this.opt.container ? typeof opt.container === 'string'
        ? document.querySelector(opt.container)
        : opt.container : void 8;
    if (!container) {
      container = this.container = null;
    }
    if (this.container) {
      if (!root) {
        this.root = root = document.createElement("iframe");
      }
      if (!this.root.parentNode) {
        container.appendChild(root);
      }
      root.setAttribute('sandbox', opt.sandbox || 'allow-scripts allow-pointer-lock allow-popups');
      (this.opt.className || '').split(' ').filter(function(it){
        return it;
      }).map(function(it){
        return root.classList.add(it);
      });
    }
    if (wopt = opt.window) {
      this.openWindow(wopt);
    }
    return this;
  };
  sandbox.prototype = import$(Object.create(Object.prototype), {
    rpcCode: '<script>\nwindow.addEventListener("message", function(e) {\nif(e.data.type == \'load\') {\n  window.location.href = URL.createObjectURL(new Blob([e.data.args.content], {type: \'text/html\'}));\n  return;\n}\nif(!e || !e.data || e.data.type != \'rpc\') return;\nwindow[e.data.name][e.data.func](e.data.args);\n}, false);\n</script>',
    openWindow: function(wopt){
      var this$ = this;
      wopt == null && (wopt = {});
      return new Promise(function(res, rej){
        var url;
        if (!wopt.name) {
          wopt.name = "sandboxjs-" + Math.random().toString(36).substring(2);
        }
        url = URL.createObjectURL(new Blob([this$.rpcCode], {
          type: 'text/html'
        }));
        this$.window = window.open(url, wopt.name, "width=" + (wopt.width || 480) + ",height=" + (wopt.height || 640));
        this$.opt.window = wopt;
        return this$.window.onload = function(){
          return res();
        };
      });
    },
    send: function(msg){
      return [this.window, this.root ? this.root.contentWindow : null].map(function(it){
        if (it) {
          return it.postMessage({
            type: 'msg',
            payload: msg
          }, '*');
        }
      });
    },
    setProxy: function(obj){
      var k, v, ref$, name, proxy, results$ = [], this$ = this;
      ref$ = (function(){
        var ref$, results$ = [];
        for (k in ref$ = obj) {
          v = ref$[k];
          results$.push([k, v]);
        }
        return results$;
      }())[0], name = ref$[0], obj = ref$[1];
      this.proxy = proxy = {};
      for (k in obj) {
        v = obj[k];
        results$.push(fn$(k, v));
      }
      return results$;
      function fn$(k, v){
        return proxy[k] = function(){
          var args, res$, i$, to$;
          res$ = [];
          for (i$ = 0, to$ = arguments.length; i$ < to$; ++i$) {
            res$.push(arguments[i$]);
          }
          args = res$;
          return [this$.window, this$.root ? this$.root.contentWindow : null].map(function(it){
            if (it) {
              return it.postMessage({
                type: 'rpc',
                name: name,
                func: k,
                args: args
              }, '*');
            }
          });
        };
      }
    },
    reload: function(){
      var this$ = this;
      return new Promise(function(res, rej){
        var ref$;
        if (this$.root) {
          ref$ = this$.root;
          ref$.onload = function(){
            return res(this$.url);
          };
          ref$.src = this$.url;
        }
        if (this$.opt.window) {
          return this$.window.postMessage({
            type: 'load',
            args: {
              url: this$.url,
              content: this$.content
            }
          });
        }
      });
    },
    load: function(d){
      var promises, this$ = this;
      d == null && (d = "");
      if (typeof d === 'string') {
        return new Promise(function(res, rej){
          var url;
          this$.content = d + this$.rpcCode;
          this$.url = url = URL.createObjectURL(new Blob([d + this$.rpcCode], {
            type: 'text/html'
          }));
          return this$.reload();
        });
      }
      promises = ['html', 'css', 'js'].map(function(it){
        return [it, d[it]];
      }).filter(function(it){
        return it[1];
      }).map(function(n){
        if (n[1] && n[1].url) {
          return fetch(n[1].url).then(function(v){
            if (!(v && v.ok)) {
              v.clone().text().then(function(t){
                var e, ref$;
                e = (ref$ = new Error(v.status + " " + t), ref$.data = v, ref$);
                throw e;
              });
            }
            return v.text();
          }).then(function(it){
            return [n[0], it];
          });
        } else {
          return Promise.resolve([n[0], n[1]]);
        }
      });
      return Promise.all(promises).then(function(list){
        var d;
        d = {};
        list.map(function(it){
          return d[it[0]] = it[1];
        });
        return this$.load("" + (d.html || '') + "\n<script>\n//<![[CDATA\n" + d.js + "\n//]]>\n</script>\n<style type=\"text/css\">\n/*<![[CDATA*/\n" + d.css + "\n/*]]>*/\n</style>");
      });
    }
  });
  if (typeof module != 'undefined' && module !== null) {
    module.exports = sandbox;
  } else if (typeof window != 'undefined' && window !== null) {
    window.sandbox = sandbox;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
