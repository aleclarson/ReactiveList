
ReactiveVar = require "ReactiveVar"
assertType = require "assertType"
Tracker = require "tracker"
Event = require "Event"
Type = require "Type"

type = Type "ReactiveList"

type.defineArgs
  array: Array

type.defineValues (array) ->

  _array: array or []

type.defineFrozenValues ->

  _length: ReactiveVar @_array.length

  _didChange: Event()

  _dep: Tracker.Dependency()

type.defineGetters

  isEmpty: -> @_length is 0

  didChange: -> @_didChange.listenable

  _canEmit: -> @_didChange.hasListeners

type.definePrototype

  length:
    get: -> @_length.get()
    set: (newLength, oldLength) ->
      return if newLength is oldLength
      removed = @_array.slice newLength
      @_array.length = newLength
      @_length.set newLength
      @_dep.changed()
      @_canEmit and @_didChange.emit
        event: "remove"
        items: removed
        offset: newLength

  array:
    get: ->
      Tracker.isActive and @_dep.depend()
      return @_array
    set: (newItems) ->
      oldItems = @_array
      return if newItems is oldItems
      @_array = newItems
      @_length.set newItems.length
      @_dep.changed()
      @_canEmit and @_didChange.emit {
        event: "replace"
        newItems
        oldItems
      }

type.defineMethods

  get: (index) ->
    assertType index, Number
    isDev and @_assertValidIndex index, @_length._value - 1
    return @_array[index]

  forEach: (iterator) ->
    Tracker.active and @_dep.depend()
    @_array.forEach iterator
    return

  prepend: (item) ->

    if isArray = Array.isArray item
      @_array = item.concat @_array
      @_length.incr item.length
    else
      @_array.unshift item
      @_length.incr 1

    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "insert"
      items: if isArray then item else [item]
      offset: 0
    return

  append: (item) ->
    oldLength = @_length._value

    if isArray = Array.isArray item
      @_array = @_array.concat item
      @_length.incr item.length
    else
      @_array.push item
      @_length.incr 1

    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "insert"
      items: if isArray then item else [item]
      offset: oldLength
    return

  pop: (count) ->

    assertType count, Number.Maybe

    return if @_length._value is 0
    return if count? and count < 1
    {removed, offset} = @_pop count

    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "remove"
      items: removed
      offset: offset

    return removed if count?
    return removed[0]

  remove: (index) ->

    assertType index, Number

    isDev and @_assertValidIndex index, @_length._value - 1

    return if @_length._value is 0
    removed = @_array.splice index, 1
    @_length.decr 1

    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "remove"
      items: removed
      offset: index
    return removed[0]

  insert: (index, item) ->
    @splice index, 0, item

  splice: (index, length, item) ->

    assertType index, Number
    assertType length, Number

    isDev and @_assertValidIndex index

    oldLength = @_length._value

    {removed, inserted} = @_splice index, length, item

    numRemoved = removed.length
    numInserted = inserted.length

    if numRemoved or numInserted

      if numRemoved isnt numInserted
        @_length.incr numInserted - numRemoved

      @_dep.changed()

      return if not @_canEmit

      numRemoved and @_didChange.emit
        event: "remove"
        items: removed
        offset: index

      numInserted and @_didChange.emit
        event: "insert"
        items: inserted
        offset: index
    return

  swap: (oldIndex, newIndex) ->

    assertType oldIndex, Number
    assertType newIndex, Number

    if isDev
      @_assertValidIndex oldIndex, @_length._value - 1
      @_assertValidIndex newIndex, @_length._value - 1

    newValue = @_array[oldIndex]
    oldValue = @_array[newIndex]
    @_array[newIndex] = newValue
    @_array[oldIndex] = oldValue

    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "swap"
      items: [newValue, oldValue]
      indexes: [newIndex, oldIndex]
    return

  _assertValidIndex: (index, maxIndex = @_length._value) ->
    if index < 0
      throw RangeError "'index' cannot be < 0!"
    if index > maxIndex
      throw RangeError "'index' cannot be >= #{maxIndex}!"
    return

  _splice: (index, length, item) ->
    if item is undefined
      removed: @_array.splice index, length
      inserted: []
    else if isArray = Array.isArray item
      removed: [].splice.apply @_array, [index, length].concat item
      inserted: item
    else
      removed: @_array.splice index, length, item
      inserted: [item]

  _pop: (count = 1) ->
    return if count <= 0
    newLength = @_length._value - count
    if count is 1
      removed = [ @_array.pop() ]
      @_length.set newLength
    else if newLength < 0
      removed = @_array
      @_array = []
      @_length.set 0
    else
      removed = @_array.slice newLength
      @_array = @_array.slice 0, newLength
      @_length.set newLength
    return {removed, offset: newLength}

module.exports = type.build()
