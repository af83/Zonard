#BlockView = require('../assets/js/BlockView.js')
class Block extends Backbone.Model

# set of parameters to initialize a model, necessary
# to instanciate a BlockView
nyan =
  type: 'image'
  src: "../assets/images/nyan.png"
  height: 100
  width: 200
  top: 300
  left: 300
  rotate: -45

# function able to build an array with the string output
# you get when you query the value of the transform attribute
# of an element - WORK IN PROGRESS
#@readMatrix = (transformString)->

# function that triggers a drag event from an element
# (specified by the className) of the selected zonard
# will simulate a displacement of the mouse of given
# vector
@triggerDragOn = (zonard, className, destination) =>
  # dom element on which to apply mousedown
  h = $(zonard.el).find(className)
  # preparing artificial dom events for mousedown & mousemove
  eventMousedown = new $.Event 'mousedown', {pageX: 300, pageY: 300}
  eventMousemove = new $.Event 'mousemove', destination
  h.trigger(eventMousedown)
  zonard.options.workspace.trigger(eventMousemove)


# Begining of the tests
#
it 'has a zonar object', ->
  expect(BlockView).to.be.a 'function'

it 'has a transform polyfill', ->
  expect(transformName).to.have.string 'ransform'
describe 'zonard', ->

  beforeEach ->
    @nyan = new Block nyan
    @workspace = document.createElement 'div'
    document.body.appendChild @workspace
    @workspace.style.height = '800px'
    @workspace.style.width = '600px'
    @workspace.style.position = 'relative'
    @blockView = new BlockView
      workspace: $ @workspace
      model: @nyan
    @el = @blockView.render().el
    @$el = $(@el)
    $(@workspace).append(@el)

  afterEach ->
    $(@workspace).remove()
  it 'is an el with a "zonard" class name', ->
    expect(@$el.hasClass('zonard')).to.be.ok

  it 'is positioned at 300 from the top', ->
    expect(@el.style.top).to.equal '300px'
    expect(@blockView.$el.position().top).to.equal 300

  it 'is rotated with an angle of -45 deg', ->
    expect(
      @blockView.contains.el.style[transformName]
    ).to.equal 'rotate(-45deg)'

  describe 'when dragging north west handle', ->
    beforeEach ->
      # preparing a spy to intercept the desired event
      @spyHandleAction = sinon.spy()
      @blockView.on 'change:resize', @spyHandleAction
      # triggering the drag
      # simulating a displacement of (100, -150)
      triggerDragOn(@blockView, '.handle.ord-nw', {pageX: 200, pageY: 150})

    it 'emits a resize event', ->
      expect(@spyHandleAction.called).to.be.true

  describe 'when dragging south dragbar', ->
    beforeEach ->
      @spyDragbarAction = sinon.spy()
      @blockView.on 'change:resize', @spyDragbarAction
      triggerDragOn(@blockView, '.dragbar.ord-s', {pageX: 200, pageY: 150})

    it 'emits a resize event', ->
      expect(@spyDragbarAction.called).to.be.true

  describe 'when dragging the rotation handler', ->
    beforeEach ->
      @spyHandleRotation = sinon.spy()
      @blockView.on 'change:rotate', @spyHandleRotation
      triggerDragOn(@blockView, '.handleRotation', {pageX: 200, pageY: 150})

### WORK IN PROGESS
    it 'rotates itself correctly', ->
      elPos = @blockView.$el.position()
      matrix = @blockView.contains.$el.css('transform')
      #console.log(matrix)
      #console.log(sign)
      #sign = matrix[1] / Math.abs(matrix[1]) || 1
      #console.log(sign * Math.acos(matrix[0]))

    it 'emits a rotate event', ->
      expect(@spyHandleRotation.called).to.be.true
###

  describe 'when dragging the tracker (zone inside the handles)', ->
    beforeEach ->
      @spyTrackerAction = sinon.spy()
      @blockView.on 'change:move', @spyTrackerAction
      triggerDragOn(@blockView, '.tracker', {pageX: 200, pageY: 150})

    it 'moves itself to the desired position', ->
      expect($(@el).css('left')).to.equal('200px')
      expect($(@el).css('top')).to.equal('150px')
    it 'emits a move event', ->
      expect(@spyTrackerAction.called).to.be.true
