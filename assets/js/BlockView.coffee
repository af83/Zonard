# polyfill:
# We check what the rotation transformation name is
# in the browser
transformName = null
for b in ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"] when document.body.style[b]?
  transformName = b

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

# BlockView
class @BlockView extends Backbone.View

  className: 'zonard'

  # @params options {object}
  # @params options.model {Block}
  # @params options.workspace {JQuerySelector}
  initialize: ->
    @contains = new RotateContainerView
    @listenToDragStart()
    @position()
    @$el.css({"background-color":"#ff0000"})
    # we attribute the angle beta
    @beta = (@model.get 'rotate') * (2 * Math.PI / 360)
    @setState()

  position: ()->
    for prop in 'top left width height'.split ' '
      @$el.css(prop, @model.get(prop))
    @contains.rotate @model.get 'rotate'
    @

  listenToDragStart: ->
    #@trigger 'drag:start', {at: at, card: @options.card}
    for handle in @contains.handlerContainer.handles
      @listenTo handle, 'drag:start', (data)=>
        @setTransform fn: @resize, end: @endResize
        @listenMouse()
        @setState data

    for dragbar in @contains.handlerContainer.dragbars
      @listenTo dragbar, 'drag:start', (data)=>
        @trigger 'start:resize'
        @setState data
        @setTransform fn: @resize, end: @endResize
        @listenMouse()

    @listenTo @contains.handlerContainer.tracker, 'drag:start', (data)=>
      @trigger 'start:move'
      @setTransform fn: @move, end: @endMove
      @listenMouse()
      @setState data

    @listenTo @contains.handlerContainer.rotateHandle, 'drag:start', (data)=>
      @trigger 'start:rotate'
      @setState data
      @setTransform fn: @rotate, end: @endRotate
      @listenMouse()

  listenMouse: ->
    @options.workspace.on 'mousemove', @_transform.fn
    @options.workspace.on 'mouseup', @_transform.end
    @options.workspace.on 'mouseleave', @_transform.end

  releaseMouse: =>
    @options.workspace
      .off('mousemove', @_transform.fn)
      .off('mouseup', @_transform.end)
      .off('mouseleave', @_transform.end)

  setTransform: (@_transform)->

  #
  # Drag'n'Drop of the block
  #
  setState: (@_state={})=>
    # passing a lot of data, for not having to look it
    # up inside the handler
    box = @contains.el.getBoundingClientRect()
    w = @$el.width()
    h = @$el.height()
      # the initial position of @el
    @_state.elPosition = @$el.position()
    @_state.elOffset = @$el.offset()
    @_state.bounds =
        ox: (box.width - w) / 2
        oy: (box.height - h) / 2
        x: @options.workspace.width() - (box.width / 2 + w / 2)
        y: @options.workspace.height() - (box.height / 2 + h / 2)
    @_state.elDimension =
      width: w
      height: h
    @_state.coef = @coefs[@_state.card] if @_state.card?
    # we calculate the coordinates of the center of the rotation container
    @_state.rotatedCenter =
      x: @_state.elOffset.left + (w / 2) * Math.cos(@beta) - (h / 2) * Math.sin(@beta)
      y: @_state.elOffset.top + (w / 2) * Math.sin(@beta) + (h / 2) * Math.cos(@beta)
    @_state.elCenter =
      x: @_state.elOffset.left + w / 2
      y: @_state.elOffset.top  + h / 2
    @_state.workspaceOffset =
      left: @_state.elPosition.left - @_state.elOffset.left
      top:  @_state.elPosition.top   - @_state.elOffset.top


    #DEBUG

    #console.log("center")
    #console.log(@_state.center)
    #console.log("el offset")
    #console.log(@_state.elOffset)
    #console.log("el position")
    #console.log(@_state.elPosition)

  # @chainable
  move: (event)=>
    vector =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y
    pos =
      left: vector.x + @_state.elPosition.left
      top: vector.y + @_state.elPosition.top

    ###
    bounds = @_state.bounds
    if pos.left < bounds.ox
      pos.left = bounds.ox
    else if pos.left > bounds.x
      pos.left = bounds.x
    if pos.top < bounds.oy
      pos.top = bounds.oy
    else if pos.top > bounds.y
      pos.top = bounds.y
    ###
    @$el.css(pos)
    @trigger 'change:move', pos
    @

  # @todo events are on document
  endMove: =>
    @releaseMouse()
    @trigger 'end:move'

  #
  # Rotation of the selectR subcontainer
  #
  rotate: (event)=>
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
    # beta is the angle between v and the vector (0,-1)
    @beta = (Math.asin(normalized.y) + Math.PI / 2) * sign
    betaDeg = @beta * 360 / (2 * Math.PI)

    # the difference between the old and new value

    # "original" M
    originalM =
      x : @_state.rotatedCenter.x - @_state.elDimension.width / 2
      y : @_state.rotatedCenter.y - @_state.elDimension.height / 2

    #console.log("original M")
    #console.log(originalM)

    # we now have to figure out the new position of the (0,0)
    # of the zonard:
    cM =
      x : @_state.elOffset.left - @_state.elCenter.x
      y : @_state.elOffset.top - @_state.elCenter.y

    cN =
      x : cM.x * Math.cos(@beta) - cM.y * Math.sin(@beta)
      y : cM.x * Math.sin(@beta) + cM.y * Math.cos(@beta)

    mN =
      x : cN.x - cM.x
      y : cN.y - cM.y

    #console.log("norme MN")
    #console.log(V.norm(mN))

    # preparing and changing css
    @$el.css
      left : originalM.x + mN.x + @_state.workspaceOffset.left
      top : originalM.y  + mN.y + @_state.workspaceOffset.top
    @contains.rotate betaDeg
    @trigger 'change:rotate', betaDeg

  endRotate:=>
    @releaseMouse()
    @trigger 'end:rotate'

  # we build a coefficient table, wich indicates the modication
  # pattern corresponding to each cardinal
  # pattern: [left,top,width,height]
  coefs:
    n:  [0, 1,  0, -1]
    s:  [0, 0,  0,  1]
    e:  [0, 0,  1,  0]
    w:  [1, 0, -1,  0]
    nw: [1, 1, -1, -1]
    ne: [0, 1,  1, -1]
    se: [0, 0,  1,  1]
    sw: [1, 0, -1,  1]

  resize: (event)=>
    bounds = @_state.bounds
    coef = @_state.coef
    vector =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y

    #console.log("pointer vector norm")
    #console.log(V.norm(vector))

    localVector =
      x: vector.x * Math.cos(@beta) + vector.y * Math.sin(@beta)
      y: -vector.x * Math.sin(@beta) + vector.y * Math.cos(@beta)

    #console.log("local vector norm")
    #console.log(V.norm(localVector))

    #console.log(V.norm(vector) - V.norm(localVector) < 0.00001)
    #console.log("i",V.signedDir(localVector, 'x'))
    #console.log("j",V.signedDir(localVector, 'y'))

    console.log(localVector)

    style =
      left :  coef[0] * localVector.x + @_state.elPosition.left
      top :   coef[1] * localVector.y + @_state.elPosition.top
      width:  coef[2] * localVector.x + @_state.elDimension.width
      height: coef[3] * localVector.y + @_state.elDimension.height

    @$el.css(style)
    @trigger 'change:resize', style
    ### WIP
    if pos.left < bounds.ox then pos.left = bounds.ox
    else if pos.left > bounds.x then pos.left = bounds.x

    if pos.top < bounds.oy then pos.top = bounds.oy
    else if pos.top > bounds.y then pos.top = bounds.y
    ###

  endResize: =>
    @releaseMouse()
    @trigger 'end:resize'

  # @chainable
  render: ->
    @$el.append @contains.render().el
    @


