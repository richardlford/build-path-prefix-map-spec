TODO: define producers, consumer

== Encoding specification ==

This describes an environment variable that encodes a list-of-pairs where each
pair holds two strings. We'll use the terms "left"- and "right end of the
list", to respectively refer to the parts of the structure (or related), that
was originally parsed from the left (start) and right (end) ends of the value.

Generally the data types of environment variables are platform-dependent, but
we'll assume here that (for each platform) these are the same for environment
variable values as it is for file paths. On POSIX systems, they are strings of
octets (bytes), and on Windows they are strings of 16-bit wide words (wchar_t)
which may be valid or invalid UTF-16 [4].

[4] In other words, it is UCS-2, but this term is deprecated; see
    http://unicode.org/faq/utf_bom.html#utf16-1 no HTTPS unfortunately

Since our encoding only deals with ASCII-compatible characters, and UTF-16 uses
surrogate pairs to encode code points not in the BMP, it should be possible to
implement our encoding below by "naively" operating on string units, regardless
of whether a unit is an 8-bit octet (e.g. POSIX C), 16-bit wchar_t [5] (e.g.
Windows C++), or an actual decoded Unicode code point (e.g. Python 3).

[5] On Windows this is "supposed" to be UTF-16 and is commonly advertised as
    "UTF-16", however the kernel does not check this and only *some* Windows
    APIs enforce it. So in practice user code should not assume that the
    sequences are valid UTF-16, and should be able to deal with invalid UTF-16
    sequences. The easiest way to do this, is to treat these things as opaque
    16-bit sequences with no encoding.

    Windows references:
    - https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/getenv-s-wgetenv-s
    - https://msdn.microsoft.com/en-us/library/windows/desktop/dd374069(v=vs.85).aspx
    - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx
    - https://github.com/rust-lang/rust/issues/12056

The encoding is as follows:

- The ":" character separates encoded list items from each other.

  Empty subsequences between ":" characters, or between a ":" character and
  either the left or right end of the envvar, are valid and are ignored. [1]

  [1] This is to make it easier for producers to append values, e.g. as in
      ``envvar += ":" + encoded_pair`` which would be valid even if envvar is
      originally empty.

- Each encoded list item contains exactly one "=" character, that separates
  encoded pair elements.

  If there are zero or more than one "=" characters, this is a parse error and
  the whole environment variable is invalid. [2] In this case, the program
  should exit with an error code appropriate for the context, or if this is not
  possible then it must communicate the error in some way to the caller.

  The encoded pair elements may be empty; this does not need special-casing if
  the rest of the document is implemented correctly.

  [2] This is to "fail early" in the cases that a naive producer does not
      encode characters like "=" but the build path does actually contain them.

- Each encoded pair element is encoded with the following mapping:

  1. % -> %p
  2. = -> %e
  3. : -> %c

  When decoding, lone % characters at the end of a string are a parse error, as
  are %[X] substrings where [X] is any character not in "pec".

  This encoding allows paths containing "%", "=", ":" to be mapped; since users
  may want to run their builds under such paths. However as a producer, if this
  is not possible for your users (e.g. because you directly restrict possible
  build paths) then you may avoid implementing this encoding logic.

  Implementation notes: due to our choice of characters, there is flexibility
  in the order in which these mappings may be applied; this is meant to ease
  implementation in a variety of programming languages. The only restriction is
  that the % -> %p mapping for encoding must not be applied on already-encoded
  %-substrings; and that the %e -> =, %c -> : mappings for decoding must not be
  applied on already-decoded %-substrings.

  Our recommended approach for a high-level language with string replace:

  a. decoding:
     1. check elem does not match the regex /%[^pec]|%$/g
     2. elem.replace("%c", ':').replace("%e", '=').replace("%p", '%')
  b. encoding:
     1. elem.replace("%p", '%').replace("%e", '=').replace("%c", ':')

  Our recommended approach for a low-level language without string replace:

  a. decoding:
     1. one single left-to-right pass with lookahead (e.g. C code example)
     2. one single left-to-right pass with lookbehind (e.g. Rust code example)
  b. encoding:
     we don't anticipate this to be a major use-case


Setting the variable
====================

Producers SHOULD NOT overwrite existing values; instead they should append
their mappings onto the right of any existing value.

Producers who build *general software* that uses this envvar, MUST NOT expect
any special contracts on the output emitted by *general consumers* based on
this variable - only that their output be reproducible when the build path
changes and the value of this envvar is changed to match the new paths.

