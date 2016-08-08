var Event, Tracker, Type, assertType, type;

assertType = require("assertType");

Tracker = require("tracker");

Event = require("Event");

Type = require("Type");

type = Type("ReactiveList");

type.argumentTypes = {
  array: Array.Maybe
};

type.defineValues(function(array) {
  return {
    _dep: Tracker.Dependency(),
    _array: array || [],
    _didChange: Event()
  };
});

type.defineReactiveValues(function() {
  return {
    _length: this._array.length
  };
});

type.defineGetters({
  length: function() {
    return this._length;
  },
  didChange: function() {
    return this._didChange.listenable;
  },
  _canEmit: function() {
    return this._didChange.hasListeners;
  }
});

type.definePrototype({
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
      this._length = newItems.length;
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
  prepend: function(item) {
    var isArray;
    if (isArray = Array.isArray(item)) {
      this._array = item.concat(this._array);
      this._length += item.length;
    } else {
      this._array.unshift(item);
      this._length += 1;
    }
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "prepend",
      items: isArray ? item : [item],
      offset: 0
    });
  },
  append: function(item) {
    var isArray, oldLength;
    oldLength = this._length;
    if (isArray = Array.isArray(item)) {
      this._array = this._array.concat(item);
      this._length += item.length;
    } else {
      this._array.push(item);
      this._length += 1;
    }
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "append",
      items: isArray ? item : [item],
      offset: oldLength
    });
  },
  pop: function(count) {
    var offset, ref, removed;
    assertType(count, Number.Maybe);
    if (this._length === 0) {
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
    } else {
      return removed[0];
    }
  },
  remove: function(index) {
    var removed;
    assertType(index, Number);
    this._assertValidIndex(index);
    if (this._length === 0) {
      return;
    }
    removed = this._array.splice(index, 1);
    this._length -= 1;
    this._dep.changed();
    this._canEmit && this._didChange.emit({
      event: "remove",
      items: removed,
      offset: index
    });
    return removed;
  },
  insert: function(index, item) {
    return this.splice(index, 0, item);
  },
  splice: function(index, length, item) {
    var inserted, numInserted, numRemoved, oldLength, ref, removed;
    assertType(index, Number);
    assertType(length, Number);
    this._assertValidIndex(index, this._length + 1);
    oldLength = this._length;
    ref = this._splice(index, length, item), removed = ref.removed, inserted = ref.inserted;
    numRemoved = removed.length;
    numInserted = inserted.length;
    if (numRemoved || numInserted) {
      if (numRemoved !== numInserted) {
        this._length += numInserted - numRemoved;
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
        event: this._getInsertEvent(index, oldLength),
        items: inserted,
        offset: index
      });
    }
  },
  swap: function(oldIndex, newIndex) {
    var newValue, oldValue;
    assertType(oldIndex, Number);
    assertType(newIndex, Number);
    this._assertValidIndex(oldIndex);
    this._assertValidIndex(newIndex);
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
      maxIndex = this._length;
    }
    if (index < 0) {
      throw RangeError("'index' cannot be < 0!");
    }
    if (index >= maxIndex) {
      throw RangeError("'index' cannot be >= " + maxIndex + "!");
    }
  },
  _getInsertEvent: function(index, length) {
    if (index === 0) {
      return "prepend";
    }
    if (index >= length) {
      return "append";
    }
    return "insert";
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
    newLength = this._length - count;
    if (count === 1) {
      removed = [this._array.pop()];
      this._length = newLength;
    } else if (newLength < 0) {
      removed = this._array;
      this._array = [];
      this._length = 0;
    } else {
      removed = this._array.slice(newLength);
      this._array = this._array.slice(0, newLength);
      this._length = newLength;
    }
    return {
      removed: removed,
      offset: newLength
    };
  }
});

module.exports = type.build();

//# sourceMappingURL=map/ReactiveList.map
