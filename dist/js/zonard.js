(function() {
  var BorderView, Cards, CentralHandle, ContentView, DisplayContainerView, DragbarView, HandleView, HandlerContainerView, RotateHandleView, SelectionView, TrackerView, animationFrame, b, calculators, classPrefix, d, ordCards, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  calculators = (function() {
    var sgn, _calculateCentralDrag, _calculateMove, _calculateResize, _calculateRotate, _setState, _sniffState;
    sgn = function(x) {
      return x < 0 ? -1 : 1;
    };
    _sniffState = function(data) {
      var angleDeg, angleRad, box, cos, h, matrix, minMouse, sign, sin, tab, w;
      if (data == null) {
        data = {};
      }
      this._state = $.extend(true, this._state, data);
      matrix = this.$el.css('transform');
      tab = matrix.substr(7, matrix.length - 8).split(', ');
      cos = parseFloat(tab[0]);
      sin = parseFloat(tab[1]);
      sign = sgn(sin);
      angleRad = sign * Math.acos(cos);
      angleDeg = angleRad * 360 / (2 * Math.PI);
      this._state.angle = {
        rad: angleRad,
        deg: angleDeg,
        cos: cos,
        sin: sin
      };
      box = this.el.getBoundingClientRect();
      w = this.$el.width();
      h = this.$el.height();
      this._state.angle.cos = Math.cos(this._state.angle.rad);
      this._state.angle.sin = Math.sin(this._state.angle.rad);
      this._state.elPosition = {
        left: parseInt(this.$el.css('left').slice(0, -2)),
        top: parseInt(this.$el.css('top').slice(0, -2))
      };
      this._state.workspaceOffset = this.$workspace.offset();
      this._state.elOffset = {
        left: this._state.workspaceOffset.left + this._state.elPosition.left,
        top: this._state.workspaceOffset.top + this._state.elPosition.top
      };
      this._state.positionBounds = {
        ox: -Infinity,
        oy: -Infinity,
        x: Infinity,
        y: Infinity
      };
      this._state.elDimension = {
        width: w,
        height: h
      };
      this._state.rotatedCenter = {
        x: this._state.elOffset.left + (w / 2) * this._state.angle.cos - (h / 2) * this._state.angle.sin,
        y: this._state.elOffset.top + (w / 2) * this._state.angle.sin + (h / 2) * this._state.angle.cos
      };
      this._state.elCenter = {
        x: this._state.elOffset.left + w / 2,
        y: this._state.elOffset.top + h / 2
      };
      if (this._state.card != null) {
        this._state.coef = this.coefs[this._state.card];
        this._state.minMouse = minMouse = {
          x: (w - this.sizeBounds.wMin) * this._state.coef[0],
          y: (h - this.sizeBounds.hMin) * this._state.coef[1]
        };
      }
      return this.getBox();
    };
    _setState = function(data) {
      var h, minMouse, rad, w;
      if (data == null) {
        data = {};
      }
      this._state = $.extend(true, this._state, data);
      rad = this.box.rotate * 2 * Math.PI / 360;
      this._state.angle = {
        rad: rad,
        deg: this.box.rotate,
        cos: Math.cos(rad),
        sin: Math.sin(rad)
      };
      this._state.elDimension = {
        width: w = this.box.width,
        height: h = this.box.height
      };
      this._state.elPosition = {
        left: this.box.left,
        top: this.box.top
      };
      this._state.workspaceOffset = this.$workspace.offset();
      this._state.elOffset = {
        left: this._state.workspaceOffset.left + this._state.elPosition.left,
        top: this._state.workspaceOffset.top + this._state.elPosition.top
      };
      this._state.positionBounds = {
        ox: -Infinity,
        oy: -Infinity,
        x: Infinity,
        y: Infinity
      };
      this._state.rotatedCenter = {
        x: this._state.elOffset.left + (w / 2) * this._state.angle.cos - (h / 2) * this._state.angle.sin,
        y: this._state.elOffset.top + (w / 2) * this._state.angle.sin + (h / 2) * this._state.angle.cos
      };
      this._state.elCenter = {
        x: this._state.elOffset.left + w / 2,
        y: this._state.elOffset.top + h / 2
      };
      if (this._state.card != null) {
        this._state.coef = this.coefs[this._state.card];
        this._state.minMouse = minMouse = {
          x: (w - this.sizeBounds.wMin) * this._state.coef[0],
          y: (h - this.sizeBounds.hMin) * this._state.coef[1]
        };
      }
      return this.getBox();
    };
    _calculateMove = function(event) {
      var bounds, box, state, vector;
      state = event.data;
      bounds = this._state.positionBounds;
      vector = {
        x: event.pageX - this._state.origin.x,
        y: event.pageY - this._state.origin.y
      };
      box = {
        left: vector.x + this._state.elPosition.left,
        top: vector.y + this._state.elPosition.top
      };
      if (box.left < bounds.ox) {
        box.left = bounds.ox;
      } else if (box.left > bounds.x) {
        box.left = bounds.x;
      }
      if (box.top < bounds.oy) {
        box.top = bounds.oy;
      } else if (box.top > bounds.y) {
        box.top = bounds.y;
      }
      box.width = this._state.elDimension.width;
      box.height = this._state.elDimension.height;
      box.rotate = this._state.angle.deg;
      box.centerX = this._state.rotatedCenter.x - this._state.workspaceOffset.left + vector.x;
      box.centerY = this._state.rotatedCenter.y - this._state.workspaceOffset.top + vector.y;
      return box;
    };
    _calculateRotate = function(event) {
      var angle, box, cM, cN, mN, mouse, normV, normalized, originalM, sign, vector;
      mouse = {
        x: event.pageX,
        y: event.pageY
      };
      vector = {
        x: mouse.x - this._state.rotatedCenter.x,
        y: mouse.y - this._state.rotatedCenter.y
      };
      normV = Math.sqrt(vector.x * vector.x + vector.y * vector.y);
      normalized = {
        x: vector.x / normV || 0,
        y: vector.y / normV || 0
      };
      sign = sgn(vector.x);
      angle = {};
      angle.rad = (Math.asin(normalized.y) + Math.PI / 2) * sign;
      angle.deg = angle.rad * 360 / (2 * Math.PI);
      angle.cos = Math.cos(angle.rad);
      angle.sin = Math.sin(angle.rad);
      originalM = {
        x: this._state.rotatedCenter.x - this._state.elDimension.width / 2,
        y: this._state.rotatedCenter.y - this._state.elDimension.height / 2
      };
      cM = {
        x: this._state.elOffset.left - this._state.elCenter.x,
        y: this._state.elOffset.top - this._state.elCenter.y
      };
      cN = {
        x: cM.x * angle.cos - cM.y * angle.sin,
        y: cM.x * angle.sin + cM.y * angle.cos
      };
      mN = {
        x: cN.x - cM.x,
        y: cN.y - cM.y
      };
      box = {
        left: originalM.x + mN.x - this._state.workspaceOffset.left,
        top: originalM.y + mN.y - this._state.workspaceOffset.top,
        rotate: angle.deg,
        angle: angle,
        width: this._state.elDimension.width,
        height: this._state.elDimension.height
      };
      box.centerX = box.left + (box.width / 2) * angle.cos - (box.height / 2) * angle.sin;
      box.centerY = box.top + (box.width / 2) * angle.sin + (box.height / 2) * angle.cos;
      return box;
    };
    _calculateResize = function(event) {
      var bounds, box, coef, constrain, dim, maxY, mouseB0, mouseB1, projectionB0, projectionB1;
      coef = this._state.coef;
      mouseB0 = {
        x: event.pageX - this._state.origin.x,
        y: event.pageY - this._state.origin.y
      };
      mouseB1 = {
        x: mouseB0.x * this._state.angle.cos + mouseB0.y * this._state.angle.sin,
        y: -mouseB0.x * this._state.angle.sin + mouseB0.y * this._state.angle.cos
      };
      maxY = mouseB1.x * coef[2] < mouseB1.y * coef[3];
      if (this.preserveRatio) {
        if (maxY) {
          mouseB1.x = mouseB1.y * coef[3] * coef[2] * this.ratio;
        } else {
          mouseB1.y = mouseB1.x * coef[2] * coef[3] / this.ratio;
        }
      }
      dim = {
        w: coef[2] * mouseB1.x + this._state.elDimension.width,
        h: coef[3] * mouseB1.y + this._state.elDimension.height
      };
      bounds = this.sizeBounds;
      constrain = {
        x: 1,
        y: 1
      };
      if (dim.w < bounds.wMin) {
        dim.w = bounds.wMin;
        constrain.x = 0;
      } else if (dim.w > bounds.wMax) {
        dim.w = bounds.wMax;
        constrain.x = 0;
      }
      if (dim.h < bounds.hMin) {
        dim.h = bounds.hMin;
        constrain.y = 0;
      } else if (dim.h > bounds.hMax) {
        dim.h = bounds.hMax;
        constrain.y = 0;
      }
      projectionB1 = {
        x: (constrain.x ? mouseB1.x : this._state.minMouse.x) * coef[0],
        y: (constrain.y ? mouseB1.y : this._state.minMouse.y) * coef[1]
      };
      projectionB0 = {
        x: this._state.angle.cos * projectionB1.x - this._state.angle.sin * projectionB1.y,
        y: this._state.angle.sin * projectionB1.x + this._state.angle.cos * projectionB1.y
      };
      box = {
        rotate: this._state.angle.deg,
        width: dim.w,
        height: dim.h,
        left: projectionB0.x + this._state.elPosition.left,
        top: projectionB0.y + this._state.elPosition.top
      };
      box.centerX = box.left + (box.width / 2) * this._state.angle.cos - (box.height / 2) * this._state.angle.sin;
      box.centerY = box.top + (box.width / 2) * this._state.angle.sin + (box.height / 2) * this._state.angle.cos;
      return box;
    };
    _calculateCentralDrag = function(event) {
      var box, mouseB0, mouseB1;
      mouseB0 = {
        x: event.pageX - this._state.origin.x,
        y: event.pageY - this._state.origin.y
      };
      mouseB1 = {
        x: mouseB0.x * this._state.angle.cos + mouseB0.y * this._state.angle.sin,
        y: -mouseB0.x * this._state.angle.sin + mouseB0.y * this._state.angle.cos
      };
      box = this.getBox();
      box.mouseLocal = mouseB1;
      return box;
    };
    return function(proto) {
      proto._sniffState = _sniffState;
      proto._setState = _setState;
      proto._calculateMove = _calculateMove;
      proto._calculateRotate = _calculateRotate;
      proto._calculateResize = _calculateResize;
      return proto._calculateCentralDrag = _calculateCentralDrag;
    };
  })();

  this.transformName = null;

  d = document.createElement('div');

  _ref = ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    b = _ref[_i];
    if (d.style[b] != null) {
      this.transformName = b;
    }
  }

  d = null;

  Cards = 'n,s,e,w,nw,ne,se,sw'.split(',');

  ordCards = 's,sw,w,nw,n,ne,e,se'.split(',');

  animationFrame = new AnimationFrame;

  this.Zonard = (function(_super) {
    __extends(Zonard, _super);

    function Zonard() {
      this.getBox = __bind(this.getBox, this);
      this.endTransform = __bind(this.endTransform, this);
      this.updateTransform = __bind(this.updateTransform, this);
      this.debouncer = __bind(this.debouncer, this);
      this.releaseMouse = __bind(this.releaseMouse, this);
      _ref1 = Zonard.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Zonard.prototype.className = 'zonard';

    Zonard.prototype.initialize = function(options) {
      var angleDeg, angleRad;
      this.box = options.box;
      this.needCentralHandle = options.centralHandle;
      this.handlerContainer = new HandlerContainerView(options);
      this.displayContainer = new DisplayContainerView;
      this.visibility = true;
      this.$el.css({
        'transform-origin': 'left top'
      });
      this.workspace = options.workspace;
      this.$workspace = $(this.workspace);
      if (this.preserveRatio = options.preserveRatio || false) {
        this.setRatio(this.box.width / this.box.height);
        this.togglePreserveRatio(this.preserveRatio);
      }
      this._state = {};
      angleDeg = this.box.rotate;
      angleRad = angleDeg * (2 * Math.PI) / 360;
      this._state.angle = {
        rad: angleRad,
        deg: angleDeg,
        cos: Math.cos(angleRad),
        sin: Math.sin(angleRad)
      };
      return this.assignCursor();
    };

    Zonard.prototype.assignCursor = function() {
      var dragbar, handle, i, _ref2, _ref3, _results;
      _ref2 = this.handlerContainer.handles;
      for (i in _ref2) {
        handle = _ref2[i];
        handle.assignCursor(this._state.angle.rad);
      }
      _ref3 = this.handlerContainer.dragbars;
      _results = [];
      for (i in _ref3) {
        dragbar = _ref3[i];
        _results.push(dragbar.assignCursor(this._state.angle.rad));
      }
      return _results;
    };

    Zonard.prototype.setRatio = function(ratio) {
      this.ratio = ratio;
      this.sizeBounds.hMin = this.sizeBounds.wMin / this.ratio;
      return this.sizeBounds.hMax = this.sizeBounds.wMax / this.ratio;
    };

    Zonard.prototype.togglePreserveRatio = function(condition) {
      return this.$el.toggleClass('preserve-ratio', condition);
    };

    Zonard.prototype.listenFocus = function() {
      var _this = this;
      return this.listenToOnce(this.handlerContainer.tracker, 'focus', function() {
        return _this.trigger('focus');
      });
    };

    Zonard.prototype.toggle = function(visibility) {
      this.$el.toggleClass("zonard-hidden", !visibility);
      return this;
    };

    Zonard.prototype.listenToDragStart = function() {
      var dragbar, handle, _j, _k, _len1, _len2, _ref2, _ref3,
        _this = this;
      _ref2 = this.handlerContainer.handles;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        handle = _ref2[_j];
        this.listenTo(handle, 'drag:start', function(data) {
          _this.startTransform(data, 'start:resize');
          _this.setTransform({
            fn: function() {
              var box;
              box = _this._calculateResize(_this._latestEvent);
              _this.setBox(box);
              return _this.trigger('change:resize', box);
            },
            end: function() {
              _this.releaseMouse();
              _this.box = _this._calculateResize(_this._latestEvent);
              _this.setBox(_this.box);
              return _this.trigger('end:resize', _this._setState());
            }
          });
          return _this.listenMouse();
        });
      }
      _ref3 = this.handlerContainer.dragbars;
      for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
        dragbar = _ref3[_k];
        this.listenTo(dragbar, 'drag:start', function(data) {
          _this.startTransform(data, 'start:resize');
          _this.setTransform({
            fn: function() {
              var box;
              box = _this._calculateResize(_this._latestEvent);
              _this.setBox(box);
              return _this.trigger('change:resize', box);
            },
            end: function() {
              _this.releaseMouse();
              _this.box = _this._calculateResize(_this._latestEvent);
              _this.setBox(_this.box);
              return _this.trigger('end:resize', _this._setState());
            }
          });
          return _this.listenMouse();
        });
      }
      this.listenTo(this.handlerContainer.tracker, 'drag:start', function(data) {
        _this.startTransform(data, 'start:move');
        _this.setTransform({
          fn: function() {
            var box;
            box = _this._calculateMove(_this._latestEvent);
            _this.setBox(box);
            return _this.trigger('change:move', box);
          },
          end: function() {
            _this.releaseMouse();
            _this.box = _this._calculateMove(_this._latestEvent);
            _this.setBox(_this.box);
            return _this.trigger('end:move', _this._setState());
          }
        });
        return _this.listenMouse();
      });
      this.listenTo(this.handlerContainer.rotateHandle, 'drag:start', function(data) {
        _this.startTransform(data, 'start:rotate');
        _this.setTransform({
          fn: function() {
            var box;
            box = _this._calculateRotate(_this._latestEvent);
            _this.setBox(box);
            return _this.trigger('change:rotate', box);
          },
          end: function() {
            _this.box = _this._calculateRotate(_this._latestEvent);
            _this.setBox(_this.box);
            _this.releaseMouse();
            _this.trigger('end:rotate', _this._setState());
            return _this.assignCursor();
          }
        });
        return _this.listenMouse();
      });
      if (this.needCentralHandle) {
        this.listenTo(this.handlerContainer.centralHandle, 'drag:start', function(data) {
          _this.startTransform(data, 'start:centralDrag');
          _this.setTransform({
            fn: function() {
              var box;
              box = _this._calculateCentralDrag(_this._latestEvent);
              return _this.trigger('info:centralDrag', box);
            },
            end: function() {
              _this.releaseMouse();
              return _this.trigger('end:centralDrag', _this._calculateCentralDrag(_this._latestEvent));
            }
          });
          return _this.listenMouse();
        });
      }
      return this;
    };

    Zonard.prototype.listenMouse = function() {
      return $('body').on('mousemove', this.debouncer).on('mouseup', this.endTransform).on('mouseleave', this.endTransform);
    };

    Zonard.prototype.releaseMouse = function() {
      return $('body').off('mousemove', this.debouncer).off('mouseup', this.endTransform).off('mouseleave', this.endTransform);
    };

    Zonard.prototype.setTransform = function(_transform) {
      this._transform = _transform;
    };

    Zonard.prototype.startTransform = function(data, eventName) {
      this.trigger(eventName);
      this._setState(data);
      this._rafIndex = null;
      return this.timeRef = Date.now();
    };

    Zonard.prototype.debouncer = function(_latestEvent) {
      this._latestEvent = _latestEvent;
      if (!this._rafIndex) {
        return this.updateTransform();
      } else {

      }
    };

    Zonard.prototype.updateTransform = function() {
      var _this = this;
      this.timeRef = Date.now();
      return this._rafIndex = animationFrame.request(function() {
        _this._transform.fn();
        return _this._rafIndex = null;
      });
    };

    Zonard.prototype.endTransform = function(_latestEvent) {
      this._latestEvent = _latestEvent;
      animationFrame.cancel(this._rafIndex);
      this._transform.end(this._latestEvent);
      return this._rafIndex = this._latestEvent = null;
    };

    Zonard.prototype.setBox = function(box) {
      if (box == null) {
        box = this.getBox();
      }
      box.transform = "rotate(" + box.rotate + "deg)";
      return this.$el.css(box);
    };

    Zonard.prototype.getBox = function() {
      return {
        left: this._state.elPosition.left,
        top: this._state.elPosition.top,
        width: this._state.elDimension.width,
        height: this._state.elDimension.height,
        rotate: this._state.angle.deg,
        centerX: this._state.rotatedCenter.x - this._state.workspaceOffset.left,
        centerY: this._state.rotatedCenter.y - this._state.workspaceOffset.top
      };
    };

    Zonard.prototype.coefs = {
      n: [0, 1, 0, -1],
      s: [0, 0, 0, 1],
      e: [0, 0, 1, 0],
      w: [1, 0, -1, 0],
      nw: [1, 1, -1, -1],
      ne: [0, 1, 1, -1],
      se: [0, 0, 1, 1],
      sw: [1, 0, -1, 1]
    };

    Zonard.prototype.sizeBounds = {
      wMin: 80,
      wMax: Infinity,
      hMin: 80,
      hMax: Infinity
    };

    Zonard.prototype.render = function() {
      this.$el.append(this.displayContainer.render().el, this.handlerContainer.render().el);
      this.setBox(_.pick(this.box, ['left', 'top', 'width', 'height', 'rotate']));
      return this;
    };

    Zonard.prototype.remove = function() {
      this.handlerContainer.remove();
      this.displayContainer.remove();
      if (this._transform != null) {
        this.releaseMouse();
      }
      return Zonard.__super__.remove.call(this);
    };

    return Zonard;

  })(Backbone.View);

  calculators(Zonard.prototype);

  classPrefix = 'zonard-';

  DisplayContainerView = (function(_super) {
    __extends(DisplayContainerView, _super);

    function DisplayContainerView() {
      _ref2 = DisplayContainerView.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    DisplayContainerView.prototype.className = function() {
      return "" + classPrefix + "displayContainer";
    };

    DisplayContainerView.prototype.initialize = function() {
      var card, i;
      this.borders = (function() {
        var _j, _len1, _ref3, _results;
        _ref3 = Cards.slice(0, 4);
        _results = [];
        for (i = _j = 0, _len1 = _ref3.length; _j < _len1; i = ++_j) {
          card = _ref3[i];
          _results.push(new BorderView({
            card: card
          }));
        }
        return _results;
      })();
      return this.visibility = true;
    };

    DisplayContainerView.prototype.render = function() {
      var border, _j, _len1, _ref3;
      _ref3 = this.borders;
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        border = _ref3[_j];
        this.$el.append(border.render().el);
      }
      return this;
    };

    DisplayContainerView.prototype.remove = function() {
      var border, _j, _len1, _ref3;
      _ref3 = this.borders;
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        border = _ref3[_j];
        border.remove();
      }
      DisplayContainerView.__super__.remove.call(this);
      return this;
    };

    return DisplayContainerView;

  })(Backbone.View);

  ContentView = (function(_super) {
    __extends(ContentView, _super);

    function ContentView() {
      _ref3 = ContentView.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    ContentView.prototype.className = function() {
      return "" + classPrefix + "content";
    };

    return ContentView;

  })(Backbone.View);

  BorderView = (function(_super) {
    __extends(BorderView, _super);

    function BorderView(options) {
      this.card = options.card;
      BorderView.__super__.constructor.call(this, options);
    }

    BorderView.prototype.className = function() {
      return "" + classPrefix + "border ord-" + this.card;
    };

    return BorderView;

  })(Backbone.View);

  HandlerContainerView = (function(_super) {
    __extends(HandlerContainerView, _super);

    function HandlerContainerView() {
      _ref4 = HandlerContainerView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    HandlerContainerView.prototype.className = function() {
      return "" + classPrefix + "handlerContainer";
    };

    HandlerContainerView.prototype.initialize = function(options) {
      var card, i;
      if (options == null) {
        options = {};
      }
      this.dragbars = (function() {
        var _j, _len1, _ref5, _results;
        _ref5 = Cards.slice(0, 4);
        _results = [];
        for (i = _j = 0, _len1 = _ref5.length; _j < _len1; i = ++_j) {
          card = _ref5[i];
          _results.push(new DragbarView({
            card: card
          }));
        }
        return _results;
      })();
      this.handles = (function() {
        var _j, _len1, _results;
        _results = [];
        for (i = _j = 0, _len1 = Cards.length; _j < _len1; i = ++_j) {
          card = Cards[i];
          _results.push(new HandleView({
            card: card
          }));
        }
        return _results;
      })();
      this.rotateHandle = new RotateHandleView;
      this.tracker = new TrackerView;
      if (options.centralHandle) {
        return this.centralHandle = new CentralHandle;
      }
    };

    HandlerContainerView.prototype.render = function() {
      var dragbar, handle;
      this.$el.append(this.tracker.render().el, (function() {
        var _j, _len1, _ref5, _results;
        _ref5 = this.dragbars;
        _results = [];
        for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
          dragbar = _ref5[_j];
          _results.push(dragbar.render().el);
        }
        return _results;
      }).call(this), (function() {
        var _j, _len1, _ref5, _results;
        _ref5 = this.handles;
        _results = [];
        for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
          handle = _ref5[_j];
          _results.push(handle.render().el);
        }
        return _results;
      }).call(this), this.rotateHandle.render().el, this.centralHandle != null ? this.centralHandle.render().el : void 0);
      return this;
    };

    HandlerContainerView.prototype.remove = function() {
      var bar, handle, _j, _k, _len1, _len2, _ref5, _ref6, _ref7, _ref8, _ref9;
      _ref5 = this.dragbars;
      for (_j = 0, _len1 = _ref5.length; _j < _len1; _j++) {
        bar = _ref5[_j];
        bar.remove();
      }
      _ref6 = this.handles;
      for (_k = 0, _len2 = _ref6.length; _k < _len2; _k++) {
        handle = _ref6[_k];
        handle.remove();
      }
      if ((_ref7 = this.rotateHandle) != null) {
        _ref7.remove();
      }
      if ((_ref8 = this.tracker) != null) {
        _ref8.remove();
      }
      if ((_ref9 = this.centralHandle) != null) {
        _ref9.remove();
      }
      return HandlerContainerView.__super__.remove.call(this);
    };

    return HandlerContainerView;

  })(Backbone.View);

  SelectionView = (function(_super) {
    __extends(SelectionView, _super);

    function SelectionView() {
      this.assignCursor = __bind(this.assignCursor, this);
      _ref5 = SelectionView.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    SelectionView.prototype.events = {
      mousedown: 'start'
    };

    SelectionView.prototype.initialize = function(options) {
      this.card = options.card;
      this.indexCard = _.indexOf(ordCards, this.card);
      return this.$el.css({
        cursor: this.card + '-resize'
      });
    };

    SelectionView.prototype.start = function(event) {
      var origin;
      if (event.which !== 1) {
        return;
      }
      event.preventDefault();
      origin = {
        x: event.pageX,
        y: event.pageY
      };
      return this.trigger('drag:start', {
        origin: origin,
        card: this.card
      });
    };

    SelectionView.prototype.assignCursor = function(angle) {
      var currentCard, permut;
      permut = (this.indexCard + Math.floor((angle + Math.PI / 8) / (Math.PI / 4))) % 8;
      if (permut < 0) {
        permut += 8;
      }
      currentCard = ordCards[permut];
      return this.el.style.cursor = "" + currentCard + "-resize";
    };

    return SelectionView;

  })(Backbone.View);

  DragbarView = (function(_super) {
    __extends(DragbarView, _super);

    function DragbarView(options) {
      this.card = options.card;
      DragbarView.__super__.constructor.call(this, options);
    }

    DragbarView.prototype.className = function() {
      return "" + classPrefix + "dragbar ord-" + this.card;
    };

    return DragbarView;

  })(SelectionView);

  HandleView = (function(_super) {
    __extends(HandleView, _super);

    function HandleView(options) {
      this.card = options.card;
      HandleView.__super__.constructor.call(this, options);
    }

    HandleView.prototype.className = function() {
      return "" + classPrefix + "handle ord-" + this.card;
    };

    return HandleView;

  })(SelectionView);

  RotateHandleView = (function(_super) {
    __extends(RotateHandleView, _super);

    function RotateHandleView() {
      _ref6 = RotateHandleView.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    RotateHandleView.prototype.className = function() {
      return "" + classPrefix + "handleRotation";
    };

    RotateHandleView.prototype.events = {
      mousedown: 'start'
    };

    RotateHandleView.prototype.start = function(event) {
      if (event.which !== 1) {
        return;
      }
      event.preventDefault();
      return this.trigger('drag:start');
    };

    return RotateHandleView;

  })(Backbone.View);

  CentralHandle = (function(_super) {
    __extends(CentralHandle, _super);

    function CentralHandle() {
      _ref7 = CentralHandle.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    CentralHandle.prototype.className = function() {
      return "" + classPrefix + "handle central";
    };

    CentralHandle.prototype.events = {
      mousedown: 'start'
    };

    CentralHandle.prototype.start = function(event) {
      var origin;
      if (event.which !== 1) {
        return;
      }
      event.preventDefault();
      origin = {
        x: event.pageX,
        y: event.pageY
      };
      return this.trigger('drag:start', {
        origin: origin
      });
    };

    return CentralHandle;

  })(Backbone.View);

  TrackerView = (function(_super) {
    __extends(TrackerView, _super);

    function TrackerView() {
      _ref8 = TrackerView.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    TrackerView.prototype.className = function() {
      return "" + classPrefix + "tracker";
    };

    TrackerView.prototype.events = {
      mousedown: 'start',
      click: 'focus'
    };

    TrackerView.prototype.focus = function(event) {
      return this.trigger('focus');
    };

    TrackerView.prototype.start = function(event) {
      var origin;
      if (event.which !== 1) {
        return;
      }
      event.preventDefault();
      origin = {
        x: event.pageX,
        y: event.pageY
      };
      return this.trigger('drag:start', {
        origin: origin
      });
    };

    return TrackerView;

  })(Backbone.View);

}).call(this);