On the other hand, if you know you will only support a limited set of
consumers, you may expect that they apply these mappings in specific ways.

(See also the definition in the next part.)


Applying the variable
=====================

Consumers MUST ensure that, at minimum: for all ("source", "target") prefix
pairs in the parsed list, with rightmost pairs taking priority: strings in the
final build output, that represent build-time paths derived from "source",
instead appear to represent potential run-time paths derived from "target".

(As a corollary, consumers MUST NOT require producers append a directory
separator to a source prefix, to define mappings related to that directory.)

Implementation notes:

This definition specifically does not define "derived from", since this may be
different for different consumers (languages, buildsystems, etc), and a more
specific definition might conflict with their idea of what that means.

In practice, we recommend one of the following algorithms:

1. For each (source, target) prefix pair in the list-of-pairs, going from right
to left: if the subject path starts with the source prefix, then replace this
occurence with the target prefix, and return this new path, ignoring any pairs
further left in the list.

2. As in (1) but with "starts with" replaced by "starts with, restricted to
whole-path components". So for example,

/path/to/a/b/c "starts with" /path/to/a
/path/to/aa/b/c does not "start with" /path/to/a

(This has more robust semantics but is slightly more complex to implement.)


More specific implementation notes
==================================

Some high-level languages do not provide easy direct access to the underlying
environment variable value, in the string-type of the platform.

For example, on Python 3, os.getenv and the path functions normally return a
unicode string (where each unit is a decoded Unicode code point), unless you
specifically use os.getenvb instead or give them "bytes"-type path arguments.

Luckily on Python 3.3+ one can implement our encoding without duplicating code,
in a cross-platform way. Yes, paths and environment variables are presented as
(unencoded) Unicode strings. However on POSIX where the underlying OS values
are bytes, values which cannot be UTF-8 decoded to valid Unicode are instead
decoded (by default) into a lone "low surrogate" character (Python calls this
the "surrogateescope" encoding) which is not present in "normal" Unicode. The
resulting string, when UTF-8 encoded back into bytes, preserves the original
byte value - which is invalid UTF-8 but that doesn't matter to a POSIX OS.
Therefore, it is correct to implement a "naive" algorithm that operates on
Python unicode strings (i.e. T = unencoded Unicode character) even when the OS
type is bytes, and the benefit is that the same code will also work on Windows.

This type of "accidentally-correct" situation may not be true for all languages
however, so you should understand these issues carefully and check it.

For example, in Rust the OsString type is platform-dependent and opaque; one
must write platform-specific code to either convert this to an array of [u8]
(for POSIX) or an array of [u16] (for Windows). In the latter case, u16 units
that are invalid UTF-16  are represented internally as WTF-8, but this is only
an implementation detail. https://simonsapin.github.io/wtf-8/

For example, in NodeJS (as of v4.6.1), non-UTF-8 bytes in environment variables
are *not supported* - they will get replaced by U+FFFD instead. Best to file a
bug against them, if you need to map non-UTF-8 paths.

Our testcases/ includes a non-UTF-8 case, so you can test how to make this work
(or not) in your favourite language. (Unfortunately, we do not yet have invalid
UTF-16 test cases for windows.)


Transmitting these values
=========================

Our encoding only transforms sequences of printable ASCII characters. If you
have reason to believe that you need to escape or encode your file paths (e.g.
because they contain non-printable or non-ASCII characters) before transmitting
it across your chosen medium, it should suffice to simply apply the same escape
or encoding mechanism to this environment variable as well. This is an entirely
separate concern from anything else mentioned in this document, and the code to
do this should be clearly separated from code that implements this document.


Rejected options
================

- Simple-split using semi-common characters like ':', because it loses the
  ability to map paths containing those characters.

- Simple-split using never-in-path characters like '\t' or '0x1E RECORD
  SEPARATOR', because they make the output unconditionally non-printable.

- Any variant of backslash-escape, because it's not clean to implement in
  high-level languages. (Need to use regex or an explicit loop.)

- Any variant of hex-encoding, because different languages decode hex codes
  >127 in different ways, when inserting it back into a string.

- Any variant of url-encoding: as for hex-encoding, and additionally because
  the original perceived gain (being able to use existing decoders) did not
  work out in the end:

  - Extra characters like "+" ";" need to be encoded.

  - Decoders in many languages only decode to a { key -> value list }; there is
    no way to turn this into a list-of-pairs preserving the original ordering.

- Mapping % into %% (or \ into \\, etc), because this causes differences when
  decoding sequences like "%%+" via different strategies.
