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
    @displayContainer = new DisplayContainerView
    @visibility = on

  # @chainable
  render: ->
    @$el.append @displayContainer.render().el, @handlerContainer.render().el
    @


# display container that holds the content and the borders of the
# content
class DisplayContainerView extends Backbone.View
  className: 'displayContainer'

  initialize: ->
    @borders = for card, i in Cards[..3]
      new BorderView card: card
    @visibility = on

  # @chainable
  render: ->
    @toggle @visibility
    @$el.append border.render().el for border in @borders
    @

  # @chainable
  toggle: (@visibility)->
    @$el.toggle(visibility)
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
    @dragbars = for card, i in Cards[..3]
      new DragbarView card: card
    @handles = for card, i in Cards
      new HandleView card: card
    @rotateHandle = new RotateHandleView
    @tracker = new TrackerView

  # @chainable
  render: ->
    @$el.append @tracker.render().el
    @$el.append dragbar.render().el for dragbar in @dragbars
    @$el.append handle.render().el for handle in @handles
    @$el.append @rotateHandle.render().el
    @

  # @chainable
  toggle: (visibility)->
    dragbar.toggle visibility for dragbar in @dragbars
    handle.toggle visibility for handle in @handles
    @rotateHandle.toggle visibility
    @

class SelectionView extends Backbone.View
  events:
    mousedown: 'start'

  # @params options {object}
  # @params options.card {srting}
  initialize: ->
    @card = @options.card
    @indexCard = _.indexOf(ordCards, @card)
    @$el.css cursor: @card + '-resize'

  start: (event)->
    event.preventDefault()
    origin =
      x: event.pageX
      y: event.pageY
    @trigger 'drag:start', {origin: origin, card: @card}

  assignCursor: (angle)=>
    permut = (@indexCard + Math.floor((angle + Math.PI / 8) / (Math.PI / 4))) % 8
    permut += 8 if permut < 0
    currentCard = ordCards[permut]
    @el.style.cursor = "#{currentCard}-resize"

  # @chainable
  toggle: (visibility)->
    @$el.toggle(visibility)
    @


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
    mousedown: 'start'

  start: (event)->
    event.preventDefault()
    @trigger 'drag:start'

  # @chainable
  toggle: (visibility)->
    @$el.toggle(visibility)
    @


#This element is here to receive mouse events (clicks)
class TrackerView extends Backbone.View
  className: 'tracker'

  events:
    mousedown: 'start'
    click: 'focus'

  focus: (event)->
    event.stopPropagation()
    @trigger 'focus'

  start: (event)->
    event.preventDefault()
    origin =
      x: event.pageX
      y: event.pageY
    @trigger 'drag:start', origin: origin
