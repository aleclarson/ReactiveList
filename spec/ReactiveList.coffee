
Tracker = require "tracker"

ReactiveList = require ".."

describe "ReactiveList(array)", ->

  it "creates an empty list", ->
    list = ReactiveList()
    expect list.length
      .toBe 0
    expect list.array
      .toEqual []

  # NOTE: A caveat here is that the backing array is overwritten by some methods. (search for "@_array = ")
  it "can use an existing array as its backing array", ->
    array = [ 1, 2, 3 ]
    list = ReactiveList array
    expect list.length
      .toBe 3
    expect list.array
      .toBe array

describe "ReactiveList().array", ->

  it "is reactive", ->
    spy = jasmine.createSpy()
    list = ReactiveList()
    computed = Tracker.autorun -> spy list.array.slice()
    computed.isAsync = no
    list.append [ 1, 2 ]
    computed.stop()
    expect spy.calls.argsFor 1
      .toEqual [[ 1, 2 ]]

  it "is writable", ->
    list = ReactiveList()
    list.array = arr2 = []
    expect list.array
      .toBe arr2

  # it "emits a 'replace' event via 'list.didChange'", ->

describe "ReactiveList().length", ->

  it "is reactive", ->
    spy = jasmine.createSpy()
    list = ReactiveList()
    computed = Tracker.autorun -> spy list.length
    computed.isAsync = no
    list.append [ 1, 2 ]
    computed.stop()
    expect spy.calls.allArgs()
      .toEqual [[0], [2]]

  it "is writable", ->
    list = ReactiveList()
    list.array = arr2 = []
    expect list.array
      .toBe arr2

  # it "emits a 'replace' event via 'list.didChange'", ->

describe "ReactiveList::append(item)", ->

  it "adds an item to the end of the list", ->
    list = ReactiveList [ 1 ]
    list.append 2
    expect list.length
      .toBe 2
    expect list.array
      .toEqual [ 1, 2 ]

  it "supports pushing multiple items", ->
    list = ReactiveList [ 1 ]
    list.append [ 2, 3 ]
    expect list.length
      .toBe 3
    expect list.array
      .toEqual [ 1, 2, 3 ]

  it "keeps its backing array if a single item is pushed", ->
    array = [ 1 ]
    list = ReactiveList array
    list.append 2
    expect list._array
      .toBe array

  it "replaces its backing array if multiple items are pushed", ->
    array = [ 1 ]
    list = ReactiveList array
    list.append [ 2, 3 ]
    expect list._array
      .not.toBe array

  it "emits an 'insert' event via 'list.didChange'", ->
    list = ReactiveList()
    onChange = list.didChange spy = jasmine.createSpy()
    onChange.start()
    list.append 1
    onChange.stop()
    expect spy.calls.count()
      .toBe 1
    args = spy.calls.argsFor 0
    expect args[0].event
      .toBe "insert"
    expect args[0].items
      .toEqual [ 1 ]

describe "ReactiveList::prepend(item)", ->

  it "adds an item to the front of the list", ->
    list = ReactiveList [ 1 ]
    list.prepend 2
    expect list.length
      .toBe 2
    expect list.array
      .toEqual [ 2, 1 ]

  it "supports unshifting multiple items", ->
    list = ReactiveList [ 1 ]
    list.prepend [ 2, 3 ]
    expect list.length
      .toBe 3
    expect list.array
      .toEqual [ 2, 3, 1 ]

  it "keeps its backing array if a single item is unshifted", ->
    array = [ 1 ]
    list = ReactiveList array
    list.prepend 2
    expect list._array
      .toBe array

  it "replaces its backing array if multiple items are pushed", ->
    array = [ 1 ]
    list = ReactiveList array
    list.prepend [ 2, 3 ]
    expect list._array
      .not.toBe array

  it "emits an 'insert' event via 'list.didChange'", ->
    list = ReactiveList()
    onChange = list.didChange spy = jasmine.createSpy()
    onChange.start()
    list.prepend 1
    onChange.stop()
    expect spy.calls.count()
      .toBe 1
    args = spy.calls.argsFor 0
    expect args[0].event
      .toBe "insert"
    expect args[0].items
      .toEqual [ 1 ]

describe "ReactiveList::pop(count)", ->

  it "removes the last item", ->
    list = ReactiveList [ 1, 2 ]
    expect list.pop()
      .toBe 2
    expect list.length
      .toBe 1
    expect list.array
      .toEqual [ 1 ]

  it "supports popping multiple items", ->
    list = ReactiveList [ 1, 2, 3 ]
    expect list.pop 2
      .toEqual [ 2, 3 ]
    expect list.length
      .toBe 1
    expect list.array
      .toEqual [ 1 ]

  # it "emits a 'remove' event via 'list.didChange'", ->

describe "ReactiveList::remove(index)", ->

  it "removes a specific index", ->
    list = ReactiveList [ 1, 2, 3 ]
    list.remove 1
    expect list.length
      .toBe 2
    expect list.array
      .toEqual [ 1, 3 ]

  # it "emits a 'remove' event via 'list.didChange'", ->

describe "ReactiveList::insert(index, item)", ->

  it "inserts at a specific index", ->
    list = ReactiveList [ 1, 3 ]
    list.insert 1, 2
    expect list.length
      .toBe 3
    expect list.array
      .toEqual [ 1, 2, 3 ]

  # it "emits an 'insert' event via 'list.didChange'", ->

describe "ReactiveList::splice(index, length, item)", ->

  it "can remove and insert at the same time", ->
    list = ReactiveList [ 1, 2 ]
    list.splice 0, 1, 2
    expect list.length
      .toBe 2
    expect list.array
      .toEqual [ 2, 2 ]

  it "is not required to insert any items", ->
    list = ReactiveList [ 1, 2 ]
    list.splice 0, 2
    expect list.length
      .toBe 0
    expect list.array
      .toEqual []

  it "is not required to remove any items", ->
    list = ReactiveList [ 1, 2 ]
    list.splice 0, 0, 0
    expect list.length
      .toBe 3
    expect list.array
      .toEqual [ 0, 1, 2 ]

  it "supports inserting multiple items", ->
    list = ReactiveList [ 0, 3 ]
    list.splice 1, 0, [ 1, 2 ]
    expect list.length
      .toBe 4
    expect list.array
      .toEqual [ 0, 1, 2, 3 ]

describe "ReactiveList::swap(oldIndex, newIndex)", ->

  it "swaps the values of two indexes", ->
    list = ReactiveList [ 0, 3, 2, 1 ]
    list.swap 1, 3
    expect list.array
      .toEqual [ 0, 1, 2, 3 ]
