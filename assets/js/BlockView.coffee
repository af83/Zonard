# BlockView
class @BlockView extends Backbone.View
  
  events:
    'mousedown .tracker' : 'handlerDispatcher'
    'mousedown .handleR' : 'handlerDispatcher'
    'mousedown .dragbar' : 'handlerDispatcher'
    'mousedown .handle' : 'handlerDispatcher'

  initialize: ->
    @page = @options.page
    @$page = $(@page)

    # We check what the rotation transformation name is
    # in the browser
    @transformName = null
    for b in ['transform', 'webkitTransform', "MozTransform", 'msTransform', "OTransform"] when @el.style[b]?
      @transformName = b


    #predefining a style for the el, adapted to the image for
    #the moment
    @$el.css(
      position: 'absolute',
      'z-index': 600,
      width: '256px',
      # 175 + 25px for the rotation handler
      height: '175px',
      top: '116px',
      left: '166px'
    )
    @render()

  handlerDispatcher: (e) ->
    origine =
      x: e.pageX
      y: e.pageY

    #if $(e.currentTarget).hasClass('tracker')

    if $(e.currentTarget).hasClass('handleR')
      offset = @$el.offset()
      center =
        x: offset.left + @$el.width()/2
        y: offset.top  + @$el.height()/2 # dh=25px
      console.log(center)
      @$page.on('mouseup', center, @endRotate)
      @$page.on('mouseleave', center, @endRotate)
      return @$page.on('mousemove', center, @rotate)

    #if $(e.currentTarget).hasClass('dragbar')

    #if $(e.currentTarget).hasClass('handle')

  # NB: here we need to bind, because we haven't use the delegate
  # event method of backbone...
  move: (e)=>
    v =
      x:e.pageX - e.data.x
      y:e.pageY - e.data.y

  endmove: (e)=>
    @$page.off('mouseup',@endmove)
    @$page.off('mouseleave',@endmove)
    @$page.off('mousemove',@move)

  rotate: (e)=>
    # v is the vector from the center of the content to
    # the pointer of the mouse
    v =
      x:e.pageX - e.data.x
      y:e.pageY - e.data.y
    #norm of v
    n = Math.sqrt(v.x*v.x + v.y*v.y)
    # vn is v normalized
    vn =
      x: v.x/n
      y: v.y/n
    # "sign" is the sign of v.x
    sign = v.x/Math.abs(v.x)
    # beta is the angle between v and the vector (0,-1)
    beta = (Math.asin(vn.y) + Math.PI/2) * sign
    betaDeg = beta * 360 /(2*Math.PI)
    # preparing and changing css
    style = {}
    style[@transformName] = "rotate(#{betaDeg}deg)"
    @$selectR.css(style)

  endRotate:=>
    @$page.off('mouseup',@endRotate)
    @$page.off('mouseleave',@endRotate)
    @$page.off('mousemove',@rotate)

  render: ->
    #cardinals that will be used throughout the rendering (maybe in other
    # functions too?)
    cards = ['n', 's', 'e', 'w', 'nw', 'ne', 'se', 'sw']
    # global subcontainer to which rotations will be applied
    @$selectR = $('<div></div>',{
      style:'width: 100%; height: 100%; z-index: 600; position: absolute;'
    })
    @selectR = @$selectR[0]
    @$el.append(@selectR)

    # dCt : display container that holds the content and the borders of the
    # content
    @$dCt = $('<div></div>',{
      style:'width: 100%; height: 100%; z-index: 310; position: absolute; overflow: hidden; bottom:0px;'
    })
    @dCt = @$dCt[0]
    @$selectR.append(@dCt)

    # the content that we display
    @$content = $('<img>',{
      src: 'assets/images/cat.jpg',
      style:'border: none; visibility: visible; margin: 0px; padding: 0px; position: absolute; top: 0px; left: 0px; width: 100%; height: 100%;'
    })
    @content = @$content[0]
    @$dCt.append(@content)

    # the borders are the line that are displayed around the countent
    @$borders = []
    @borders = []

    for str, i in ['jcrop-hline', 'jcrop-hline bottom', 'jcrop-vline', 'jcrop-vline right']
      e = $('<div></div>',{
        style:'position:absolute; opacity:0.4;'
      })
      e.addClass(str)
      @$borders.push(e)
      @borders.push(e[0])

    for e of @borders
      @$dCt.append(@borders[e])

        #
    # hCt: Handler container that will hold all the handlers
    #
    @$hCt = $('<div></div>',{
      style:'width: 100%; height: 100%; bottom: 0px; position: absolute; z-index: 320; display: block;'
    })
    @hCt = @$hCt[0]
    @$selectR.append(@hCt)


    # create the dragbars
    @dragbars = []
    @$dragbars = []
    for str, i in cards.slice(0, 4)
      e = $('<div></div>',{
        style:'position:absolute;'
      })
      style = {}
      style.cursor = str + '-resize'
      style['z-index'] = 370 + i
      className = 'ord-' + str + ' jcrop-dragbar'
      e.css(style)
      e.addClass(className)
      e.addClass('dragbar')
      @$dragbars.push(e)
      @dragbars.push(e[0])

    for e of @dragbars
      @$hCt.append(@dragbars[e])

    # create the handles
    @handles = []
    @$handles = []
    for str, i in cards
      e = $('<div></div>',{
        style:'position:absolute;'
      })
      style = {}
      style.cursor = str + '-resize'
      style['z-index'] = 374 + i
      className = 'ord-' + str + ' jcrop-handle'
      e.css(style)
      e.addClass(className)
      e.addClass('handle')
      @$handles.push(e)
      @handles.push(e[0])

    for e of @handles
      @$hCt.append(@handles[e])

    # the special handler responsible for the rotation
    @$handleR = $('<div></div>',{
      style:'position:absolute; margin-left: -4px; margin-top: -4px; left: 50%; top:-25px; cursor:url(assets/images/rotate.png) 12 12, auto; z-index:382;'
    })
    @$handleR.addClass('jcrop-handle')
    @$handleR.addClass('handleR')
    @handleR = @$handleR[0]

    @$hCt.append(@handleR)

    #This element is here to receive mouse events (clicks)
    @$tracker = $('<div></div>',{
      style:'cursor: move; position: absolute; z-index: 360;'
    })
    # ADD A CROSS COMPATIBLE CSS PROPERTY TO MAKE IT UNSELECTABLE
    @$tracker.css({'-webkit-user-select':'none'})
    @$tracker.addClass('jcrop-tracker')
    @$tracker.addClass('tracker')
    @tracker = @$tracker[0]
    @$hCt.append(@tracker)



    # we finally attach the Block element to the page
    @$page.append(@el)








