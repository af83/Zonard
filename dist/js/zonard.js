(function() {
  var BorderView, Cards, CentralHandle, ContentView, DisplayContainerView, DragbarView, HandleView, HandlerContainerView, RotateHandleView, SelectionView, TrackerView, V, b, calculators, classPrefix, d, ordCards, _i, _len, _ref, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  calculators = (function() {
    var _calculateCentralDrag, _calculateMove, _calculateResize, _calculateRotate, _setState;

    _setState = function(data) {
      var angleDeg, angleRad, box, cos, h, matrix, minMouse, sign, sin, tab, w;

      if (data == null) {
        data = {};
      }
      this._state = $.extend(true, this._state, data);
      matrix = this.$el.css('transform');
      tab = matrix.substr(7, matrix.length - 8).split(', ');
      cos = parseFloat(tab[0]);
      sin = parseFloat(tab[1]);
      sign = sin / Math.abs(sin) || 1;
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
        minMouse = {
          x: (w - this.sizeBounds.wMin) * this._state.coef[0],
          y: (h - this.sizeBounds.hMin) * this._state.coef[1]
        };
        this._state.minResizePosition = {
          left: this._state.angle.cos * minMouse.x - this._state.angle.sin * minMouse.y + this._state.elPosition.left,
          top: this._state.angle.sin * minMouse.x + this._state.angle.cos * minMouse.y + this._state.elPosition.top
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
      var angle, box, cM, cN, mN, mouse, normalized, originalM, sign, vector;

      mouse = {
        x: event.pageX,
        y: event.pageY
      };
      vector = V.vector(mouse, this._state.rotatedCenter);
      normalized = V.normalized(vector);
      sign = V.signedDir(vector, 'x');
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
      var absB1, bounds, box, coef, constrain, dim, maxY, mouseB0, mouseB1, projectionB0, projectionB1, signsB1;

      coef = this._state.coef;
      mouseB0 = {
        x: event.pageX - this._state.origin.x,
        y: event.pageY - this._state.origin.y
      };
      mouseB1 = {
        x: mouseB0.x * this._state.angle.cos + mouseB0.y * this._state.angle.sin,
        y: -mouseB0.x * this._state.angle.sin + mouseB0.y * this._state.angle.cos
      };
      signsB1 = {
        x: mouseB1.x / Math.abs(mouseB1.x) || 1,
        y: mouseB1.y / Math.abs(mouseB1.y) || 1
      };
      absB1 = {
        x: Math.abs(mouseB1.x),
        y: Math.abs(mouseB1.y)
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
        x: mouseB1.x * coef[0],
        y: mouseB1.y * coef[1]
      };
      projectionB0 = {
        x: this._state.angle.cos * projectionB1.x - this._state.angle.sin * projectionB1.y,
        y: this._state.angle.sin * projectionB1.x + this._state.angle.cos * projectionB1.y
      };
      box = {
        rotate: this._state.angle.deg
      };
      box.width = dim.w;
      if (constrain.x) {
        box.left = projectionB0.x + this._state.elPosition.left;
      } else {
        box.left = this._state.minResizePosition.left;
      }
      box.height = dim.h;
      if (constrain.y) {
        box.top = projectionB0.y + this._state.elPosition.top;
      } else {
        box.top = this._state.minResizePosition.top;
      }
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

  V = {
    vector: function(direction, center) {
      return {
        x: direction.x - center.x,
        y: direction.y - center.y
      };
    },
    norm: function(vector) {
      return Math.sqrt(vector.x * vector.x + vector.y * vector.y);
    },
    normalized: function(vector) {
      var norm;

      norm = this.norm(vector);
      return {
        x: vector.x / norm,
        y: vector.y / norm
      };
    },
    signedDir: function(vector, comp) {
      return vector[comp] / Math.abs(vector[comp]);
    }
  };

  Cards = 'n,s,e,w,nw,ne,se,sw'.split(',');

  ordCards = 's,sw,w,nw,n,ne,e,se'.split(',');

  this.Zonard = (function(_super) {
    __extends(Zonard, _super);

    function Zonard() {
      this.getBox = __bind(this.getBox, this);
      this.releaseMouse = __bind(this.releaseMouse, this);      _ref1 = Zonard.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Zonard.prototype.className = 'zonard';

    Zonard.prototype.initialize = function() {
      var angleDeg, angleRad;

      this.handlerContainer = new HandlerContainerView(this.options);
      this.displayContainer = new DisplayContainerView;
      this.visibility = true;
      this.$el.css({
        'transform-origin': 'left top'
      });
      this.workspace = this.options.workspace;
      this.$workspace = $(this.workspace);
      if (this.preserveRatio = this.options.preserveRatio || false) {
        this.setRatio(this.options.box.width / this.options.box.height);
        this.togglePreserveRatio(this.preserveRatio);
      }
      this._state = {};
      angleDeg = this.options.box.rotate;
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
      this.displayContainer.toggle(visibility);
      this.handlerContainer.toggle(visibility);
      return this;
    };

    Zonard.prototype.listenToDragStart = function() {
      var dragbar, handle, _j, _k, _len1, _len2, _ref2, _ref3,
        _this = this;

      _ref2 = this.handlerContainer.handles;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        handle = _ref2[_j];
        this.listenTo(handle, 'drag:start', function(data) {
          _this.trigger('start:resize');
          _this._setState(data);
          _this.setTransform({
            fn: function(event) {
              var box;

              box = _this._calculateResize(event);
              _this.setBox(box);
              return _this.trigger('change:resize', box);
            },
            end: function() {
              _this.releaseMouse();
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
          _this.trigger('start:resize');
          _this._setState(data);
          _this.setTransform({
            fn: function(event) {
              var box;

              box = _this._calculateResize(event);
              _this.setBox(box);
              return _this.trigger('change:resize', box);
            },
            end: function() {
              _this.releaseMouse();
              return _this.trigger('end:resize', _this._setState());
            }
          });
          return _this.listenMouse();
        });
      }
      this.listenTo(this.handlerContainer.tracker, 'drag:start', function(data) {
        _this.trigger('start:move');
        _this._setState(data);
        _this.setTransform({
          fn: function(event) {
            var box;

            box = _this._calculateMove(event);
            _this.setBox(box);
            return _this.trigger('change:move', box);
          },
          end: function() {
            _this.releaseMouse();
            return _this.trigger('end:move', _this._setState());
          }
        });
        return _this.listenMouse();
      });
      this.listenTo(this.handlerContainer.rotateHandle, 'drag:start', function(data) {
        _this.trigger('start:rotate');
        _this._setState(data);
        _this.setTransform({
          fn: function(event) {
            var box;

            box = _this._calculateRotate(event);
            _this.setBox(box);
            return _this.trigger('change:rotate', box);
          },
          end: function(event) {
            var box;

            box = _this._calculateRotate(event);
            _this.setBox(box);
            _this.releaseMouse();
            _this.trigger('end:rotate', _this._setState());
            return _this.assignCursor();
          }
        });
        return _this.listenMouse();
      });
      if (this.options.centralHandle) {
        this.listenTo(this.handlerContainer.centralHandle, 'drag:start', function(data) {
          _this.trigger('start:centralDrag');
          _this._setState(data);
          _this.setTransform({
            fn: function(event) {
              var box;

              box = _this._calculateCentralDrag(event);
              return _this.trigger('info:centralDrag', box);
            },
            end: function(event) {
              _this.releaseMouse();
              return _this.trigger('end:centralDrag', _this._calculateCentralDrag(event));
            }
          });
          return _this.listenMouse();
        });
      }
      return this;
    };

    Zonard.prototype.listenMouse = function() {
      $('body').on('mousemove', this._transform.fn);
      $('body').on('mouseup', this._transform.end);
      return $('body').on('mouseleave', this._transform.end);
    };

    Zonard.prototype.releaseMouse = function() {
      return $('body').off('mousemove', this._transform.fn).off('mouseup', this._transform.end).off('mouseleave', this._transform.end);
    };

    Zonard.prototype.setTransform = function(_transform) {
      this._transform = _transform;
    };

    Zonard.prototype.setBox = function(box) {
      if (box == null) {
        box = this.getBox();
      }
      this.$el.css({
        transform: "rotate(" + box.rotate + "deg)"
      });
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
      this.setBox(_.pick(this.options.box, ['left', 'top', 'width', 'height', 'rotate']));
      return this;
    };

    Zonard.prototype.remove = function() {
      this.handlerContainer.remove();
      this.displayContainer.remove();
      this.releaseMouse();
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

      this.toggle(this.visibility);
      _ref3 = this.borders;
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        border = _ref3[_j];
        this.$el.append(border.render().el);
      }
      return this;
    };

    DisplayContainerView.prototype.toggle = function(visibility) {
      this.visibility = visibility;
      this.$el.toggle(visibility);
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

    function BorderView() {
      _ref4 = BorderView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    BorderView.prototype.className = function() {
      return "" + classPrefix + "border ord-" + this.options.card;
    };

    return BorderView;

  })(Backbone.View);

  HandlerContainerView = (function(_super) {
    __extends(HandlerContainerView, _super);

    function HandlerContainerView() {
      _ref5 = HandlerContainerView.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    HandlerContainerView.prototype.className = function() {
      return "" + classPrefix + "handlerContainer";
    };

    HandlerContainerView.prototype.initialize = function() {
      var card, i;

      this.dragbars = (function() {
        var _j, _len1, _ref6, _results;

        _ref6 = Cards.slice(0, 4);
        _results = [];
        for (i = _j = 0, _len1 = _ref6.length; _j < _len1; i = ++_j) {
          card = _ref6[i];
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
      if ((this.options.centralHandle != null) && this.options.centralHandle) {
        return this.centralHandle = new CentralHandle;
      }
    };

    HandlerContainerView.prototype.render = function() {
      var dragbar, handle;

      this.$el.append(this.tracker.render().el, (function() {
        var _j, _len1, _ref6, _results;

        _ref6 = this.dragbars;
        _results = [];
        for (_j = 0, _len1 = _ref6.length; _j < _len1; _j++) {
          dragbar = _ref6[_j];
          _results.push(dragbar.render().el);
        }
        return _results;
      }).call(this), (function() {
        var _j, _len1, _ref6, _results;

        _ref6 = this.handles;
        _results = [];
        for (_j = 0, _len1 = _ref6.length; _j < _len1; _j++) {
          handle = _ref6[_j];
          _results.push(handle.render().el);
        }
        return _results;
      }).call(this), this.rotateHandle.render().el, this.options.centralHandle ? this.centralHandle.render().el : void 0);
      return this;
    };

    HandlerContainerView.prototype.toggle = function(visibility) {
      var dragbar, handle, _j, _k, _len1, _len2, _ref6, _ref7;

      _ref6 = this.dragbars;
      for (_j = 0, _len1 = _ref6.length; _j < _len1; _j++) {
        dragbar = _ref6[_j];
        dragbar.toggle(visibility);
      }
      _ref7 = this.handles;
      for (_k = 0, _len2 = _ref7.length; _k < _len2; _k++) {
        handle = _ref7[_k];
        handle.toggle(visibility);
      }
      this.rotateHandle.toggle(visibility);
      if (this.options.centralHandle) {
        this.centralHandle.toggle(visibility);
      }
      return this;
    };

    HandlerContainerView.prototype.remove = function() {
      var _ref10, _ref6, _ref7, _ref8, _ref9;

      if ((_ref6 = this.dragbars) != null) {
        _ref6.remove();
      }
      if ((_ref7 = this.handles) != null) {
        _ref7.remove();
      }
      if ((_ref8 = this.rotateHandle) != null) {
        _ref8.remove();
      }
      if ((_ref9 = this.tracker) != null) {
        _ref9.remove();
      }
      if ((_ref10 = this.centralHandle) != null) {
        _ref10.remove();
      }
      return HandlerContainerView.__super__.remove.call(this);
    };

    return HandlerContainerView;

  })(Backbone.View);

  SelectionView = (function(_super) {
    __extends(SelectionView, _super);

    function SelectionView() {
      this.assignCursor = __bind(this.assignCursor, this);      _ref6 = SelectionView.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    SelectionView.prototype.events = {
      mousedown: 'start'
    };

    SelectionView.prototype.initialize = function() {
      this.card = this.options.card;
      this.indexCard = _.indexOf(ordCards, this.card);
      return this.$el.css({
        cursor: this.card + '-resize'
      });
    };

    SelectionView.prototype.start = function(event) {
      var origin;

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

    SelectionView.prototype.toggle = function(visibility) {
      this.$el.toggle(visibility);
      return this;
    };

    return SelectionView;

  })(Backbone.View);

  DragbarView = (function(_super) {
    __extends(DragbarView, _super);

    function DragbarView() {
      _ref7 = DragbarView.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    DragbarView.prototype.className = function() {
      return "" + classPrefix + "dragbar ord-" + this.options.card;
    };

    return DragbarView;

  })(SelectionView);

  HandleView = (function(_super) {
    __extends(HandleView, _super);

    function HandleView() {
      _ref8 = HandleView.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    HandleView.prototype.className = function() {
      return "" + classPrefix + "handle ord-" + this.options.card;
    };

    return HandleView;

  })(SelectionView);

  RotateHandleView = (function(_super) {
    __extends(RotateHandleView, _super);

    function RotateHandleView() {
      _ref9 = RotateHandleView.__super__.constructor.apply(this, arguments);
      return _ref9;
    }

    RotateHandleView.prototype.className = function() {
      return "" + classPrefix + "handleRotation";
    };

    RotateHandleView.prototype.events = {
      mousedown: 'start'
    };

    RotateHandleView.prototype.start = function(event) {
      event.preventDefault();
      return this.trigger('drag:start');
    };

    RotateHandleView.prototype.toggle = function(visibility) {
      this.$el.toggle(visibility);
      return this;
    };

    return RotateHandleView;

  })(Backbone.View);

  CentralHandle = (function(_super) {
    __extends(CentralHandle, _super);

    function CentralHandle() {
      _ref10 = CentralHandle.__super__.constructor.apply(this, arguments);
      return _ref10;
    }

    CentralHandle.prototype.className = function() {
      return "" + classPrefix + "handle central";
    };

    CentralHandle.prototype.events = {
      mousedown: 'start'
    };

    CentralHandle.prototype.start = function(event) {
      var origin;

      event.preventDefault();
      origin = {
        x: event.pageX,
        y: event.pageY
      };
      return this.trigger('drag:start', {
        origin: origin
      });
    };

    CentralHandle.prototype.toggle = function(visibility) {
      this.$el.toggle(visibility);
      return this;
    };

    return CentralHandle;

  })(Backbone.View);

  TrackerView = (function(_super) {
    __extends(TrackerView, _super);

    function TrackerView() {
      _ref11 = TrackerView.__super__.constructor.apply(this, arguments);
      return _ref11;
    }

    TrackerView.prototype.className = function() {
      return "" + classPrefix + "tracker";
    };

    TrackerView.prototype.events = {
      mousedown: 'start',
      click: 'focus'
    };

    TrackerView.prototype.focus = function(event) {
      event.stopPropagation();
      return this.trigger('focus');
    };

    TrackerView.prototype.start = function(event) {
      var origin;

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
