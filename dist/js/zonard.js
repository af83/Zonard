(function() {
  var BorderView, Cards, CentralHandle, ContentView, DisplayContainerView, DragbarView, HandleView, HandlerContainerView, RotateContainerView, RotateHandleView, SelectionView, TrackerView, V, b, d, ordCards, _i, _len, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

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
      this._endCentralDrag = __bind(this._endCentralDrag, this);
      this._calculateCentralDrag = __bind(this._calculateCentralDrag, this);
      this._endResize = __bind(this._endResize, this);
      this._calculateResize = __bind(this._calculateResize, this);
      this._endRotate = __bind(this._endRotate, this);
      this._calculateRotate = __bind(this._calculateRotate, this);
      this._endMove = __bind(this._endMove, this);
      this._calculateMove = __bind(this._calculateMove, this);
      this.getBox = __bind(this.getBox, this);
      this._setState = __bind(this._setState, this);
      this.releaseMouse = __bind(this.releaseMouse, this);      _ref1 = Zonard.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Zonard.prototype.className = 'zonard';

    Zonard.prototype.initialize = function() {
      var angleDeg, angleRad, dragbar, handle, i, _ref2, _ref3, _results;

      this.rotationContainer = new RotateContainerView(this.options);
      this.rotationContainer.$el.css({
        'transform-origin': 'left top'
      });
      this.workspace = this.options.workspace;
      this.$workspace = $(this.workspace);
      this._state = {};
      angleDeg = this.model.get('rotate');
      angleRad = angleDeg * (2 * Math.PI) / 360;
      this._state.angle = {
        rad: angleRad,
        deg: angleDeg,
        cos: Math.cos(angleRad),
        sin: Math.sin(angleRad)
      };
      _ref2 = this.rotationContainer.handlerContainer.handles;
      for (i in _ref2) {
        handle = _ref2[i];
        handle.assignCursor(this._state.angle.rad);
      }
      _ref3 = this.rotationContainer.handlerContainer.dragbars;
      _results = [];
      for (i in _ref3) {
        dragbar = _ref3[i];
        _results.push(dragbar.assignCursor(this._state.angle.rad));
      }
      return _results;
    };

    Zonard.prototype.listenFocus = function() {
      var _this = this;

      return this.listenToOnce(this.rotationContainer.handlerContainer.tracker, 'focus', function() {
        return _this.trigger('focus');
      });
    };

    Zonard.prototype.toggle = function(visibility) {
      this.rotationContainer.displayContainer.toggle(visibility);
      this.rotationContainer.handlerContainer.toggle(visibility);
      return this;
    };

    Zonard.prototype.listenToDragStart = function() {
      var dragbar, handle, _j, _k, _len1, _len2, _ref2, _ref3,
        _this = this;

      _ref2 = this.rotationContainer.handlerContainer.handles;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        handle = _ref2[_j];
        this.listenTo(handle, 'drag:start', function(data) {
          _this.trigger('start:resize');
          _this._setState(data);
          _this.setTransform({
            fn: _this._calculateResize,
            end: _this._endResize
          });
          return _this.listenMouse();
        });
      }
      _ref3 = this.rotationContainer.handlerContainer.dragbars;
      for (_k = 0, _len2 = _ref3.length; _k < _len2; _k++) {
        dragbar = _ref3[_k];
        this.listenTo(dragbar, 'drag:start', function(data) {
          _this.trigger('start:resize');
          _this._setState(data);
          _this.setTransform({
            fn: _this._calculateResize,
            end: _this._endResize
          });
          return _this.listenMouse();
        });
      }
      this.listenTo(this.rotationContainer.handlerContainer.tracker, 'drag:start', function(data) {
        _this.trigger('start:move');
        _this._setState(data);
        _this.setTransform({
          fn: _this._calculateMove,
          end: _this._endMove
        });
        return _this.listenMouse();
      });
      this.listenTo(this.rotationContainer.handlerContainer.rotateHandle, 'drag:start', function(data) {
        _this.trigger('start:rotate');
        _this._setState(data);
        _this.setTransform({
          fn: _this._calculateRotate,
          end: _this._endRotate
        });
        return _this.listenMouse();
      });
      if (this.options.centralHandle) {
        return this.listenTo(this.rotationContainer.handlerContainer.centralHandle, 'drag:start', function(data) {
          _this.trigger('start:centralDrag');
          _this._setState(data);
          _this.setTransform({
            fn: _this._calculateCentralDrag,
            end: _this._endCentralDrag
          });
          return _this.listenMouse();
        });
      }
    };

    Zonard.prototype.listenMouse = function() {
      this.$workspace.on('mousemove', this._transform.fn);
      this.$workspace.on('mouseup', this._transform.end);
      return this.$workspace.on('mouseleave', this._transform.end);
    };

    Zonard.prototype.releaseMouse = function() {
      return this.$workspace.off('mousemove', this._transform.fn).off('mouseup', this._transform.end).off('mouseleave', this._transform.end);
    };

    Zonard.prototype.setTransform = function(_transform) {
      this._transform = _transform;
    };

    Zonard.prototype.setBox = function(box) {
      this.rotationContainer.$el.css({
        transform: "rotate(" + box.rotate + "deg)"
      });
      return this.$el.css(box);
    };

    Zonard.prototype._setState = function(data) {
      var angleDeg, angleRad, box, cos, h, matrix, sign, sin, tab, w;

      if (data == null) {
        data = {};
      }
      this._state = $.extend(true, this._state, data);
      matrix = this.rotationContainer.$el.css('transform');
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
      box = this.rotationContainer.el.getBoundingClientRect();
      w = this.$el.width();
      h = this.$el.height();
      this._state.angle.cos = Math.cos(this._state.angle.rad);
      this._state.angle.sin = Math.sin(this._state.angle.rad);
      this._state.elPosition = this.$el.position();
      this._state.elOffset = this.$el.offset();
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
      this._state.workspaceOffset = {
        left: this._state.elPosition.left - this._state.elOffset.left,
        top: this._state.elPosition.top - this._state.elOffset.top
      };
      if (this._state.card != null) {
        this._state.coef = this.coefs[this._state.card];
      }
      this._state.sizeBounds = {
        wMin: 20,
        wMax: Infinity,
        hMin: 20,
        hMax: Infinity
      };
      return this.getBox();
    };

    Zonard.prototype.getBox = function() {
      return {
        left: this._state.elPosition.left,
        top: this._state.elPosition.top,
        width: this._state.elDimension.width,
        height: this._state.elDimension.height,
        rotate: this._state.angle.deg,
        centerX: this._state.rotatedCenter.x - this._state.workspaceOffset.x,
        centerY: this._state.rotatedCenter.y - this._state.workspaceOffset.y
      };
    };

    Zonard.prototype._calculateMove = function(event) {
      var bounds, box, vector;

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
      box.centerX = this._state.rotatedCenter.x - this._state.workspaceOffset.x + vector.x;
      box.centerY = this._state.rotatedCenter.y - this._state.workspaceOffset.y + vector.y;
      this.setBox(box);
      this.trigger('change:move', box);
      return this;
    };

    Zonard.prototype._endMove = function() {
      this.releaseMouse();
      return this.trigger('end:move', this._setState());
    };

    Zonard.prototype._calculateRotate = function(event) {
      var box, cM, cN, mN, mouse, normalized, originalM, sign, vector;

      mouse = {
        x: event.pageX,
        y: event.pageY
      };
      vector = V.vector(mouse, this._state.rotatedCenter);
      normalized = V.normalized(vector);
      sign = V.signedDir(vector, 'x');
      this._state.angle.rad = (Math.asin(normalized.y) + Math.PI / 2) * sign;
      this._state.angle.deg = this._state.angle.rad * 360 / (2 * Math.PI);
      this._state.angle.cos = Math.cos(this._state.angle.rad);
      this._state.angle.sin = Math.sin(this._state.angle.rad);
      originalM = {
        x: this._state.rotatedCenter.x - this._state.elDimension.width / 2,
        y: this._state.rotatedCenter.y - this._state.elDimension.height / 2
      };
      cM = {
        x: this._state.elOffset.left - this._state.elCenter.x,
        y: this._state.elOffset.top - this._state.elCenter.y
      };
      cN = {
        x: cM.x * this._state.angle.cos - cM.y * this._state.angle.sin,
        y: cM.x * this._state.angle.sin + cM.y * this._state.angle.cos
      };
      mN = {
        x: cN.x - cM.x,
        y: cN.y - cM.y
      };
      box = {
        left: originalM.x + mN.x + this._state.workspaceOffset.left,
        top: originalM.y + mN.y + this._state.workspaceOffset.top,
        rotate: this._state.angle.deg,
        width: this._state.elDimension.width,
        height: this._state.elDimension.height
      };
      box.centerX = box.left + (box.width / 2) * this._state.angle.cos - (box.height / 2) * this._state.angle.sin;
      box.centerY = box.top + (box.width / 2) * this._state.angle.sin + (box.height / 2) * this._state.angle.cos;
      this.setBox(box);
      return this.trigger('change:rotate', box);
    };

    Zonard.prototype._endRotate = function() {
      var dragbar, handle, i, _ref2, _ref3, _results;

      this.releaseMouse();
      this.trigger('end:rotate', this._setState());
      _ref2 = this.rotationContainer.handlerContainer.handles;
      for (i in _ref2) {
        handle = _ref2[i];
        handle.assignCursor(this._state.angle.rad);
      }
      _ref3 = this.rotationContainer.handlerContainer.dragbars;
      _results = [];
      for (i in _ref3) {
        dragbar = _ref3[i];
        _results.push(dragbar.assignCursor(this._state.angle.rad));
      }
      return _results;
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

    Zonard.prototype._calculateResize = function(event) {
      var bounds, box, coef, constrain, dim, mouseB0, mouseB1, projectionB0, projectionB1;

      coef = this._state.coef;
      mouseB0 = {
        x: event.pageX - this._state.origin.x,
        y: event.pageY - this._state.origin.y
      };
      mouseB1 = {
        x: mouseB0.x * this._state.angle.cos + mouseB0.y * this._state.angle.sin,
        y: -mouseB0.x * this._state.angle.sin + mouseB0.y * this._state.angle.cos
      };
      dim = {
        w: coef[2] * mouseB1.x + this._state.elDimension.width,
        h: coef[3] * mouseB1.y + this._state.elDimension.height
      };
      bounds = this._state.sizeBounds;
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
      if (constrain.x) {
        box.left = projectionB0.x + this._state.elPosition.left;
        box.width = dim.w;
      } else {
        box.left = this._state.elPosition.left;
        box.width = this._state.elDimension.width;
      }
      if (constrain.y) {
        box.top = projectionB0.y + this._state.elPosition.top;
        box.height = dim.h;
      } else {
        box.top = this._state.elPosition.top;
        box.height = this._state.elDimension.height;
      }
      box.centerX = box.left + (box.width / 2) * this._state.angle.cos - (box.height / 2) * this._state.angle.sin;
      box.centerY = box.top + (box.width / 2) * this._state.angle.sin + (box.height / 2) * this._state.angle.cos;
      this.setBox(box);
      return this.trigger('change:resize', box);
    };

    Zonard.prototype._endResize = function() {
      this.releaseMouse();
      return this.trigger('end:resize', this._setState());
    };

    Zonard.prototype._calculateCentralDrag = function(event) {
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
      return this.trigger('info:centralDrag', box);
    };

    Zonard.prototype._endCentralDrag = function() {
      this.releaseMouse();
      return this.trigger('end:centralDrag', this._setState());
    };

    Zonard.prototype.render = function() {
      var box, prop, props, _j, _len1;

      this.$el.append(this.rotationContainer.render().el);
      props = 'left top width height rotate'.split(' ');
      box = {};
      for (_j = 0, _len1 = props.length; _j < _len1; _j++) {
        prop = props[_j];
        box[prop] = this.model.get(prop);
      }
      this.setBox(box);
      return this;
    };

    return Zonard;

  })(Backbone.View);

  RotateContainerView = (function(_super) {
    __extends(RotateContainerView, _super);

    function RotateContainerView() {
      _ref2 = RotateContainerView.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    RotateContainerView.prototype.className = 'rotateContainer';

    RotateContainerView.prototype.initialize = function() {
      this.handlerContainer = new HandlerContainerView(this.options);
      this.displayContainer = new DisplayContainerView;
      return this.visibility = true;
    };

    RotateContainerView.prototype.render = function() {
      this.$el.append(this.displayContainer.render().el, this.handlerContainer.render().el);
      return this;
    };

    return RotateContainerView;

  })(Backbone.View);

  DisplayContainerView = (function(_super) {
    __extends(DisplayContainerView, _super);

    function DisplayContainerView() {
      _ref3 = DisplayContainerView.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    DisplayContainerView.prototype.className = 'displayContainer';

    DisplayContainerView.prototype.initialize = function() {
      var card, i;

      this.borders = (function() {
        var _j, _len1, _ref4, _results;

        _ref4 = Cards.slice(0, 4);
        _results = [];
        for (i = _j = 0, _len1 = _ref4.length; _j < _len1; i = ++_j) {
          card = _ref4[i];
          _results.push(new BorderView({
            card: card
          }));
        }
        return _results;
      })();
      return this.visibility = true;
    };

    DisplayContainerView.prototype.render = function() {
      var border, _j, _len1, _ref4;

      this.toggle(this.visibility);
      _ref4 = this.borders;
      for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++) {
        border = _ref4[_j];
        this.$el.append(border.render().el);
      }
      return this;
    };

    DisplayContainerView.prototype.toggle = function(visibility) {
      this.visibility = visibility;
      this.$el.toggle(visibility);
      return this;
    };

    return DisplayContainerView;

  })(Backbone.View);

  ContentView = (function(_super) {
    __extends(ContentView, _super);

    function ContentView() {
      _ref4 = ContentView.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    ContentView.prototype.className = 'content';

    return ContentView;

  })(Backbone.View);

  BorderView = (function(_super) {
    __extends(BorderView, _super);

    function BorderView() {
      _ref5 = BorderView.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    BorderView.prototype.className = function() {
      return "border ord-" + this.options.card;
    };

    return BorderView;

  })(Backbone.View);

  HandlerContainerView = (function(_super) {
    __extends(HandlerContainerView, _super);

    function HandlerContainerView() {
      _ref6 = HandlerContainerView.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    HandlerContainerView.prototype.className = 'handlerContainer';

    HandlerContainerView.prototype.initialize = function() {
      var card, i;

      this.dragbars = (function() {
        var _j, _len1, _ref7, _results;

        _ref7 = Cards.slice(0, 4);
        _results = [];
        for (i = _j = 0, _len1 = _ref7.length; _j < _len1; i = ++_j) {
          card = _ref7[i];
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
        var _j, _len1, _ref7, _results;

        _ref7 = this.dragbars;
        _results = [];
        for (_j = 0, _len1 = _ref7.length; _j < _len1; _j++) {
          dragbar = _ref7[_j];
          _results.push(dragbar.render().el);
        }
        return _results;
      }).call(this), (function() {
        var _j, _len1, _ref7, _results;

        _ref7 = this.handles;
        _results = [];
        for (_j = 0, _len1 = _ref7.length; _j < _len1; _j++) {
          handle = _ref7[_j];
          _results.push(handle.render().el);
        }
        return _results;
      }).call(this), this.rotateHandle.render().el, this.options.centralHandle ? this.centralHandle.render().el : void 0);
      return this;
    };

    HandlerContainerView.prototype.toggle = function(visibility) {
      var dragbar, handle, _j, _k, _len1, _len2, _ref7, _ref8;

      _ref7 = this.dragbars;
      for (_j = 0, _len1 = _ref7.length; _j < _len1; _j++) {
        dragbar = _ref7[_j];
        dragbar.toggle(visibility);
      }
      _ref8 = this.handles;
      for (_k = 0, _len2 = _ref8.length; _k < _len2; _k++) {
        handle = _ref8[_k];
        handle.toggle(visibility);
      }
      this.rotateHandle.toggle(visibility);
      if (this.options.centralHandle) {
        this.centralHandle.toggle(visibility);
      }
      return this;
    };

    return HandlerContainerView;

  })(Backbone.View);

  SelectionView = (function(_super) {
    __extends(SelectionView, _super);

    function SelectionView() {
      this.assignCursor = __bind(this.assignCursor, this);      _ref7 = SelectionView.__super__.constructor.apply(this, arguments);
      return _ref7;
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
      _ref8 = DragbarView.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    DragbarView.prototype.className = function() {
      return "ord-" + this.options.card + " dragbar";
    };

    return DragbarView;

  })(SelectionView);

  HandleView = (function(_super) {
    __extends(HandleView, _super);

    function HandleView() {
      _ref9 = HandleView.__super__.constructor.apply(this, arguments);
      return _ref9;
    }

    HandleView.prototype.className = function() {
      return "ord-" + this.options.card + " handle";
    };

    return HandleView;

  })(SelectionView);

  RotateHandleView = (function(_super) {
    __extends(RotateHandleView, _super);

    function RotateHandleView() {
      _ref10 = RotateHandleView.__super__.constructor.apply(this, arguments);
      return _ref10;
    }

    RotateHandleView.prototype.className = 'handleRotation';

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
      _ref11 = CentralHandle.__super__.constructor.apply(this, arguments);
      return _ref11;
    }

    CentralHandle.prototype.className = 'handle central';

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
      _ref12 = TrackerView.__super__.constructor.apply(this, arguments);
      return _ref12;
    }

    TrackerView.prototype.className = 'tracker';

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

  this.Block = (function(_super) {
    __extends(Block, _super);

    function Block() {
      _ref13 = Block.__super__.constructor.apply(this, arguments);
      return _ref13;
    }

    return Block;

  })(Backbone.Model);

}).call(this);
