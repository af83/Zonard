TODO
====

  * factorize the expressions of the vector of the mouse in local base in
    a function, factorize some projections calculus...
  * docs
  * fix an complete specs
  * rethink the setBox method. The box is now considered as an origin for
    transformations (see _setState). we now need a method able to handle a
    *real* setting of of the box attribute mixed with the current setBox, that
    could do something equivalent to:

```
zonard.box = {...}
zonard._setState()
zonard.setBox()
zonard._state.bBox = zonard.el.getBoundingClientRect()
zonard.assignCursor()
```

