# polyfill:
# We check what the rotation transformation name is
# in the browser
@transformName = null
for b in ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"] when document.body.style[b]?
  @transformName = b
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

Cards = ['n', 's', 'e', 'w', 'nw', 'ne', 'se', 'sw']
ordCards = ['s', 'sw', 'w', 'nw', 'n', 'ne', 'e', 'se']

# BlockView
class @BlockView extends Backbone.View

  className: 'zonard'

  # @params options {object}
  # @params options.model {Block}
  # @params options.workspace {div element}
  initialize: ->
    @rCont = new RotateContainerView
    # set tranform-origin css property
    @rCont.$el.css({'transform-origin': 'left top'})

    @workspace = @options.workspace
    @$workspace = $ @workspace
    @listenToDragStart()
    @$el.css({"background-color":"#ff0000"})

    # initialize _state object, that will hold informations
    # necessary to determines the block position and rotation
    @_state = {}

    # we set the rotation angle
    angleDeg = @model.get 'rotate'
    angleRad = angleDeg * (2 * Math.PI) /360
    @_state.angle =
      rad: angleRad
      deg: angleDeg
      cos: Math.cos(angleRad)
      sin: Math.sin(angleRad)


    # Caution: can't call getClientBoundingRectangle in IE9 if element not
    # in the DOM
    # @_setState()
    handle.assignCursor(@_state.angle.rad) for i, handle of @rCont.handlerContainer.handles
    dragbar.assignCursor(@_state.angle.rad) for i, dragbar of @rCont.handlerContainer.dragbars

  listenToDragStart: ->
    #@trigger 'drag:start', {at: at, card: @options.card}
    for handle in @rCont.handlerContainer.handles
      @listenTo handle, 'drag:start', (data)=>
        @trigger 'start:resize'
        @_setState data
        @setTransform fn: @_calculateResize, end: @_endResize
        @listenMouse()

    for dragbar in @rCont.handlerContainer.dragbars
      @listenTo dragbar, 'drag:start', (data)=>
        @trigger 'start:resize'
        @_setState data
        @setTransform fn: @_calculateResize, end: @_endResize
        @listenMouse()

    @listenTo @rCont.handlerContainer.tracker, 'drag:start', (data)=>
      @trigger 'start:move'
      @_setState data
      @setTransform fn: @_calculateMove, end: @_endMove
      @listenMouse()

    @listenTo @rCont.handlerContainer.rotateHandle, 'drag:start', (data)=>
      @trigger 'start:rotate'
      @_setState data
      @setTransform fn: @_calculateRotate, end: @_endRotate
      @listenMouse()

  listenMouse: ->
    @workspace.on 'mousemove', @_transform.fn
    @workspace.on 'mouseup', @_transform.end
    @workspace.on 'mouseleave', @_transform.end

  releaseMouse: =>
    @workspace
      .off('mousemove', @_transform.fn)
      .off('mouseup', @_transform.end)
      .off('mouseleave', @_transform.end)

  setTransform: (@_transform)->

  # the 3 basic movements
  #
  # position: {left: x, top: y}
  move: (position)=>
    @$el.css(position)

  # box: {left:x, top: y, width:w, height: h}
  resize: (box)=>
    @$el.css(box)

  rotate: (angleDeg,position)=>
    @rCont.$el.css
      transform: "rotate(#{angleDeg}deg"
      top: position?.top
      left: position?.left

  #
  # Method to be called before calculating any displacement
  #
  _setState: (data = {})=>
    # passing a lot of data, for not having to look it
    # up inside the handler
    @_state = $.extend(true, @_state, data)
    # TODO: find a way to figure out the angle of rotation with the
    # output of @rCont.$el.css('transform')

    # WARNING!!! problems in IE9 when trying to get bounding
    # client rect when the element is not in the dom yet!
    box = @rCont.el.getBoundingClientRect()
    w = @$el.width()
    h = @$el.height()
    # we precalculate the value of cos and sin
    @_state.angle.cos = Math.cos(@_state.angle.rad)
    @_state.angle.sin = Math.sin(@_state.angle.rad)
    # the initial position of @el
    @_state.elPosition = @$el.position()
    @_state.elOffset = @$el.offset()
    # example of position bound based on the box that bounds
    # the rotateContainer
    @_state.positionBounds =
      #ox: (box.width - w) / 2
      #oy: (box.height - h) / 2
      #x: @workspace.width() - (box.width / 2 + w / 2)
      #y: @workspace.height() - (box.height / 2 + h / 2)
      ox: -Infinity
      oy: -Infinity
      x: Infinity
      y: Infinity
    @_state.elDimension =
      width: w
      height: h
    # we calculate the coordinates of the center of the rotation container
    @_state.rotatedCenter =
      x: @_state.elOffset.left + (w / 2) * @_state.angle.cos - (h / 2) * @_state.angle.sin
      y: @_state.elOffset.top + (w / 2) * @_state.angle.sin + (h / 2) * @_state.angle.cos
    @_state.elCenter =
      x: @_state.elOffset.left + w / 2
      y: @_state.elOffset.top  + h / 2
    @_state.workspaceOffset =
      left: @_state.elPosition.left - @_state.elOffset.left
      top:  @_state.elPosition.top   - @_state.elOffset.top

    # if we are dealing with a handle, we need to set the bases, and we need
    # to calculate the minimum and maximum  top left of the el - TODO
    @_state.coef = @coefs[@_state.card] if @_state.card?
    @_state.sizeBounds =
      wMin: 20
      wMax: Infinity
      hMin: 20
      hMax: Infinity

  # drag'n'drop of the block
  # @chainable
  _calculateMove: (event)=>
    vector =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y
    pos =
      left: vector.x + @_state.elPosition.left + "px"
      top: vector.y + @_state.elPosition.top + "px"

    ### to constrain the displacement with bound
    bounds = @_state.positionBounds
    if pos.left < bounds.ox
      pos.left = bounds.ox
    else if pos.left > bounds.x
      pos.left = bounds.x
    if pos.top < bounds.oy
      pos.top = bounds.oy
    else if pos.top > bounds.y
      pos.top = bounds.y
    ###
    @move(pos)
    #console.log(@$el.position().left)
    #console.log(@$el.position().top)
    @trigger 'change:move', pos
    @

  # @todo events are on document
  _endMove: =>
    @releaseMouse()
    @trigger 'end:move'

  #
  # Rotation of the selectR subcontainer
  #
  _calculateRotate: (event)=>
    # v is the vector from the center of the content to
    # the pointer of the mouse
    direction =
      x: event.pageX
      y: event.pageY
    vector = V.vector(direction, @_state.rotatedCenter)
    # vn is v normalized
    normalized = V.normalized vector
    # "sign" is the sign of v.x
    sign = V.signedDir vector, 'x'
    # @_state.angle is the angle between v and the vector (0,-1)
    @_state.angle.rad = (Math.asin(normalized.y) + Math.PI / 2) * sign
    @_state.angle.deg = @_state.angle.rad * 360 / (2 * Math.PI)

    @_state.angle.cos = Math.cos(@_state.angle.rad)
    @_state.angle.sin = Math.sin(@_state.angle.rad)

    # the difference between the old and new value

    # "original" M
    originalM =
      x : @_state.rotatedCenter.x - @_state.elDimension.width / 2
      y : @_state.rotatedCenter.y - @_state.elDimension.height / 2

    # we now have to figure out the new position of the (0,0)
    # of the zonard:
    cM =
      x : @_state.elOffset.left - @_state.elCenter.x
      y : @_state.elOffset.top - @_state.elCenter.y

    cN =
      x : cM.x * @_state.angle.cos - cM.y * @_state.angle.sin
      y : cM.x * @_state.angle.sin + cM.y * @_state.angle.cos

    mN =
      x : cN.x - cM.x
      y : cN.y - cM.y

    # preparing and changing css
    @$el.css
      left : originalM.x + mN.x + @_state.workspaceOffset.left
      top : originalM.y  + mN.y + @_state.workspaceOffset.top
    @rCont.$el.css {transform: "rotate(#{@_state.angle.deg}deg)"}
    @trigger 'change:rotate', @_state.angle.deg

  _endRotate:=>
    @releaseMouse()
    @trigger 'end:rotate'
    handle.assignCursor(@_state.angle.rad) for i, handle of @rCont.handlerContainer.handles
    dragbar.assignCursor(@_state.angle.rad) for i, dragbar of @rCont.handlerContainer.dragbars

  # we build a coefficient table, wich indicates the modication
  # pattern corresponding to each cardinal
  # the 2 first are the direction on which to project in the
  # local base to obtain the top & left movement
  # the 2 last are for the width & height modification
  coefs:
    n : [ 0,  1,  0, -1]
    s : [ 0,  0,  0,  1]
    e : [ 0,  0,  1,  0]
    w : [ 1,  0, -1,  0]
    nw : [ 1,  1, -1, -1]
    ne : [ 0,  1,  1, -1]
    se : [ 0,  0,  1,  1]
    sw : [ 1,  0, -1,  1]

  _calculateResize: (event)=>
    coef = @_state.coef

    vector =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y

    localVector =
      x: vector.x * @_state.angle.cos + vector.y * @_state.angle.sin
      y: -vector.x * @_state.angle.sin + vector.y * @_state.angle.cos

    # new dimensions of the el
    dim =
      w: coef[2] * localVector.x + @_state.elDimension.width
      h: coef[3] * localVector.y + @_state.elDimension.height

    bounds = @_state.sizeBounds
    # constrain is a couple of boolean that decide if we need to
    # change the top and left style
    constrain =
      x: 1
      y: 1
    if dim.w < bounds.wMin
      dim.w = bounds.wMin
      constrain.x = 0
    else if dim.w > bounds.wMax
      dim.w = bounds.wMax
      constrain.x = 0
    if dim.h < bounds.hMin
      dim.h = bounds.hMin
      constrain.y = 0
    else if dim.h > bounds.hMax
      dim.h = bounds.hMax
      constrain.y = 0

    # vector on which we need to project
    #  x: coef[0]
    #  y: coef[1]
    #  so our local vector projected on proj is
    mB1 =
      x: localVector.x * coef[0]
      y: localVector.y * coef[1]

    #mB1.x *= constrain.x
    #mB1.y *= constrain.y

    #translated in the base of the screen, it gives us
    mB0 =
      x: @_state.angle.cos * mB1.x - @_state.angle.sin * mB1.y
      y: @_state.angle.sin * mB1.x + @_state.angle.cos * mB1.y

    box = {}
    if constrain.x
      box.left  =  (mB0.x + @_state.elPosition.left)
      box.width =  dim.w
    if constrain.y
      box.top =    (mB0.y + @_state.elPosition.top)
      box.height = dim.h

    @resize(box)
    @trigger 'change:resize', box

  _endResize: =>
    @releaseMouse()
    @trigger 'end:resize'

  # @chainable
  render: ->
    @$el.append @rCont.render().el
    # initializes from the model
    box = {}
    for prop in 'top left width height'.split ' '
      box[prop] = @model.get(prop)
    @$el.css(box)

    angleDeg = @model.get 'rotate'
    @rCont.$el.css {transform: "rotate(#{angleDeg}deg)"}
    @


