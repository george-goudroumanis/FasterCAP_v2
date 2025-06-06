Summary of important user-visible changes for version 9 (yyyy-mm-dd):
---------------------------------------------------------------------

### General improvements

- `oruntests`: The current directory now changes to the directory
containing the files with the tests for the duration of the test.  This
aligns the behavior of this function with Octave's test suite.  This also
means that the file encoding specified in the `.oct-config` file for the
respective directory is taken into account for the tests.

### Graphical User Interface

### Graphics backend

* the `set` function now accepts any combination of name/value pairs,
cell array of names / cell array of values, or property structures.
This change is Matlab-compatible.

### Matlab compatibility

### Alphabetical list of new functions added in Octave 9

* `tensorprod`

### Deprecated functions, properties, and operators

The following functions and properties have been deprecated in Octave 9
and will be removed from Octave 11 (or whatever version is the second
major release after 9):

- Functions

        Function               | Replacement
        -----------------------|------------------

- Properties

  The following property names are discouraged, but there is no fixed
  date for their removal.

        Object           | Property    | Replacement
        -----------------|-------------|------------

- Core

    * The `idx_vector::bool()` function is obsolete and always returns true.
Any uses can simply be removed from existing code with no loss of function.

    * The `all_ok(const Array<octave::idx_vector>&)` function in `Array-util.h`
is obsolete and always returns true.  Any uses can simply be removed from
existing code with no loss of function.

    * The member variable `octave_base_value::count` is deprecated and will be removed from Octave 11.  Replace all instances with the new name `m_count`.

The following features were deprecated in Octave 7 and have been removed
from Octave 9.

- Functions

        Function                   | Replacement
        ---------------------------|------------------
        disable_diagonal_matrix    | optimize_diagonal_matrix
        disable_permutation_matrix | optimize_permutation_matrix
        disable_range              | optimize_range

- Operators

        Operator | Replacement
        ---------|------------
        .+       | +
        .+=      | +=
        .-       | -
        .-=      | -=
        **       | ^
        **=      | ^=
        .**      | .^
        .**=     | .^=

- Interpreter

    * The use of `'...'` for line continuations *inside* double-quoted
    strings has been removed.  Use `'\'` for line continuations inside strings
    instead.

    * The use of `'\'` as a line continuation *outside* of double-quoted
    strings has been removed.  Use `'...'` for line continuations instead.

    * Support for trailing whitespace after a `'\'` line continuation has been
    removed.  Delete unnecessary trailing whitespace.

- For plot functions, the use of numbers to select line colors in
  shorthand formats was an undocumented feature was removed from Octave 9.

- The environment variable used by `mkoctfile` for linker flags is now
  `LDFLAGS` rather than `LFLAGS`.  `LFLAGS` was deprecated in Octave 6
  and has been removed.

### Old release news

- [Octave 8.x](etc/NEWS.8)
- [Octave 7.x](etc/NEWS.7)
- [Octave 6.x](etc/NEWS.6)
- [Octave 5.x](etc/NEWS.5)
- [Octave 4.x](etc/NEWS.4)
- [Octave 3.x](etc/NEWS.3)
- [Octave 2.x](etc/NEWS.2)
- [Octave 1.x](etc/NEWS.1)
