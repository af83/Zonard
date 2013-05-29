class Block extends Backbone.Model

# set of parameters to initialize a model, necessary
# to instanciate a Zonard
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
@readMatrix = (transformString)->
  matrixPattern = /^\w*\((((\d+)|(\d*\.\d+)),\s*)*((\d+)|(\d*\.\d+))\)/i
  matrixValue = []
  if(matrixPattern.test(transformString))
    matrixCopy = matrix.replace(/^\w*\(/, '').replace(')', '')
    matrixValue = matrixCopy.split(/\s*,\s*/)


# function that triggers a drag event from an element
# (specified by the className) of the selected zonard
# will simulate a displacement of the mouse of given
# vector
@triggerDragOn = (zonard, className, vector) =>
  # dom element on which to apply mousedown
  h = $(zonard.el).find(className)
  # getting the workspace offset, to place the displacement vector correctly
  offset = zonard.$workspace.offset()
  # preparing artificial dom events for mousedown & mousemove
  eventMousedown = new $.Event 'mousedown',
    pageX: offset.left + 300
    pageY: offset.top  + 300
  eventMousemove = new $.Event 'mousemove',
    pageX: offset.left + vector.x
    pageY: offset.top  + vector.y
  h.trigger(eventMousedown)
  zonard.$workspace.trigger(eventMousemove)


# Begining of the tests
#
it 'has a zonar object', ->
  expect(Zonard).to.be.a 'function'

it 'has a transform polyfill', ->
  expect(transformName).to.have.string 'ransform'
describe 'zonard', ->

  beforeEach ->
    @nyan = new Block nyan
    @workspace = document.createElement 'div'
    @workspace.style['background-color'] = 'red'
    document.body.appendChild @workspace
    @workspace.style.height = '800px'
    @workspace.style.width = '600px'
    @workspace.style.position = 'relative'
    @blockView = new Zonard
      workspace: @workspace
      model: @nyan
    @el = @blockView.render().el
    @$el = $(@el)
    $(@workspace).append(@el)

  afterEach ->
    $(@workspace).remove()

  it 'is an el with a "zonard" class name', ->
    expect(@$el.hasClass('zonard')).to.be.ok

  it 'is positioned at 300 from the top', ->
    expect(@blockView.$el.position().top).to.equal 300

  it 'is rotated with an angle of -45 deg', ->
    expect(
      @blockView.rotationContainer.el.style[transformName]
    ).to.equal 'rotate(-45deg)'

  describe 'when dragging north west handle', ->
    beforeEach ->
      @blockView.listenToDragStart()
      # preparing a spy to intercept the desired event
      @spyHandleAction = sinon.spy()
      @blockView.on 'change:resize', @spyHandleAction
      # triggering the drag
      # simulating a displacement of (100, -150)
      triggerDragOn @blockView, '.handle.ord-nw',
        x: 200
        y: 150

    it 'emits a resize event', ->
      expect(@spyHandleAction.called).to.be.true

  describe 'when dragging south dragbar', ->
    beforeEach ->
      @blockView.listenToDragStart()
      @spyDragbarAction = sinon.spy()
      @blockView.on 'change:resize', @spyDragbarAction
      triggerDragOn(@blockView, '.dragbar.ord-s', {x: 200, y: 150})

    it 'emits a resize event', ->
      expect(@spyDragbarAction.called).to.be.true

  describe 'when dragging the rotation handler', ->
    beforeEach ->
      @blockView.listenToDragStart()
      @spyHandleRotation = sinon.spy()
      @blockView.on 'change:rotate', @spyHandleRotation
      triggerDragOn @blockView, '.handleRotation',
        x: 200
        y: 150

    afterEach ->

    it 'rotates itself correctly', ->
      # desired accuracy for the test
      accuracy = 1e-5

      matrix = @blockView.rotationContainer.$el.css('transform')
      tab = matrix.substr(7, matrix.length-8).split(', ')

      cos = parseFloat tab[0]
      expect(cos).to.be.closeTo 0.486172, accuracy

      sin = parseFloat tab[1]
      expect(sin).to.be.closeTo -0.873862, accuracy

    it 'emits a rotate event', ->
      expect(@spyHandleRotation.called).to.be.true

  describe 'when dragging the tracker (zone inside the handles)', ->
    beforeEach ->
      @blockView.listenToDragStart()
      @spyTrackerAction = sinon.spy()
      @blockView.on 'change:move', @spyTrackerAction
      triggerDragOn @blockView, '.tracker',
        x: 200
        y: 150

    it 'moves itself to the desired position', ->
      expect($(@el).css('left')).to.equal('200px')
      expect($(@el).css('top')).to.equal('150px')
    it 'emits a move event', ->
      expect(@spyTrackerAction.called).to.be.true

  describe 'when dragging the tracker and not listening', ->
    beforeEach ->
      @spyTrackerAction = sinon.spy()
      @blockView.on 'change:move', @spyTrackerAction
      triggerDragOn @blockView, '.tracker',
        x: 200
        y: 150

    it 'doesnt moves', ->
      expect($(@el).css('left')).to.equal(nyan.left+'px')
      expect($(@el).css('top')).to.equal(nyan.top+'px')

    it 'doesnt emits move event', ->
      expect(@spyTrackerAction.called).to.be.false

  describe 'when hiding', ->
    beforeEach ->
      @blockView.toggle off

    it 'elements block are not display', ->
      @blockView.$('.displayContainer, .dragbar, .handle, .handleRotation').each ->
        expect($(@).css 'display').to.eql 'none'

    describe 'when showing', ->
      beforeEach ->
        @blockView.toggle on

      it 'elements block are display', ->
        @blockView.$('.displayContainer, .dragbar, .handle, .handleRotation').each ->
          expect($(@).css 'display').to.eql 'block'

  describe 'when click', ->
    beforeEach ->
      @spyFocus = sinon.spy()
      @blockView.listenFocus().on 'focus', @spyFocus
      @blockView.$('.tracker').click()

    it 'notify focus', ->
      expect(@spyFocus.called).to.be.true
