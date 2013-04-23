# polyfill:
# We check what the rotation transformation name is
# in the browser
transformName = null
for b in ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"] when document.body.style[b]?
  transformName = b

# Vector Helper
V =
  eventDir: (event)->
    x: event.pageX - event.data.x
    y: event.pageY - event.data.y

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

  events:
    'mousedown .tracker'        : 'beginMove'
    'mousedown .handleRotation' : 'beginRotate'
    'mousedown .dragbar'        : 'handlerDispatcher'
    'mousedown .handle'         : 'handlerDispatcher'

  # @params options {object}
  # @params options.model {Block}
  # @params options.workspace {JQuerySelector}
  initialize: ->
   @contains = new RotateContainerView

  #
  # Drag'n'Drop of the block
  #
  beginMove: (event)=>
    # passing a lot of data, for not having to look it
    # up inside the handler
    box = @contains.el.getBoundingClientRect()
    data =
      # the origin of the mouseon
      origin :
        x: event.pageX
        y: event.pageY
        # the initial position of @el
      initialPosition : @$el.position()
      bounds:
        ox: (box.width - @$el.width()) / 2
        oy: (box.height - @$el.height()) / 2
        x: @options.workspace.width() - (box.width / 2 + @$el.width() / 2)
        y: @options.workspace.height() - (box.height / 2 + @$el.height() / 2)
      # are the 2 following events even possible considering
      # we are 'on' the image? hum....
    $(document).on 'mouseup', @endMove
    $(document).on 'mouseleave', @endMove
    @options.workspace.on 'mousemove', data, @move

  # @chainable
  move: (event)=>
    bounds = event.data.bounds
    vector =
      x: event.pageX - event.data.origin.x
      y: event.pageY - event.data.origin.y
    pos =
      left: vector.x + event.data.initialPosition.left
      top: vector.y + event.data.initialPosition.top
    if pos.left < bounds.ox then pos.left = bounds.ox
    else if pos.left > bounds.x then pos.left = bounds.x

    if pos.top < bounds.oy then pos.top = bounds.oy
    else if pos.top > bounds.y then pos.top = bounds.y
    @$el.css(pos)
    @

  # @todo events are on document
  endMove: (event)=>
    @options.workspace
      .off('mouseup', @endMove)
      .off('mouseleave', @endMove)
      .off('mousemove', @move)

  #
  # Rotation of the selectR subcontainer
  #
  beginRotate: =>
    offset = @$el.offset()
    center =
      x: offset.left + @$el.width() / 2
      y: offset.top  + @$el.height() / 2
    $(document).on('mouseup', @endRotate)
    $(document).on('mouseleave', @endRotate)
    @options.workspace.on('mousemove', center, @rotate)

  rotate: (event)=>
    # v is the vector from the center of the content to
    # the pointer of the mouse
    vector = V.eventDir event
    # vn is v normalized
    normalized = V.normalized vector
    # "sign" is the sign of v.x
    sign = V.signedDir vector, 'x'
    # beta is the angle between v and the vector (0,-1)
    beta = (Math.asin(normalized.y) + Math.PI / 2) * sign
    betaDeg = beta * 360 / (2 * Math.PI)
    # preparing and changing css
    @contains.$el.css transformName, "rotate(#{betaDeg}deg)"

  # @todo event were attach on document
  endRotate:=>
    @options.workspace
      .off('mouseup', @endRotate)
      .off('mouseleave', @endRotate)
      .off('mousemove', @rotate)


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

  #
  # Dispatch events from dragbars and handles
  # For now this just does a resize
  # @todo rewrite event handling on draggable event.
  #
  handlerDispatcher: (event)=>
    $target = $ event.currentTarget

    # @todo should be remove on next code rework
    re = /ord\-([nsew]{1,2})/
    dir = (re.exec $target[0].className)[1]

    data =
      # the origin of the mouseon
      origin :
        x: event.pageX
        y: event.pageY
        # the initial position of @el
      initialPosition : @$el.position()
      initialDimension:
        width: @$el.width()
        height: @$el.height()
      # if isESES, we only change dimensions
      # else, we change dimensionis and position of the el
      coef: @coefs[dir]

    $(document).on('mouseup', @endResize)
    $(document).on('mouseleave', @endResize)
    @options.workspace.on('mousemove', data, @resize)

  resize: (event)=>
    bounds = event.data.bounds
    coef = event.data.coef
    vector =
      x: event.pageX - event.data.origin.x
      y: event.pageY - event.data.origin.y

    style =
      left :  coef[0] * vector.x + event.data.initialPosition.left
      top :   coef[1] * vector.y + event.data.initialPosition.top
      width:  coef[2] * vector.x + event.data.initialDimension.width
      height: coef[3] * vector.y + event.data.initialDimension.height

    @$el.css(style)
    ### WIP
    if pos.left < bounds.ox then pos.left = bounds.ox
    else if pos.left > bounds.x then pos.left = bounds.x

    if pos.top < bounds.oy then pos.top = bounds.oy
    else if pos.top > bounds.y then pos.top = bounds.y
    ###

  endResize: (event)=>
    $(document).off('mouseup', @endResize)
    $(document).off('mouseleave', @endResize)
    @options.workspace.off('mousemove', @resize)

  # @chainable
  render: ->
    @$el.append @contains.render().el
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
    @content = new ContentView

  # @chainable
  render: ->
    @$el.append @content.render().el
    @$el.append border.render().el for border in @borders
    @

# the content that we display
class ContentView extends Backbone.View
  tagName: 'img'
  className: 'content'

  initialize: ->
    @$el.attr
      src: 'assets/images/cat.jpg'


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


# create the dragbars
class DragbarView extends Backbone.View
  className: -> "ord-#{@options.card} dragbar"

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @$el.css cursor: @options.card + '-resize'


# create the handles
class HandleView extends Backbone.View
  className: -> "ord-#{@options.card} handle"

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @$el.css  cursor: @options.card + '-resize'


# the special handler responsible for the rotation
class RotateHandleView extends Backbone.View
  className: 'handleRotation'
  initialize: ->
    #@listenTo $el, 'mousedown', =>


#This element is here to receive mouse events (clicks)
class TrackerView extends Backbone.View
  className: 'tracker'
  initialize: ->
