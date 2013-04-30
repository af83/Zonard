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

# function that triggers a drag event from an element
# (specified by the className) of the selected zonard
# will simulate a (-100, -150) displacement of the mouse
@triggerDragOn = (zonard, className) =>
  # dom element on which to apply mousedown
  h = $(zonard.el).find(className)
  # preparing artificial dom events for mousedown & mousemove
  eventMousedown = new $.Event 'mousedown', {pageX: 300, pageY: 300}
  eventMousemove = new $.Event 'mousemove', {pageX: 200, pageY: 150}
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
    @blockView = new BlockView
      workspace: $ @workspace
      model: @nyan
    @el = @blockView.render().el

  it 'is an el with a "zonard" class name', ->
    expect(@el.classList.contains('zonard')).to.be.ok

  it 'is positioned at 300 from the top', ->
    expect(@el.style.top).to.equal '300px'

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
      triggerDragOn(@blockView, '.handle.ord-nw')

    it 'emits a resize event', ->
      expect(@spyHandleAction.called).to.be.true

  describe 'when dragging south dragbar', ->
    beforeEach ->
      @spyDragbarAction = sinon.spy()
      @blockView.on 'change:resize', @spyDragbarAction
      triggerDragOn(@blockView, '.dragbar.ord-s')

    it 'emits a resize event', ->
      expect(@spyDragbarAction.called).to.be.true

  describe 'when dragging the rotation handler', ->
    beforeEach ->
      @spyHandleRotation = sinon.spy()
      @blockView.on 'change:rotate', @spyHandleRotation
      triggerDragOn(@blockView, '.handleRotation')

    it 'emits a rotate event', ->
      expect(@spyHandleRotation.called).to.be.true

  describe 'when dragging the tracker (zone inside the handles)', ->
    beforeEach ->
      @spyTrackerAction = sinon.spy()
      @blockView.on 'change:move', @spyTrackerAction
      triggerDragOn(@blockView, '.tracker')

    it 'emits a move event', ->
      expect(@spyTrackerAction.called).to.be.true
