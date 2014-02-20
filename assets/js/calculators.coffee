# Functions destined to process data from mouse events
# These are internal method

calculators = (->

  # fastest implementation of the signum function:
  #   sgn = (x)-> `x ? (x < 0 ? -1 : 1) : 0`
  # for our use, will force the method to ouput 1 if the input is 0
  sgn = (x)-> `x < 0 ? -1 : 1`

  # Estimate the position, dimensions and rotation of the composant
  # Cannot achieve subpixel precision as of now :(
  _sniffState = (data = {})->
    # passing a lot of data, for not having to look it
    # up inside the handler
    @_state = $.extend(true, @_state, data)

    # we figure out the angle of rotation with the
    # output of @el.css('transform')
    # CAUTION: this won't work if there is any scaling on
    # the el
    matrix = @$el.css('transform')
    tab = matrix.substr(7, matrix.length-8).split(', ')
    cos = parseFloat tab[0]
    sin = parseFloat tab[1]

    # using the sign of the sinus of the angle is relevant as we will epxress our angle between [-Pi Pi]
    sign = sgn sin
    angleRad = sign * Math.acos(cos)
    angleDeg = angleRad * 360 /(2 * Math.PI)

    @_state.angle =
      rad: angleRad
      deg: angleDeg
      cos: cos
      sin: sin

    # WARNING!!! problems in IE9 when trying to get bounding
    # client rect when the element is not in the dom yet!
    box = @el.getBoundingClientRect()
    w = @$el.width()
    h = @$el.height()
    # we precalculate the value of cos and sin
    @_state.angle.cos = Math.cos(@_state.angle.rad)
    @_state.angle.sin = Math.sin(@_state.angle.rad)
    # TODO: Find a consistent way of finding out where the
    # zonard is (css positions + transform state ?)
    #
    # the initial position of @el
    @_state.elPosition =
      left : parseInt @$el.css('left')[...-2]
      top  : parseInt @$el.css('top')[...-2]
    # WILL CAUSE A HUGE MESS IF THE WORKSPACE HAS
    # A ROTATE TRANSFORMATION

    # = workspaceOffset??
    @_state.workspaceOffset = @$workspace.offset()

    @_state.elOffset =
      left: @_state.workspaceOffset.left + @_state.elPosition.left
      top : @_state.workspaceOffset.top   + @_state.elPosition.top
    # example of position bound based on the box that bounds
    # the rotateContainer
    @_state.positionBounds =
      ox: -Infinity
      oy: -Infinity
      x: Infinity
      y: Infinity
    @_state.elDimension =
      width: w
      height: h
    # we calculate the coordinates of the center of the rotation container
    @_state.rotatedCenter =
      x: @_state.elPosition.left + (w / 2) * @_state.angle.cos - (h / 2) * @_state.angle.sin
      y: @_state.elPosition.top + (w / 2) * @_state.angle.sin + (h / 2) * @_state.angle.cos

     if @_state.card?
      @_state.coef = @coefs[@_state.card]
      # to be used when constraining a resize interaction
      @_state.minMouse = minMouse =
        x: (w - @sizeBounds.wMin) * @_state.coef[0]
        y: (h - @sizeBounds.hMin) * @_state.coef[1]

    @getBox()

  #
  # Method to set the original state to be used for transformation
  # uses data in the box attribute as base
  #
  _setState = (data = {})->
    # passing a lot of data, for not having to look it
    # up inside the handler
    @_state = $.extend(true, @_state, data)

    rad = @box.rotate * 2 * Math.PI / 360
    @_state.angle =
      rad: rad
      deg: @box.rotate
      cos: Math.cos rad
      sin: Math.sin rad

    @_state.elDimension =
      width : w = @box.width
      height: h = @box.height

    @_state.elPosition =
      left : @box.left
      top  : @box.top

    @_state.workspaceOffset = @$workspace.offset()

    @_state.elOffset =
      left: @_state.workspaceOffset.left + @_state.elPosition.left
      top : @_state.workspaceOffset.top   + @_state.elPosition.top
    # example of position bound based on the box that bounds
    # the rotateContainer
    @_state.positionBounds =
      ox: -Infinity
      oy: -Infinity
      x: Infinity
      y: Infinity
    # element bounding box
    @_state.bBox = @el.getBoundingClientRect()
    # we calculate the coordinates of the center of the rotation container
    @_state.rotatedCenter =
      x: @_state.elPosition.left + (w / 2) * @_state.angle.cos - (h / 2) * @_state.angle.sin
      y: @_state.elPosition.top + (w / 2) * @_state.angle.sin + (h / 2) * @_state.angle.cos

     if @_state.card?
      @_state.coef = @coefs[@_state.card]
      # to be used when constraining a resize interaction
      @_state.minMouse = minMouse =
        x: (w - @sizeBounds.wMin) * @_state.coef[0]
        y: (h - @sizeBounds.hMin) * @_state.coef[1]

    @getBox()

  _calculateMove = (event)->
    state = event.data
    bounds = @_state.positionBounds
    vector =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y

    previousCenter =
      x: @_state.rotatedCenter.x
      y: @_state.rotatedCenter.y

    # if the shift key is pressed, only take account of the dominant component
    # of the mouse displacement
    if event.shiftKey
      maxY = Math.abs(vector.x) < Math.abs(vector.y)
      if maxY
        vector.x = 0
      else
        vector.y = 0

    snap = {}
    # if the alt key is pressed, ignore snapping
    if !event.altKey and @anchors?
      center =
        x: previousCenter.x + vector.x
        y: previousCenter.y + vector.y

      # offsets to reach a side of the box from the center
      offsets =
        x: @_state.bBox.width / 2
        y: @_state.bBox.height / 2

      threshold = 15

      min =
        x: Infinity
        y: Infinity
      # check vertical and horizontal component
      for component in ["x", "y"]
        # check each anchor
        for anchor in @anchors[component]
          # check the each side and the center of the zonard
          for val in [offsets[component], 0, -offsets[component]]
            offset = anchor + val
            if Math.abs(center[component] - offset) < threshold
              if Math.abs(offset) < Math.abs(min[component])
                min[component] = offset
                snap[component] = anchor

        # snap at the smallest anchor offset if there was one
        if min[component] isnt Infinity
          vector[component] = min[component] - previousCenter[component]

    # return box
    left   : @_state.elPosition.left + vector.x
    top    : @_state.elPosition.top + vector.y
    width  : @_state.elDimension.width
    height : @_state.elDimension.height
    rotate : @_state.angle.deg
    center:
      x: previousCenter.x + vector.x
      y: previousCenter.y + vector.y
    bBox:
      width : @_state.bBox.width
      height: @_state.bBox.height
    # notify the coordinates of the anchors if there was a snap
    snap:
      x: snap.x
      y: snap.y

  #
  # Rotation of the rotationContainer
  #
  _calculateRotate = (event)->
    w = @_state.elDimension.width
    h = @_state.elDimension.height

    # v is the vector from the center of the content to
    # the pointer of the mouse
    mouse =
      x: event.pageX
      y: event.pageY

    vector =
      x: (mouse.x - @_state.workspaceOffset.left) - @_state.rotatedCenter.x
      y: (mouse.y - @_state.workspaceOffset.top)  - @_state.rotatedCenter.y

    normV = Math.sqrt vector.x * vector.x + vector.y * vector.y
    # vn is v normalized
    normalized =
      x: vector.x / normV || 0
      y: vector.y / normV || 0
    # "sign" is the sign of v.x
    sign = sgn vector.x
    # angle is the angle between v and the vector (0,-1)
    angle = {}
    angle.rad = (Math.asin(normalized.y) + Math.PI / 2) * sign

    # add some snappings to ease the use of the rotation
    unless event.altKey
      [notch, threshold] = if event.shiftKey
        [Math.PI / 12, null]
      else
        [Math.PI / 2, 1 / 30]

      inter = angle.rad / notch
      round = Math.round(inter)
      rest = inter - round
      angle.rad = round * notch if !threshold? or Math.abs(rest) < threshold

    angle.deg = angle.rad * 360 / (2 * Math.PI)

    angle.cos = Math.cos(angle.rad)
    angle.sin = Math.sin(angle.rad)

    # "original" M
    originalM =
      x: @_state.rotatedCenter.x - w / 2
      y: @_state.rotatedCenter.y - h / 2

    # we now have to figure out the new position of the (0,0)
    # of the zonard:
    cM =
      x: -w / 2
      y: -h / 2

    cN =
      x: cM.x * angle.cos - cM.y * angle.sin
      y: cM.x * angle.sin + cM.y * angle.cos

    mN =
      x: cN.x - cM.x
      y: cN.y - cM.y

    # return box
    {
      left   : originalM.x + mN.x
      top    : originalM.y  + mN.y
      rotate : angle.deg
      angle  : angle
      width  : @_state.elDimension.width
      height : @_state.elDimension.height
      # due the way we calculate the rotation, the natural center of the zonard
      # is untouched
      center:
        x: @_state.rotatedCenter.x
        y: @_state.rotatedCenter.y
      bBox:
        width : @_state.bBox.width
        height: @_state.bBox.height
    }

  _calculateResize = (event)->
    coef = @_state.coef
    # B0 makes reference to the base of the workspace
    # B1 makes reference to the rotated base (local base of the rotation
    # container)

    mouseB0 =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y

    mouseB1 =
      x:  mouseB0.x * @_state.angle.cos + mouseB0.y * @_state.angle.sin
      y: -mouseB0.x * @_state.angle.sin + mouseB0.y * @_state.angle.cos

    # true if y > x in the local base, the coefs  define what is the direction
    # to be considered positive (ie the direction of the "exterior"
    maxY = mouseB1.x * coef[2] < mouseB1.y * coef[3]

    if @preserveRatio
      if maxY
        mouseB1.x =  mouseB1.y * coef[3] * coef[2] * @ratio
      else
        mouseB1.y = mouseB1.x * coef[2] * coef[3] / @ratio

    # new dimensions of the el
    dim =
      w: coef[2] * mouseB1.x + @_state.elDimension.width
      h: coef[3] * mouseB1.y + @_state.elDimension.height

    bounds = @sizeBounds
    # constrain is a couple of boolean that decide if we need to change the top
    # and left style
    constrain =
      x: 1
      y: 1

    if dim.w < bounds.wMin
      dim.w = bounds.wMin
      constrain.x = 0
    else if dim.w > bounds.wMax
      dim.w = bounds.wMax
      constrain.x = 0
    if dim.h < bounds.hMin
      dim.h = bounds.hMin
      constrain.y = 0
    else if dim.h > bounds.hMax
      dim.h = bounds.hMax
      constrain.y = 0

    # vector on which we need to project
    #  x: coef[0]
    #  y: coef[1]
    #  so our local vector projected on proj is
    projectionB1 =
      x: (if constrain.x then mouseB1.x else @_state.minMouse.x) * coef[0]
      y: (if constrain.y then mouseB1.y else @_state.minMouse.y) * coef[1]

    #translated in the base of the screen, it gives us
    projectionB0 =
      x: @_state.angle.cos * projectionB1.x - @_state.angle.sin * projectionB1.y
      y: @_state.angle.sin * projectionB1.x + @_state.angle.cos * projectionB1.y

    box =
      rotate: @_state.angle.deg
      width : dim.w
      height: dim.h
      left  : projectionB0.x + @_state.elPosition.left
      top   : projectionB0.y + @_state.elPosition.top

    box.center =
      x: box.left + (box.width / 2) * @_state.angle.cos - (box.height / 2) * @_state.angle.sin
      y: box.top  + (box.width / 2) * @_state.angle.sin + (box.height / 2) * @_state.angle.cos

    # we cannot give the bounding box here
    box

  _calculateCentralDrag = (event)->
    # B0 makes reference to the base of the workspace
    # B1 makes reference to the rotated base (local base of the
    # rotation container

    mouseB0 =
      x: event.pageX - @_state.origin.x
      y: event.pageY - @_state.origin.y

    mouseB1 =
      x:  mouseB0.x * @_state.angle.cos + mouseB0.y * @_state.angle.sin
      y: -mouseB0.x * @_state.angle.sin + mouseB0.y * @_state.angle.cos

    box = @getBox()
    box.mouseLocal = mouseB1
    box

  (proto)->
    proto._sniffState           = _sniffState
    proto._setState             = _setState
    proto._calculateMove        = _calculateMove
    proto._calculateRotate      = _calculateRotate
    proto._calculateResize      = _calculateResize
    proto._calculateCentralDrag = _calculateCentralDrag

)()
