# init of the app, fetch the image, draw the canvas
# dependencies:
# jquery
# underscore
# backbone

cat =
  src: "assets/images/cat.jpg"
  height: 200
  width: 300
  top: 100
  left: 24
  rotate: 30
  
nyan =
  src: "assets/images/nyan.png"
  height: 100
  width: 130
  top: 300
  left: 400
  rotate: -45
  
class Blocks extends Backbone.Collection
  models: Block

class CloneImageView extends CloneView
  tagName: 'img'
  render: ->
    @$el.attr src: @model.get 'src'
    @


class Workspace extends Backbone.View

  initialize: ->
    @listenTo @collection, 'add', @addBlock

  addBlock: (block)=>
    blockView = new BlockView
      workspace: @$el
      model: block
    c = new CloneImageView model: block, cloning: blockView
    @$el.append c.render().el
    @$el.append blockView.render().el


@onload = ->
  blocks = new Blocks
  workspace = new Workspace
    el: $("#page")[0]
    collection: blocks
  blocks.add new Block cat
  blocks.add new Block nyan
