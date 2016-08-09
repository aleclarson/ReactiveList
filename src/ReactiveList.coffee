
assertType = require "assertType"
Tracker = require "tracker"
Event = require "Event"
Type = require "Type"

type = Type "ReactiveList"

type.argumentTypes =
  array: Array.Maybe

type.defineValues (array) ->

  _dep: Tracker.Dependency()

  _array: array or []

  _didChange: Event()

type.defineReactiveValues ->

  _length: @_array.length

type.defineGetters

  length: -> @_length

  didChange: -> @_didChange.listenable

  _canEmit: -> @_didChange.hasListeners

type.definePrototype

  array:
    get: ->
      Tracker.isActive and @_dep.depend()
      return @_array
    set: (newItems) ->
      oldItems = @_array
      return if newItems is oldItems
      @_array = newItems
      @_length = newItems.length
      @_dep.changed()
      @_canEmit and @_didChange.emit {
        event: "replace"
        newItems
        oldItems
      }

type.defineMethods

  prepend: (item) ->
    if isArray = Array.isArray item
      @_array = item.concat @_array
      @_length += item.length
    else
      @_array.unshift item
      @_length += 1
    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "prepend"
      items: if isArray then item else [item]
      offset: 0
    return

  append: (item) ->
    oldLength = @_length
    if isArray = Array.isArray item
      @_array = @_array.concat item
      @_length += item.length
    else
      @_array.push item
      @_length += 1
    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "append"
      items: if isArray then item else [item]
      offset: oldLength
    return

  pop: (count) ->
    assertType count, Number.Maybe
    return if @_length is 0
    {removed, offset} = @_pop count
    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "remove"
      items: removed
      offset: offset
    if count? then removed
    else removed[0]

  remove: (index) ->
    assertType index, Number
    @_assertValidIndex index
    return if @_length is 0
    removed = @_array.splice index, 1
    @_length -= 1
    @_dep.changed()
    @_canEmit and @_didChange.emit
      event: "remove"
      items: removed
      offset: index
    return removed

  insert: (index, item) ->
    @splice index, 0, item

  splice: (index, length, item) ->

    assertType index, Number
    assertType length, Number

    @_assertValidIndex index, @_length + 1

    oldLength = @_length
    {removed, inserted} = @_splice index, length, item
    numRemoved = removed.length
    numInserted = inserted.length

    if numRemoved or numInserted
      if numRemoved isnt numInserted
        @_length += numInserted - numRemoved
      @_dep.changed()
      return if not @_canEmit
      numRemoved and @_didChange.emit
        event: "remove"
        items: removed
        offset: index
      numInserted and @_didChange.emit
        event: @_getInsertEvent index, oldLength
        items: inserted
        offset: index
    return

  swap: (oldIndex, newIndex) ->

    assertType oldIndex, Number
    assertType newIndex, Number

    @_assertValidIndex oldIndex
    @_assertValidIndex newIndex

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

  _assertValidIndex: (index, maxIndex = @_length) ->
    if index < 0
      throw RangeError "'index' cannot be < 0!"
    if index >= maxIndex
      throw RangeError "'index' cannot be >= #{maxIndex}!"
    return

  _getInsertEvent: (index, length) ->
    return "prepend" if index is 0
    return "append" if index >= length
    return "insert"

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
    newLength = @_length - count
    if count is 1
      removed = [ @_array.pop() ]
      @_length = newLength
    else if newLength < 0
      removed = @_array
      @_array = []
      @_length = 0
    else
      removed = @_array.slice newLength
      @_array = @_array.slice 0, newLength
      @_length = newLength
    return {removed, offset: newLength}

module.exports = type.build()
