# init of the app, fetch the image, draw the canvas
# dependencies:
# jquery
# underscore
# backbone

cat =
  type: 'image'
  src: "assets/images/cat.jpg"
  height: 200
  width: 300
  top: 100
  left: 24
  rotate: 30
  
nyan =
  type: 'image'
  src: "assets/images/nyan.png"
  height: 100
  width: 130
  top: 300
  left: 400
  rotate: -45

lorem =
  type: 'texte'
  content: """Lorem ipsum dolor sit amet, consectetur adipiscing elit. In elementum, nisi eu scelerisque facilisis, urna ligula interdum nulla, hendrerit dignissim elit dui nec justo. Duis erat dolor, mollis vitae tincidunt in, consectetur ut mi. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pellentesque cursus odio imperdiet iaculis. Nam iaculis sollicitudin semper. Donec vitae tempus elit. Donec ornare fermentum magna, lacinia euismod odio vestibulum sit amet. Integer quis tortor eget est scelerisque commodo. Nulla commodo erat et mi tincidunt at hendrerit urna aliquet. Suspendisse ultrices, enim nec ornare varius, tellus enim vestibulum purus, ut tempus sapien risus a eros. Cras mattis placerat nisi non euismod. Donec urna ante, porttitor quis ornare id, posuere sit amet neque. In libero felis, ultrices non volutpat at, gravida et velit. Cras id lacus justo, gravida tristique purus. Donec ligula augue, gravida eu gravida pharetra, adipiscing id arcu."""
  height: 100
  width: 130
  top: 300
  left: 400
  rotate: -45
  
class Blocks extends Backbone.Collection
  models: Block


class CloneImageView extends CloneView
  tagName: 'canvas'
  initialize: ->
    super()
    @el.setAttribute 'height', @model.get 'height'
    @el.setAttribute 'width', @model.get 'width'
    @img = new Image
    @img.onload = @draw
    @img.src = @model.get 'src'
    @context = @el.getContext '2d'

  draw: =>
    super()
    @el.setAttribute 'height', @model.get 'height'
    @el.setAttribute 'width', @model.get 'width'
    @context.drawImage @img, 0, 0, @model.get('width'), @model.get('height')


class CloneTextView extends CloneView
  tagName: 'div'
  render: ->
    @$el.text @model.get 'content'
    @


class Workspace extends Backbone.View

  initialize: ->
    @listenTo @collection, 'add', @addBlock
    @selected = null

  addBlock: (block)=>
    c = switch block.get 'type'
      when 'image'
        new CloneImageView model: block
      when 'texte'
        new CloneTextView model: block
    @$el.append c.render().el
    block.cacheState().saveState()
    @select c
    c.on 'select', => @select c

  select: (clone)->
    @selected?.stopListenToZonard().zonard.$el.remove() # @fixme leak.
    @selected?.selectable on
    zonard = new BlockView model: clone.model, workspace: @$el
    @$el.append zonard.render().el
    @selected = clone.listenToZonard(zonard)
    @selected.selectable off

  levelDown: ->
    @selected.$el.prev('.clone')?.before @selected.$el

  levelUp: ->
    @selected.$el.next('.clone')?.after @selected.$el



class ActionStack
  constructor: ->
    @stack = []
    @current = -1

  save: (model, state)=>
    @stack[++@current..] = model: model, state: state
    
  undo: =>
    if @current > 0
      item = @stack[@current]
      item.model.set item.state.before
      @current--

  redo: =>
    if @current < @stack.length - 1
      item = @stack[++@current]
      item.model.set item.state.after

@onload = ->
  blocks = new Blocks
  stack = new ActionStack


  blocks.on 'stack', stack.save
  $('#undo').on 'click', (event)->
    event.preventDefault()
    stack.undo()
  $('#redo').on 'click', (event)->
    event.preventDefault()
    stack.redo()
  
  $('#levelUp').on 'click', (event)->
    event.preventDefault()
    workspace.levelUp()
  $('#levelDown').on 'click', (event)->
    event.preventDefault()
    workspace.levelDown()

  workspace = new Workspace
    el: $("#page")[0]
    collection: blocks
  blocks.add new Block cat
  blocks.add new Block nyan
  blocks.add new Block lorem