class @CloneView extends Backbone.View

  className: 'zonard'

  # @params options {object}
  # @params options.model {Block}
  # @params options.cloning {Zonard}
  initialize: ->
    @position()
    @rotate()
    @listenToZonard()

  listenToZonard: ->
    blockView = @options.cloning
    blockView.on 'change:resize', @position
    blockView.on 'end:resize', ->
    blockView.on 'start:resize', ->

    blockView.on 'change:rotate', @rotate
    blockView.on 'start:rotate', ->
    blockView.on 'end:rotate', ->

    blockView.on 'change:move', @position
    blockView.on 'start:move', ->
    blockView.on 'end:move', ->
    
  position: (data)=>
    data ?= @model.toJSON()
    for prop in 'top left width height'.split ' '
      @$el.css(prop, data[prop])
    @
  
  rotate: (deg)=>
    deg ?= @model.get 'rotate'
    @$el.css transformName, "rotate(#{deg}deg)"


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
    # set tranform-origin css property
    @$el.css({'transform-origin': 'left top'})
    @handlerContainer = new HandlerContainerView
    @display = new DisplayContainerView

  # @chainable
  render: ->
    @$el
      .append(@display.render().el)
      .append(@handlerContainer.render().el)
    @

  rotate: (deg)->
    @$el.css transformName, "rotate(#{deg}deg)"


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

  start: (event)->
    event.preventDefault()
    origin =
      x: event.pageX
      y: event.pageY
    @trigger 'drag:start', {origin: origin, card: @options.card}

# create the dragbars
class DragbarView extends SelectionView
  className: -> "ord-#{@options.card} dragbar"

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @$el.css cursor: @options.card + '-resize'

# create the handles
class HandleView extends SelectionView
  className: -> "ord-#{@options.card} handle"

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @$el.css  cursor: @options.card + '-resize'


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