# global subcontainer to which rotations will be applied
# el
#   display
#     content
#     borders
#   handlerContainer
#     tracker
#     rotateHandle
#     dragbars
#     handles
class RotateContainerView extends Backbone.View

  className: 'rotateContainer'
  initialize: ->
    @handlerContainer = new HandlerContainerView
    @display = new DisplayContainerView

  # @chainable
  render: ->
    @$el
      .append(@display.render().el)
      .append(@handlerContainer.render().el)
    @


# display container that holds the content and the borders of the
# content
class DisplayContainerView extends Backbone.View

  className: 'displayContainer'
  initialize: ->
    @borders = for card, i in Cards.slice 0, 4
      new BorderView card: card

  # @chainable
  render: ->
    @$el.append border.render().el for border in @borders
    @

# the content that we display
class ContentView extends Backbone.View
  className: 'content'


# the borders are the line that are displayed around the content
# @params options {object}
# @params options.card {srting}
class BorderView extends Backbone.View
  className: ->
    "border ord-#{@options.card}"


class HandlerContainerView extends Backbone.View
  className: 'handlerContainer'
  initialize: ->
    @dragbars = for card, i in Cards.slice(0, 4)
      new DragbarView card: card
    @handles = for card, i in Cards
      new HandleView card: card
    @rotateHandle = new RotateHandleView
    @tracker = new TrackerView

  # @chainable
  render: ->
    @$el.append(@tracker.render().el)
    @$el.append dragbar.render().el for dragbar in @dragbars
    @$el.append handle.render().el for handle in @handles
    @$el.append(@rotateHandle.render().el)
    @


