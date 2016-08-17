var Event, ReactiveVar, Tracker, Type, assertType, type;

ReactiveVar = require("ReactiveVar");

assertType = require("assertType");

Tracker = require("tracker");

Event = require("Event");

Type = require("Type");

type = Type("ReactiveList");

type.defineArgs({
  array: Array
});

type.defineValues(function(array) {
  return {
    _array: array || []
  };
});

type.defineFrozenValues(function() {
  return {
    _length: ReactiveVar(this._array.length),
    _didChange: Event(),
    _dep: Tracker.Dependency()
  };
});

type.defineGetters({
  isEmpty: function() {
    return this._length === 0;
  },
  didChange: function() {
    return this._didChange.listenable;
  },
  _canEmit: function() {
    return this._didChange.hasListeners;
  }
});

type.definePrototype({
  length: {
    get: function() {
      return this._length.get();
    },
    set: function(newLength, oldLength) {
      var removed;
      if (newLength === oldLength) {
        return;
      }
      removed = this._array.slice(newLength);
      this._array.length = newLength;
      this._length.set(newLength);
      this._dep.changed();
      return this._canEmit && this._didChange.emit({
        event: "remove",
        items: removed,
        offset: newLength
      });
    }
  },
  array: {
    get: function() {
      Tracker.isActive && this._dep.depend();
      return this._array;
    },
    set: function(newItems) {
      var oldItems;
      oldItems = this._array;
      if (newItems === oldItems) {
        return;
      }
      this._array = newItems;
      this._length.set(newItems.length);
      this._dep.changed();
      return this._canEmit && this._didChange.emit({
        event: "replace",
        newItems: newItems,
        oldItems: oldItems
      });
    }
  }
});

type.defineMethods({
  get: function(index) {
    assertType(index, Number);
    isDev && this._assertValidIndex(index, this._length._value - 1);
    return this._array[index];
  },
  forEach: function(iterator) {
    Tracker.active && this._dep.depend();
    this._array.forEach(iterator);
  },
  prepend: function(item) {
    var isArray;
    if (isArray = Array.isArray(item)) {
      this._array = item.concat(this._array);
      this._length.incr(item.length);
    } else {
      this._array.unshift(item);
      this._length.incr(1);
    }
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "insert",
      items: isArray ? item : [item],
      offset: 0
    });
  },
  append: function(item) {
    var isArray, oldLength;
    oldLength = this._length._value;
    if (isArray = Array.isArray(item)) {
      this._array = this._array.concat(item);
      this._length.incr(item.length);
    } else {
      this._array.push(item);
      this._length.incr(1);
    }
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "insert",
      items: isArray ? item : [item],
      offset: oldLength
    });
  },
  pop: function(count) {
    var offset, ref, removed;
    assertType(count, Number.Maybe);
    if (this._length._value === 0) {
      return;
    }
    if ((count != null) && count < 1) {
      return;
    }
    ref = this._pop(count), removed = ref.removed, offset = ref.offset;
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "remove",
      items: removed,
      offset: offset
    });
    if (count != null) {
      return removed;
    }
    return removed[0];
  },
  remove: function(index) {
    var removed;
    assertType(index, Number);
    isDev && this._assertValidIndex(index, this._length._value - 1);
    if (this._length._value === 0) {
      return;
    }
    removed = this._array.splice(index, 1);
    this._length.decr(1);
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "remove",
      items: removed,
      offset: index
    });
    return removed[0];
  },
  insert: function(index, item) {
    return this.splice(index, 0, item);
  },
  splice: function(index, length, item) {
    var inserted, numInserted, numRemoved, oldLength, ref, removed;
    assertType(index, Number);
    assertType(length, Number);
    isDev && this._assertValidIndex(index);
    oldLength = this._length._value;
    ref = this._splice(index, length, item), removed = ref.removed, inserted = ref.inserted;
    numRemoved = removed.length;
    numInserted = inserted.length;
    if (numRemoved || numInserted) {
      if (numRemoved !== numInserted) {
        this._length.incr(numInserted - numRemoved);
      }
      this._dep.changed();
      if (!this._canEmit) {
        return;
      }
      numRemoved && this._didChange.emit({
        event: "remove",
        items: removed,
        offset: index
      });
      numInserted && this._didChange.emit({
        event: "insert",
        items: inserted,
        offset: index
      });
    }
  },
  swap: function(oldIndex, newIndex) {
    var newValue, oldValue;
    assertType(oldIndex, Number);
    assertType(newIndex, Number);
    if (isDev) {
      this._assertValidIndex(oldIndex, this._length._value - 1);
      this._assertValidIndex(newIndex, this._length._value - 1);
    }
    newValue = this._array[oldIndex];
    oldValue = this._array[newIndex];
    this._array[newIndex] = newValue;
    this._array[oldIndex] = oldValue;
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "swap",
      items: [newValue, oldValue],
      indexes: [newIndex, oldIndex]
    });
  },
  _assertValidIndex: function(index, maxIndex) {
    if (maxIndex == null) {
      maxIndex = this._length._value;
    }
    if (index < 0) {
      throw RangeError("'index' cannot be < 0!");
    }
    if (index > maxIndex) {
      throw RangeError("'index' cannot be >= " + maxIndex + "!");
    }
  },
  _splice: function(index, length, item) {
    var isArray;
    if (item === void 0) {
      return {
        removed: this._array.splice(index, length),
        inserted: []
      };
    } else if (isArray = Array.isArray(item)) {
      return {
        removed: [].splice.apply(this._array, [index, length].concat(item)),
        inserted: item
      };
    } else {
      return {
        removed: this._array.splice(index, length, item),
        inserted: [item]
      };
    }
  },
  _pop: function(count) {
    var newLength, removed;
    if (count == null) {
      count = 1;
    }
    if (count <= 0) {
      return;
    }
    newLength = this._length._value - count;
    if (count === 1) {
      removed = [this._array.pop()];
      this._length.set(newLength);
    } else if (newLength < 0) {
      removed = this._array;
      this._array = [];
      this._length.set(0);
    } else {
      removed = this._array.slice(newLength);
      this._array = this._array.slice(0, newLength);
      this._length.set(newLength);
    }
    return {
      removed: removed,
      offset: newLength
    };
  }
});

module.exports = type.build();

//# sourceMappingURL=map/ReactiveList.map
