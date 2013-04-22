# init of the app, fetch the image, draw the canvas
# dependencies:
# jquery
# underscore
# backbone

@onload = ->

  @page = $("#page")[0]

  @img = new Image
  @img.src = "assets/images/cat.jpg"
  @img.onload = =>
    @init(@page, @img)

@init = (page, img)->
  @block = new @Block img: img
  @blockView = new @BlockView model: @block, page: @page
