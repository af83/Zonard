# Vector Helper
V =
  eventDir: (event)->
    x: event.pageX - event.data.x
    y: event.pageY - event.data.y

  norm: (vector)->
    Math.sqrt vector.x * vector.x + vector.y * vector.y

  normalized: (vector)->
    norm = @norm vector
    x: vector.x / norm
    y: vector.y / norm

  signedDir: (vector, comp)->
    vector[comp] / Math.abs(vector[comp])

# BlockView
class @BlockView extends Backbone.View
  
  events:
    'mousedown .tracker' : 'beginMove'
    'mousedown .handleR' : 'beginRotate'
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
    @$el.css
      position: 'absolute'
      'z-index': 600
      width: '256px'
      # 175 + 25px for the rotation handler
      height: '175px'
      top: '116px'
      left: '166px'
    @render()

  #
  # Drag'n'Drop of the block
  #
  beginMove: (e)=>
    # passing a lot of data, for not having to look it
    # up inside the handler
    cr = @selectR.getBoundingClientRect()
    data =
      # the origin of the mouseon
      origin :
        x: e.pageX
        y: e.pageY
        # the initial position of @el
      initialPosition : @$el.position()
      bounds:
        ox: (cr.width - @$el.width()) / 2
        oy: (cr.height - @$el.height()) / 2
        x: @$page.width() - (cr.width / 2 + @$el.width() / 2)
        y: @$page.height() - (cr.height / 2 + @$el.height() / 2)
      # are the 2 following events even possible considering
      # we are 'on' the image? hum....
    $(document).on 'mouseup', @endMove
    $(document).on 'mouseleave', @endMove
    @$page.on 'mousemove', data, @move

  # @chainable
  move: (event)=>
    bounds = event.data.bounds
    vector =
      x: event.pageX - event.data.origin.x
      y: event.pageY - event.data.origin.y
    pos =
      left: vector.x + event.data.initialPosition.left
      top: vector.y + event.data.initialPosition.top
    if pos.left < bounds.ox then pos.left = bounds.ox
    else if pos.left > bounds.x then pos.left = bounds.x

    if pos.top < bounds.oy then pos.top = bounds.oy
    else if pos.top > bounds.y then pos.top = bounds.y
    @$el.css(pos)
    @

  # @todo events are on document
  endMove: (event)=>
    @$page
      .off('mouseup', @endMove)
      .off('mouseleave', @endMove)
      .off('mousemove', @move)

  #
  # Rotation of the selectR subcontainer
  #
  beginRotate: =>
    offset = @$el.offset()
    center =
      x: offset.left + @$el.width() / 2
      y: offset.top  + @$el.height() / 2
    $(document).on('mouseup', @endRotate)
    $(document).on('mouseleave', @endRotate)
    @$page.on('mousemove', center, @rotate)

  rotate: (event)=>
    # v is the vector from the center of the content to
    # the pointer of the mouse
    vector = V.eventDir event
    # vn is v normalized
    normalized = V.normalized vector
    # "sign" is the sign of v.x
    sign = V.signedDir vector, 'x'
    # beta is the angle between v and the vector (0,-1)
    beta = (Math.asin(normalized.y) + Math.PI / 2) * sign
    betaDeg = beta * 360 / (2 * Math.PI)
    # preparing and changing css
    @$selectR.css @transformName, "rotate(#{betaDeg}deg)"

  # @todo event were attach on document
  endRotate:=>
    @$page
      .off('mouseup', @endRotate)
      .off('mouseleave', @endRotate)
      .off('mousemove', @rotate)

  cards: ['n', 's', 'e', 'w', 'nw', 'ne', 'se', 'sw']

  # we build a coefficient table, wich indicates the modication
  # pattern corresponding to each cardinal
  # pattern: [left,top,width,height]
  coefs:
    n:  [0, 1,  0, -1]
    s:  [0, 0,  0,  1]
    e:  [0, 0,  1,  0]
    w:  [1, 0, -1,  0]
    nw: [1, 1, -1, -1]
    ne: [0, 1,  1, -1]
    se: [0, 0,  1,  1]
    sw: [1, 0, -1,  1]

  #
  # Dispatch events from dragbars and handles
  # For now this just does a resize
  # @todo rewrite event handling on draggable event.
  #
  handlerDispatcher: (event)=>
    $target = $ event.currentTarget

    # @todo should be remove on next code rework
    re = /ord\-([nsew]{1,2})/
    dir = (re.exec $target[0].className)[1]

    data =
      # the origin of the mouseon
      origin :
        x: event.pageX
        y: event.pageY
        # the initial position of @el
      initialPosition : @$el.position()
      initialDimension:
        width: @$el.width()
        height: @$el.height()
      # if isESES, we only change dimensions
      # else, we change dimensionis and position of the el
      coef: @coefs[dir]

    $(document).on('mouseup', @endResize)
    $(document).on('mouseleave', @endResize)
    @$page.on('mousemove', data, @resize)

  resize: (event)=>
    bounds = event.data.bounds
    coef = event.data.coef
    vector =
      x: event.pageX - event.data.origin.x
      y: event.pageY - event.data.origin.y

    style =
      left :  coef[0] * vector.x + event.data.initialPosition.left
      top :   coef[1] * vector.y + event.data.initialPosition.top
      width:  coef[2] * vector.x + event.data.initialDimension.width
      height: coef[3] * vector.y + event.data.initialDimension.height

    @$el.css(style)
    ### WIP
    if pos.left < bounds.ox then pos.left = bounds.ox
    else if pos.left > bounds.x then pos.left = bounds.x

    if pos.top < bounds.oy then pos.top = bounds.oy
    else if pos.top > bounds.y then pos.top = bounds.y
    ###

  endResize: (event)=>
    $(document).off('mouseup', @endResize)
    $(document).off('mouseleave', @endResize)
    @$page.off('mousemove', @resize)

  #
  # render create all the dom elements and append them
  #
  render: ->
    # global subcontainer to which rotations will be applied
    @$selectR = $('<div></div>',{
      style:'width: 100%; height: 100%; z-index: 600; position: absolute;'
    })
    @selectR = @$selectR[0]
    @$el.append(@selectR)

    # dCt : display container that holds the content and the borders of the
    # content
    @$dCt = $('<div></div>', {
      style: 'width: 100%; height: 100%; z-index: 310; position: absolute; overflow: hidden; bottom:0px;'
    })
    @dCt = @$dCt[0]
    @$selectR.append(@dCt)

    # the content that we display
    @$content = $('<img>', {
      src: 'assets/images/cat.jpg',
      style:'border: none; visibility: visible; margin: 0px; padding: 0px; position: absolute; top: 0px; left: 0px; width: 100%; height: 100%; -webkit-user-select:none;'
    })
    @content = @$content[0]
    @$dCt.append(@content)

    # the borders are the line that are displayed around the countent
    @$borders = []
    @borders = for className, i in ['jcrop-hline', 'jcrop-hline bottom', 'jcrop-vline', 'jcrop-vline right']
      $el = $('<div></div>', {
        style: 'position:absolute; opacity:0.4;'
      })
      $el.addClass className
      @$borders.push $el
      $el[0]

    @$dCt.append @borders[el] for el of @borders

    # hCt: Handler container that will hold all the handlers
    @$hCt = $('<div></div>', {
      style: 'width: 100%; height: 100%; bottom: 0px; position: absolute; z-index: 320; display: block;'
    })
    @hCt = @$hCt[0]
    @$selectR.append(@hCt)

    # create the dragbars
    @dragbars = []
    @$dragbars = []
    for dir, i in @cards.slice(0, 4)
      $el = $('<div></div>', {
        style: 'position:absolute;'
      })
      $el.css
        cursor: dir + '-resize'
        'z-index': 370 + i
      $el.addClass "ord-#{dir} jcrop-dragbar dragbar"
      @$dragbars.push($el)
      @dragbars.push($el[0])

    for el of @dragbars
      @$hCt.append(@dragbars[el])

    # create the handles
    @handles = []
    @$handles = []
    for dir, i in @cards
      $el = $('<div></div>', {
        style: 'position:absolute;'
      })
      $el.css
        cursor: dir + '-resize'
        'z-index': 374 + i
      $el.addClass "ord-#{dir} jcrop-handle handle"
      @$handles.push $el
      @handles.push $el[0]

    for el of @handles
      @$hCt.append(@handles[el])

    # the special handler responsible for the rotation
    @$handleR = $('<div></div>', {
      style: 'position:absolute; margin-left: -4px; margin-top: -4px; left: 50%; top:-25px; cursor:url(assets/images/rotate.png) 12 12, auto; z-index:382;'
    })
    @$handleR.addClass 'jcrop-handle handleR'
    @handleR = @$handleR[0]

    @$hCt.append(@handleR)

    #This element is here to receive mouse events (clicks)
    @$tracker = $('<div></div>', {
      style: 'cursor: move; position: absolute; z-index: 360;'
    })
    @$tracker.addClass('jcrop-tracker tracker')
    @tracker = @$tracker[0]
    @$hCt.append(@tracker)

    # we finally attach the Block element to the page
    @$page.append(@el)
