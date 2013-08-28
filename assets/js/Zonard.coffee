# polyfill:
# We check what the rotation transformation name is
# in the browser
@transformName = null
d = document.createElement('div')
for b in ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"] when d.style[b]?
  @transformName = b
d = null
# Vector Helper
V =
  vector: (direction, center)->
    x: direction.x - center.x
    y: direction.y - center.y

  norm: (vector)->
    Math.sqrt vector.x * vector.x + vector.y * vector.y

  normalized: (vector)->
    norm = @norm vector
    x: vector.x / norm
    y: vector.y / norm

  signedDir: (vector, comp)->
    vector[comp] / Math.abs(vector[comp])

Cards = 'n,s,e,w,nw,ne,se,sw'.split ','
ordCards = 's,sw,w,nw,n,ne,e,se'.split ','

# Zonard
class @Zonard extends Backbone.View
  className: 'zonard'

  # @params options {object}
  # @params options.box {left, top, width, height, rotate}
  # @params options.workspace {div element}
  # @params options.centralHandle {bool} (optional)
  initialize: ->
    @handlerContainer = new HandlerContainerView @options
    @displayContainer = new DisplayContainerView
    @visibility = on

    # set tranform-origin css property
    @$el.css  'transform-origin': 'left top'

    @workspace = @options.workspace
    @$workspace = $ @workspace

    # if this option is set to true, the zonard will keep the ratio
    # it was initialized with on resize interactions
    # it will also hide the dragbars and the n e s w handles
    if @preserveRatio = @options.preserveRatio || off
      @ratio = @options.box.width / @options.box.height
      @togglePreserveRatio @preserveRatio
      # adapt the dimension of the min and max size so that it respect the same ratio
      @sizeBounds.hMin = @sizeBounds.wMin / @ratio
      @sizeBounds.hMax = @sizeBounds.wMax / @ratio

    # initialize _state object, that will hold informations
    # necessary to determines the block position and rotation
    @_state = {}

    angleDeg = @options.box.rotate
    angleRad = angleDeg * (2 * Math.PI) /360
    @_state.angle =
      rad: angleRad
      deg: angleDeg
      cos: Math.cos(angleRad)
      sin: Math.sin(angleRad)

    # Caution: can't call getClientBoundingRectangle in IE9 if element not
    # in the DOM
    # @_setState()
    @assignCursor()

  assignCursor: ->
    handle.assignCursor(@_state.angle.rad) for i, handle of @handlerContainer.handles
    dragbar.assignCursor(@_state.angle.rad) for i, dragbar of @handlerContainer.dragbars

  togglePreserveRatio: (condition)->
    @$el.toggleClass 'preserve-ratio', condition

  listenFocus: ->
    @listenToOnce @handlerContainer.tracker, 'focus', =>
      @trigger 'focus'

  toggle: (visibility)->
    @displayContainer.toggle visibility
    @handlerContainer.toggle visibility
    @

  # @chainable
  listenToDragStart: ->
    for handle in @handlerContainer.handles
      @listenTo handle, 'drag:start', (data)=>
        @trigger 'start:resize'
        @_setState data
        @setTransform
          fn: (event)=>
            box = @_calculateResize(event)
            @setBox(box)
            @trigger 'change:resize', box
          end: =>
            @releaseMouse()
            @trigger 'end:resize', @_setState()
        @listenMouse()

    for dragbar in @handlerContainer.dragbars
      @listenTo dragbar, 'drag:start', (data)=>
        @trigger 'start:resize'
        @_setState data
        @setTransform
          fn: (event)=>
            box = @_calculateResize(event)
            @setBox(box)
            @trigger 'change:resize', box
          end: =>
            @releaseMouse()
            @trigger 'end:resize', @_setState()
        @listenMouse()

    @listenTo @handlerContainer.tracker, 'drag:start', (data)=>
      @trigger 'start:move'
      @_setState data
      @setTransform
        fn: (event)=>
          box = @_calculateMove(event)
          @setBox(box)
          @trigger 'change:move', box
        end: =>
          @releaseMouse()
          @trigger 'end:move', @_setState()
      @listenMouse()

    @listenTo @handlerContainer.rotateHandle, 'drag:start', (data)=>
      @trigger 'start:rotate'
      @_setState data
      @setTransform
        fn: (event)=>
          box = @_calculateRotate(event)
          @setBox box
          @trigger 'change:rotate', box
        end: (event)=>
          box = @_calculateRotate(event)
          @setBox box
          @releaseMouse()
          @trigger 'end:rotate', @_setState()
          @assignCursor()
      @listenMouse()

    if @options.centralHandle
      @listenTo @handlerContainer.centralHandle, 'drag:start', (data)=>
        @trigger 'start:centralDrag'
        @_setState data
        @setTransform
          fn: (event)=>
            box = @_calculateCentralDrag(event)
            @trigger 'info:centralDrag', box
          end: (event)=>
            @releaseMouse()
            @trigger 'end:centralDrag', @_calculateCentralDrag(event)
        @listenMouse()

    @

  listenMouse: ->
    @$workspace.on 'mousemove', @_transform.fn
    @$workspace.on 'mouseup', @_transform.end
    @$workspace.on 'mouseleave', @_transform.end

  releaseMouse: =>
    @$workspace
      .off('mousemove', @_transform.fn)
      .off('mouseup', @_transform.end)
      .off('mouseleave', @_transform.end)

  setTransform: (@_transform)->

  # Method to set the position and rotation of the zonard
  # the properties of box are optionals
  # box: {left: x, top: y, width: w, height:h, rotate, angle(degrès)}
  setBox: (box = @getBox())->
    @$el.css transform: "rotate(#{box.rotate}deg)"
    @$el.css(box)

  # return position information stored in state
  getBox:=>
    # we return the main informations of position
    left    : @_state.elPosition.left
    top     : @_state.elPosition.top
    width   : @_state.elDimension.width
    height  : @_state.elDimension.height
    rotate  : @_state.angle.deg
    centerX : @_state.rotatedCenter.x - @_state.workspaceOffset.left
    centerY : @_state.rotatedCenter.y - @_state.workspaceOffset.top

  # we build a coefficient table, wich indicates the modication
  # pattern corresponding to each cardinal
  # the 2 first are the direction on which to project in the
  # local base to obtain the top & left movement
  # the 2 last are for the width & height modification
  coefs:
    n  : [ 0,  1,  0, -1]
    s  : [ 0,  0,  0,  1]
    e  : [ 0,  0,  1,  0]
    w  : [ 1,  0, -1,  0]
    nw : [ 1,  1, -1, -1]
    ne : [ 0,  1,  1, -1]
    se : [ 0,  0,  1,  1]
    sw : [ 1,  0, -1,  1]

  sizeBounds:
    wMin: 80
    wMax: Infinity
    hMin: 80
    hMax: Infinity

  # @chainable
  render: ->
    @$el.append @displayContainer.render().el, @handlerContainer.render().el
    # initializes css from the model attributes
    @setBox _.pick @options.box, ['left', 'top', 'width', 'height', 'rotate']
    @

# we apply the calculator mixin
calculators Zonard.prototype
