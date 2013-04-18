# BlockView
class @BlockView extends Backbone.View
  
  initialize: ->
    @page = @options.page
    @$page = $(@page)


    #predefining a style for the el, adapted to the image for
    #the moment
    @$el.css(
      position: "absolute",
      "z-index": 600,
      width: "256px",
      # 175 + 25px for the rotation handler
      height: "200px",
      top: "116px",
      left: "166px"
    )


    @render()

  render: ->
    # global subcontainer to which rotations will be applied
    @$selectR = $('<div></div>',{
      style:"width: 100%; height: 100%; z-index: 600; position: absolute;"
    })
    @selectR = @$selectR[0]
    @$el.append(@selectR)

    # dCt : display container that holds the content and the borders of the content
    @$dCt = $('<div></div>',{
      style:"width: 100%; height: 175px; z-index: 310; position: absolute; overflow: hidden; bottom:0px;"
    })
    @dCt = @$dCt[0]
    @$selectR.append(@dCt)

    # the content that we display
    @$content = $('<img>',{
      src: "assets/images/cat.jpg",
      style:"border: none; visibility: visible; margin: 0px; padding: 0px; position: absolute; top: 0px; left: 0px; width: 256px; height: 175px;"
    })
    @content = @$content[0]
    @$dCt.append(@content)

    # the borders are the line that are displayed around the countent
    @$borders = []
    @borders = []

    for st in ["jcrop-hline", "jcrop-hline bottom", "jcrop-vline", "jcrop-vline right"]
      e = $('<div></div>',{
        style:"position:absolute; opacity:0.4;"
      })
      e.addClass(st)
      @$borders.push(e)
      @borders.push(e[0])

    for e of @borders
      @$dCt.append(@borders[e])

    @$page.append(@el)






