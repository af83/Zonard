# init of the app, fetch the image, draw the canvas
# dependencies:
# jquery
# underscore
# backbone

dummy =
  src: "assets/images/cat.jpg"
  height: 200
  width: 300
  top: 100
  left: 24
  rotate: 30
  
  
class Blocks extends Backbone.Collection
  models: Block

class BlockImageView extends Backbone.View
  tagName: 'img'
  render: ->
    @el.src = @model.get 'src'
    @$el.css
      height: @model.get 'height'
      width: @model.get 'width'


class Workspace extends Backbone.View

  initialize: ->
    @listenTo @collection, 'add', @addBlock

  addBlock: (block)=>
    b = new BlockImageView model: block
    @$el.append b.render().el
    blockView = new BlockView
      workspace: @$el
      model: block
    @$el.append blockView.render().el
    blockView.on 'change:resize', (data)->
      console.log 'resize', data
    blockView.on 'end:resize', ->
      console.log 'end:resize'
    blockView.on 'start:resize', ->
      console.log 'start:resize'

    blockView.on 'change:rotate', (data)->
      console.log 'rotate', data
    blockView.on 'start:rotate', ->
      console.log 'start:rotate'
    blockView.on 'end:rotate', ->
      console.log 'end:rotate'

    blockView.on 'change:move', (data)->
      console.log 'move', data
    blockView.on 'start:move', ->
      console.log 'start:move'
    blockView.on 'end:move', ->
      console.log 'end:move'
    

@onload = ->
  blocks = new Blocks
  workspace = new Workspace
    el: $("#page")[0]
    collection: blocks
  blocks.add new Block dummy