class SelectionView extends Backbone.View
  events:
    'mousedown' : 'start'

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @card = @options.card
    @indexCard = _.indexOf(ordCards,@card)
    @$el.css cursor: @card + '-resize'

  start: (event)->
    event.preventDefault()
    origin =
      x: event.pageX
      y: event.pageY
    @trigger 'drag:start', {origin: origin, card: @card}

  assignCursor: (angle)=>
    permut = (@indexCard + Math.floor((angle + Math.PI/8) / (Math.PI/4))) %8
    permut += 8 if permut<0
    currentCard = ordCards[permut]
    @el.style.cursor = "#{currentCard}-resize"

# create the dragbars
class DragbarView extends SelectionView
  className: -> "ord-#{@options.card} dragbar"


# create the handles
class HandleView extends SelectionView
  className: -> "ord-#{@options.card} handle"


# the special handler responsible for the rotation
class RotateHandleView extends Backbone.View
  className: 'handleRotation'
  events:
    'mousedown' : 'start'
  initialize: ->
    #@listenTo $el, 'mousedown', =>

  start: (event)->
    event.preventDefault()
    @trigger 'drag:start'


#This element is here to receive mouse events (clicks)
class TrackerView extends Backbone.View
  className: 'tracker'
  events:
    'mousedown' : 'start'

  start: (event)->
    event.preventDefault()
    origin =
      x: event.pageX
      y: event.pageY
    @trigger 'drag:start', {origin: origin}
