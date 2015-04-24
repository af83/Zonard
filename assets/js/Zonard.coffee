Cards = 'n,s,e,w,nw,ne,se,sw'.split ','
ordCards = 's,sw,w,nw,n,ne,e,se'.split ','

# Zonard
class @Zonard extends Backbone.View
  className: 'zonard'

  # @params options {object}
  # @params options.box {left, top, width, height, rotate}
  # @params options.workspace {div element}
  # @params options.centralHandle {bool} (optional)
  # @params options.preserveRatio {bool} (optional)
  initialize: (options)->
    @box = options.box
    @needCentralHandle = options.centralHandle
    @workspaceAngle = options.workspaceAngle or 0

    @handlerContainer = new HandlerContainerView options
    @displayContainer = new DisplayContainerView
    @visibility = on

    # set tranform-origin css property
    @$el.css  'transform-origin': 'left top'

    @workspace = options.workspace
    @$workspace = $ @workspace

    # if this option is set to true, the zonard will keep the ratio
    # it was initialized with on resize interactions
    # it will also hide the dragbars and the n e s w handles
    if @preserveRatio = options.preserveRatio || off
      @setRatio @box.width / @box.height
      @togglePreserveRatio @preserveRatio

    # initialize _state object, that will hold informations
    # necessary to determines the block position and rotation
    @_state = {}

    angleDeg = @box.rotate
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

  # in the case we want to preserve the ratio, we also need
  # to change the size boundaries accordingly
  setRatio: (@ratio)->
    @sizeBounds.hMin = @sizeBounds.wMin / @ratio
    @sizeBounds.hMax = @sizeBounds.wMax / @ratio


  togglePreserveRatio: (condition)->
    @$el.toggleClass 'preserve-ratio', condition

  listenFocus: ->
    @listenToOnce @handlerContainer.tracker, 'focus', =>
      @trigger 'focus'

  toggle: (visibility)->
    @$el.toggleClass "zonard-hidden", !visibility
    @

  # @chainable
  listenToDragStart: ->
    for handle in @handlerContainer.handles
      @listenTo handle, 'drag:start', (data)=>
        @startTransform data, 'start:resize'
        @setTransform
          fn: =>
            box = @_calculateResize @_latestEvent
            @setBox(box)
            @trigger 'change:resize', box
          end: =>
            @releaseMouse()
            @box = @_calculateResize @_latestEvent
            @setBox(@box)
            @trigger 'end:resize', @_setState()
        @listenMouse()

    for dragbar in @handlerContainer.dragbars
      @listenTo dragbar, 'drag:start', (data)=>
        @startTransform data, 'start:resize'
        @setTransform
          fn: =>
            box = @_calculateResize @_latestEvent
            @setBox(box)
            @trigger 'change:resize', box
          end: =>
            @releaseMouse()
            @box = @_calculateResize @_latestEvent
            @setBox @box
            @trigger 'end:resize', @_setState()
        @listenMouse()

    @listenTo @handlerContainer.tracker, 'drag:start', (data)=>
      @startTransform data,'start:move'
      @_moved = no
      @setTransform
        fn: =>
          @_moved = yes
          box = @_calculateMove @_latestEvent
          @setBox(box)
          @trigger 'change:move', box
        end: =>
          @releaseMouse()
          # if the mouse has not moved, do not attempt to calculate
          # a displacement (and avoid snapping)
          if @_moved
            @box = @_calculateMove @_latestEvent
            @setBox @box
          @trigger 'end:move', @_setState()
      @listenMouse()

    @listenTo @handlerContainer.rotateHandle, 'drag:start', (data)=>
      @startTransform data, 'start:rotate'
      @setTransform
        fn: =>
          box = @_calculateRotate @_latestEvent
          @setBox box
          @trigger 'change:rotate', box
        end: =>
          @box = @_calculateRotate @_latestEvent
          @setBox @box
          @releaseMouse()
          @trigger 'end:rotate', @_setState()
          @assignCursor()
      @listenMouse()

    if @needCentralHandle
      @listenTo @handlerContainer.centralHandle, 'drag:start', (data)=>
        @startTransform data, 'start:centralDrag'
        @setTransform
          fn: =>
            box = @_calculateCentralDrag @_latestEvent
            @trigger 'info:centralDrag', box
          end: =>
            @releaseMouse()
            @trigger 'end:centralDrag', @_calculateCentralDrag @_latestEvent
        @listenMouse()

    @

  listenMouse: ->
    $('body').on('mousemove', @debouncer)
             .on('mouseup', @endTransform)
             .on('mouseleave', @endTransform)

  releaseMouse: =>
    $('body').off('mousemove', @debouncer)
             .off('mouseup', @endTransform)
             .off('mouseleave', @endTransform)

  setTransform: (@_transform)->

  startTransform: (data, eventName)->
    @_setState data
    @_rafIndex = null
    @trigger eventName

  #check if there is already a call waiting
  debouncer: (@_latestEvent)=>
    if !@_rafIndex
      @updateTransform()
    else

  updateTransform: =>
    @_rafIndex = requestAnimationFrame =>
      @_transform.fn()
      @_rafIndex = null

  endTransform: (@_latestEvent)=>
    cancelAnimationFrame @_rafIndex
    @_transform.end @_latestEvent
    @_rafIndex = @_latestEvent = null

  # Method to set the position and rotation of the zonard the properties of box
  # are optionals
  # box: {left: x, top: y, width: w, height:h, rotate, angle(degrès)}
  setBox: (box = @getBox())->
    box.transform = "rotate(#{box.rotate}deg)"
    box.left = Math.round box.left
    box.top = Math.round box.top
    box.width = Math.round box.width
    box.height = Math.round box.height
    @$el.css box


  # return position information stored in state
  getBox:=>
    @_setState() unless @_state.elPosition?
    # we return the main informations of position
    left    : @_state.elPosition.left
    top     : @_state.elPosition.top
    width   : @_state.elDimension.width
    height  : @_state.elDimension.height
    rotate  : @_state.angle.deg
    center:
      x: @_state.rotatedCenter.x
      y: @_state.rotatedCenter.y
    bBox:
      width : @_state.bBox.width
      height: @_state.bBox.height

  # we build a coefficient table, wich indicates the modication pattern
  # corresponding to each cardinal
  #   * the first 2 are the direction on which to project in the local base to
  #   obtain the top & left movement
  #   * the last 2 are for the width & height modification
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
    @setBox _.pick @box, ['left', 'top', 'width', 'height', 'rotate']
    @

  remove: ->
    @handlerContainer.remove()
    @displayContainer.remove()
    @releaseMouse() if @_transform?
    super()

# we apply the calculator mixin
calculators Zonard.prototype
