
# ReactiveList v1.2.1 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

```coffee
ReactiveList = require "ReactiveList"

list = ReactiveList [ 1 ]

# The number of items in the list.
# This value is *reactive*!
list.length

# The items of the list.
# This value is *reactive*!
list.array

# Feel free to replace the backing array.
list.array = [ 1, 2 ]

# You can set the length directly, too.
list.length = 1
```

### Methods

```coffee
# Identical to push...
list.append 2

# ...except you can concat other arrays!
list.append [ 3, 4 ]

# Identical to unshift...
list.prepend 0

# ...except you can concat other arrays!
list.prepend [ -2, -1 ]

# Identical to pop...
value = list.pop()

# ...except you can pop multiple!
values = list.pop 2

# Insert at a specific index.
list.insert 2, 100

# Remove a specific index.
list.remove 2

# Splice like an array.
# Except no return value.
# And you can concat other arrays!
list.splice 0, 2, [ 2, 1 ]

# Swap the values of two indexes.
list.swap 0, 1
```

### Reacting to changes

There are **2** ways of reacting to changes in a `ReactiveList`:

- Wrap `list.array` in a `Tracker.Computation` (if you don't care about event names)

```coffee
Tracker = require "tracker"

# The callback passed to 'autorun' is called
# every time a change is made to the backing array.
computed = Tracker.autorun ->
  console.log list.array.toString()

# Must stop manually.
computed.stop()
```

- Create an `Event.Listener` using `list.didChange(callback)`

```coffee
listener = list.didChange (change) ->
  switch change.event # Only one event is emitted for each operation.
    when "prepend" # When items are added to the front.
    when "append"  # When items are added to the back.
    when "insert"  # When items are added to the middle.
    when "swap"    # When two items switch places.
    when "remove"  # When items are removed.
    when "replace" # When 'list.array' is directly set.

# Must start/stop manually.
listener.start()
listener.stop()
```
