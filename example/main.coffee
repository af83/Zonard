# init of the app, fetch the image, draw the canvas
# dependencies:
# jquery
# underscore
# backbone

cat =
  type: 'image'
  src: "../assets/images/cat.jpg"
  height:100
  width: 200
  top: 300
  left: 300
  rotate: -45

nyan =
  type: 'image'
  src: "../assets/images/nyan.png"
  height: 100
  width: 200
  top: 300
  left: 300
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
  tagName: 'img'
  render: ->
    @$el.attr src: @model.get 'src'
    @
class CloneTextView extends CloneView
  tagName: 'div'
  render: ->
    @$el.text @model.get 'content'
    @


class Workspace extends Backbone.View

  initialize: ->
    @listenTo @collection, 'add', @addBlock

  addBlock: (block)=>
    blockView = new BlockView
      workspace: @$el
      model: block
    c = switch block.get 'type'
      when 'image'
        new CloneImageView model: block, cloning: blockView
      when 'texte'
        new CloneTextView model: block, cloning: blockView
    @$el.append c.render().el
    @$el.append blockView.render().el


@onload = ->
  blocks = new Blocks
  workspace = new Workspace
    el: $("#page")[0]
    collection: blocks
  #blocks.add new Block cat
  blocks.add new Block nyan
  #blocks.add new Block lorem
