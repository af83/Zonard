class Block extends Backbone.Model

# set of parameters to initialize a model, necessary
# to instanciate a Zonard
nyan =
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
    @workspace = document.createElement 'div'
    @workspace.style['background-color'] = 'red'
    document.body.appendChild @workspace
    @workspace.style.height = '800px'
    @workspace.style.width = '600px'
    @workspace.style.position = 'relative'

  afterEach ->
    $(@workspace).remove()

  describe 'when instanciated with the preserveRatio option', ->
    beforeEach ->
      @blockView = new Zonard
        workspace: @workspace
        box: _.extend({},nyan)
        preserveRatio: on
      @el = @blockView.render().el
      @$el = $(@el)
      $(@workspace).append(@el)

    it 'hides the the dragbars and the n e s w handles', ->
      sel = @blockView.$('.zonard-handle').filter ->
        @className.match /ord-[nsew]$/
      .add @blockView.$ '.zonard-dragbar'
      sel.each ->
        expect($(@).css('display')).to.equal 'none'


  describe 'when instanciated without central Handle', ->
    beforeEach ->
      @blockView = new Zonard
        workspace: @workspace
        box: _.extend({},nyan)
      @el = @blockView.render().el
      @$el = $(@el)
      $(@workspace).append(@el)

    it 'doesn\' have a central handle element', ->
      expect(@blockView.$('.central').length).to.eql 0

  describe 'when instanciated with a central Handle', ->
    beforeEach ->
      @nyan = new Block nyan
      @blockView = new Zonard
        workspace: @workspace
        box: _.extend {}, nyan
        centralHandle: true
      @el = @blockView.render().el
      @$el = $(@el)
      $(@workspace).append(@el)

    it 'is an el with a "zonard" class name', ->
      expect(@$el.hasClass('zonard')).to.be.ok

    it 'is positioned at 300 from the top', ->
      expect(@blockView.$el.css("top")).to.equal "300px"

    it 'is rotated with an angle of -45 deg', ->
      expect(
        @blockView.el.style[transformName]
      ).to.equal 'rotate(-45deg)'

    it 'has a central handle element', ->
      expect(@blockView.$('.central').length).to.eql 1

    describe 'when dragging north west handle', ->
      beforeEach ->
        @blockView.listenToDragStart()
        # preparing a spy to intercept the desired event
        @spyStart = sinon.spy()
        @spyHandleAction = sinon.spy()
        @blockView.on 'start:resize', @spyStart
        @blockView.on 'change:resize', @spyHandleAction
        # triggering the drag
        # simulating a displacement of (100, -150)
        triggerDragOn @blockView, '.zonard-handle.ord-nw',
          x: 200
          y: 150

      it 'emits a resize event', ->
        expect(@spyStart.calledOnce).to.be.true
        expect(@spyHandleAction.calledOnce).to.be.true

    describe 'when dragging south dragbar', ->
      beforeEach ->
        @blockView.listenToDragStart()
        @spyStart = sinon.spy()
        @spyDragbarAction = sinon.spy()
        @blockView.on 'start:resize', @spyStart
        @blockView.on 'change:resize', @spyDragbarAction
        triggerDragOn(@blockView, '.zonard-dragbar.ord-s', {x: 200, y: 150})

      it 'emits a resize event', ->
        expect(@spyStart.calledOnce).to.be.true
        expect(@spyDragbarAction.called).to.be.true

    describe 'when dragging the rotation handler', ->
      beforeEach ->
        @blockView.listenToDragStart()
        @spyStart = sinon.spy()
        @spyHandleRotation = sinon.spy()
        @blockView.on 'start:rotate', @spyStart
        @blockView.on 'change:rotate', @spyHandleRotation
        triggerDragOn @blockView, '.zonard-handleRotation',
          x: 200
          y: 150

      it 'emits a rotate event', ->
        expect(@spyStart.calledOnce).to.be.true
        expect(@spyHandleRotation.called).to.be.true

      it 'rotates itself correctly', ->
        # desired accuracy for the test
        accuracy = 1e-5

        matrix = @blockView.$el.css('transform')
        tab = matrix.substr(7, matrix.length-8).split(', ')

        cos = parseFloat tab[0]
        expect(cos).to.be.closeTo 0.486172, accuracy

        sin = parseFloat tab[1]
        expect(sin).to.be.closeTo -0.873862, accuracy


    describe 'when dragging the tracker (zone inside the handles)', ->

      beforeEach ->
        @blockView.listenToDragStart()
        @spyTrackerAction = sinon.spy()
        @blockView.on 'change:move', @spyTrackerAction
        triggerDragOn @blockView, '.zonard-tracker',
          x: 200
          y: 150

      it 'emits a move event', ->
        expect(@spyTrackerAction.called).to.be.true

      it 'moves itself to the desired position', ->
        expect($(@el).css('left')).to.equal('200px')
        expect($(@el).css('top')).to.equal('150px')


    describe 'when dragging the centralHandle', ->

      beforeEach ->
        @blockView.listenToDragStart()
        @spyStart = sinon.spy()
        @spyCentralDrag = sinon.spy()
        @blockView.on 'start:centralDrag', @spyStart
        @blockView.on 'info:centralDrag', @spyCentralDrag
        triggerDragOn @blockView, '.central',
          x: 200
          y: 150

      it 'emits an info event', ->
        expect(@spyStart.called).to.be.true
        expect(@spyCentralDrag.called).to.be.true

      it 'the data sent with the event is correct', ->
        # desired accuracy for the test
        accuracy = 1

        data = @spyCentralDrag.args[0][0]
        expect(data.mouseLocal.x).to.be.closeTo 35, accuracy
        expect(data.mouseLocal.y).to.be.closeTo -177, accuracy

    describe 'when dragging the tracker and not listening', ->
      beforeEach ->
        @spyStart = sinon.spy()
        @spyTrackerAction = sinon.spy()
        @blockView.on 'start:move', @spyStart
        @blockView.on 'change:move', @spyTrackerAction
        triggerDragOn @blockView, '.zonard-tracker',
          x: 200
          y: 150

      it 'doesnt emits move event', ->
        expect(@spyStart.called).to.be.false
        expect(@spyTrackerAction.called).to.be.false

      it 'doesnt moves', ->
        expect($(@el).css('left')).to.equal(nyan.left+'px')
        expect($(@el).css('top')).to.equal(nyan.top+'px')

    describe 'when hiding', ->
      beforeEach ->
        @blockView.toggle off

      it 'elements block are not display', ->
        @blockView.$('.zonard-displayContainer, .zonard-dragbar, .zonard-handle, .zonard-handleRotation').each ->
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
        @blockView.$('.zonard-tracker').click()

      it 'notify focus', ->
        expect(@spyFocus.called).to.be.true
