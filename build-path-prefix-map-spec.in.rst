Introduction
============

This specification describes the environment variable ``BUILD_PATH_PREFIX_MAP``
for build tools to exchange information about the build-time filesystem layout,
to generate reproducible output where all embedded paths are independent of
that layout.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

The canonical URI for this document is:
`<https://reproducible-builds.org/specs/build-path-prefix-map/>`_.


Motivation
==========

Software packages are often unreproducible because they embed build-time paths
into generated files. At the time of writing, this affects an estimated 15-20%
of 25000 Debian packages being unreproducible when the build path is varied.

These paths do not exist at runtime, nor do they exist in the source code. An
improvement is to use relative paths that depend only on the source layout.
These paths can also be easily used as runtime paths, for example to access
source-code packages installed into standard paths, for IDEs and debuggers.

This requires knowledge of where the top-level source directories are, and
where (if any) the top-level out-of-tree-build directories are. However, some
toolchains were not designed to make this information available to the
lower-level tools that generate those build outputs with embedded paths.

This specification therefore defines a distribution-agnostic standard for
lower-level tools to consume this information from higher-level tools.

For more discussion on the mechanism of environment variables, see our page on
`Standard Environment Variables
<https://wiki.debian.org/ReproducibleBuilds/StandardEnvironmentVariables>`_.
Other mechanisms were also explored, but they were not completely effective and
only fixed some cases of the issue whilst generating new cases. For example,
automatically setting GCC's ``-fdebug-prefix-map`` option does not fix other
sources of irreproducibility such as ``__FILE__``, and in some packages the
option itself is saved into other parts of the build output by another tool.

For more information on Reproducible Builds in general, include its motivation
and its uses, see `<https://reproducible-builds.org/>`_.


Specification
=============

Overview
--------

The environment variable ``BUILD_PATH_PREFIX_MAP`` represents an ordered map
that associates reproducible path prefixes that may appear in the build output,
with path prefixes that exist on the build-time filesystem that must not appear
in the build output. We use the following terms:

A *producer* is a program that knows how to determine appropriate values for
the map, and can pass this information to lower-level build tools. For example,
a distribution's top-level package builder, or a high-level buildsystem.

A *consumer* is a program that generates output that contains paths, but does
not by itself know enough information about the filesystem layout to be able to
appropriately strip the build-time specific parts of those paths. Instead, it
relies on another tool to pass this information in. For example, a C compiler.

The value of the variable MUST NOT be saved as-is into any output meant to form
part of a reproducible binary artefact.


Encoding and decoding the variable
----------------------------------

This section describes a data structure encoding, from a list-of-pairs where
each pair holds two strings, into a single string.

We use the phrases *left*- and *right end of the list*, to refer to the parts
of the list that respectively correspond to the left (start) and right (end)
ends of the string that it was parsed from, and vice versa.

On POSIX systems these strings are a sequence of 8-bit bytes. On Windows
systems these strings are a sequence of 16-bit ``wchar_t`` words. On both
platforms, these string types are the types of both filesystem paths and
environment variables on that platform.

When implementing this data structure encoding, either (a) you MUST directly
operate on the system string types described above *without* also decoding or
encoding them using a character encoding such as UTF-8 or UTF-16; or (b) if you
must use a character encoding e.g. because your language's standard libraries
force you to, then either it is total and injective over the system string type
[1]_, or you MUST raise a parse error for inputs where it is undefined or not
injective. (See [2]_ for further details and guidance on how to do this.)

The encoding is as follows:

- The ``:`` character separates encoded list items from each other.

  Empty subsequences between ``:`` characters, or between a ``:`` character and
  either the left or right end of the value, are valid and are ignored. [3]_

- Each encoded list item contains exactly one ``=`` character, that separates
  encoded pair elements.

  If there are zero or more than one ``=`` characters, this is a parse error.
  [4]_

  The encoded pair elements may be empty; this does not need special-casing if
  the rest of the document is implemented correctly.

- Each encoded pair element is encoded with the following mapping:

  1. ``%`` → ``%#``
  2. ``=`` → ``%+``
  3. ``:`` → ``%.``

  When decoding, ``%`` characters at the end of a string are a parse error, as
  are ``%X`` substrings where ``X`` is any character not in ``#+.``.

  This encoding allows paths containing ``%``, ``=``, ``:`` to be mapped; since
  users may want to run their builds under such paths. However as a producer,
  if this is not possible for your consumers, for example because you directly
  restrict the possible build paths, then you may omit this encoding logic.

  Our choice of characters means there is flexibility in the order in which
  these mappings can be applied. The only restriction is that the ``%`` →
  ``%#`` mapping for encoding must not be applied on already-encoded
  %-substrings; and that the ``%+`` → ``=``, ``%.`` → ``:`` mappings for
  decoding must not be applied on already-decoded %-substrings. This is meant
  to ease implementation in a variety of programming languages.

  Our recommended approach for a high-level language with string replace:

  A. Decoding:

     1. check that ``elem`` does not match the regex ``/%[^#+.]|%$/g``, then
     2. ``elem.replace("%.", ":").replace("%+", "=").replace("%#", "%")``

  B. Encoding:

     1. ``elem.replace("%", "%#").replace("=", "%+").replace(":", "%.")``

  Our recommended approach for a low-level language without string replace:

  A. Decoding:

     - one single left-to-right pass with lookahead (e.g. see our C example), or
     - one single left-to-right pass with lookbehind (e.g. see our Rust example)

  B. Encoding:

     - We don't anticipate this to be a major use-case

In the event of parse errors, the whole value of the variable should be treated
as invalid rather than silently using only the "good" parts. The program should
exit with an error code appropriate for the context, or if this is not possible
then the parser must communicate the error in some way to the caller.


Setting the encoded value
-------------------------

Producers SHOULD NOT overwrite existing values; instead they should append
their new mappings onto the right of any existing value.

Producers that expect reproducible output MUST append at least one distinct
mapping for each top-level directory that the build is expected to take place
under. Each mapping has the reproducible *target* path prefix on the left, and
the unreproducible *source* path prefix on the right.

Producers such as top-level distribution package builders, that expect
*arbitrary consumers* to read this variable, MUST NOT expect any additional
constraints or special contracts on the output emitted by these consumers ―
only that their output be reproducible when the build path changes and the
value of this variable is changed to match the new paths.

On the other hand, producers that only support a limited set of consumers, may
expect that these consumers apply these mappings in particular ways.

See also the requirements for consumers in the next part for guidance.


Applying the decoded structure
------------------------------

Consumers MUST ensure that, at minimum: for all (*target*, *source*) prefix
pairs in the parsed list, with rightmost pairs taking priority: strings in the
final build output, that represent build-time paths derived from *source*,
instead appear to represent potential run-time paths derived from *target*.

As a consequence, consumers MUST apply mappings as above, regardless of whether
the *source* prefix ends with a directory separator or not.

We do not define "derived from" more specifically, since this may be different
for different consumers (languages, buildsystems, etc), and a more specific
definition might conflict with their idea of what that means. Generally,
consumers SHOULD implement one of the following algorithms:

1. For each (*target*, *source*) prefix pair in the list-of-pairs, going from
   right to left: if the subject path starts with the source prefix, then
   replace this occurence with the target prefix, and return this new path,
   ignoring any pairs further left in the list.

2. As in (1) but with "starts with" replaced by "starts with, restricted to
   whole-path components". So for example,

   - ``/path/to/a/b/c`` "starts with" ``/path/to/a``
   - ``/path/to/aa/b/c`` does not "start with" ``/path/to/a``

   This has more robust semantics but is slightly more complex to implement.

Consumers MAY for historical reasons internally store the map with the prefix
pairs flipped as in (*source*, *target*), instead of (*target*, *source*) as
described above. New code should prefer the latter representation.


Notes and links
===============

.. [1] In practice, this means any two byte sequences that are invalid UTF-8,
    or ``wchar_t`` sequences that are invalid UTF-16, must be decoded into
    distinct application-level character string values. This is not satisfied
    by most standard Unicode decoding strategies, which is to replace all
    invalid input sequences with ``U+FFFD REPLACEMENT CHARACTER``. For these
    cases, the easiest way to be compliant is to check the decode output for
    this character and raise an "unsupported" exception if it is found.

.. [2] Detailed implementation notes and advice are available on `our wiki page
    <https://wiki.debian.org/ReproducibleBuilds/BuildPathProposal#Implementation_notes>`_.
    Example source code is also available there, as well as in runnable form in
    `our git repository
    <https://anonscm.debian.org/cgit/reproducible/build-path-prefix-map-spec.git>`_.
    The test vectors from this document's appendix are also available there.

.. [3] This is to make it easier for producers to append values, e.g. as in
    ``old_value += ":" + encoded_pair`` which would be valid even if the value
    is originally empty.

.. [4] This is to "fail early" in case a naive producer does not
    encode characters like ``=`` but the build path or target path does
    actually contain them.


References
==========

POSIX system strings
--------------------

- `Definitions (no HTTPS)
  <http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html>`_
  -- see "Pathname", "String" and "Byte".

- `Environment Variables (no HTTPS)
  <http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html>`_
  for the type of ``environ``.

- `limits.h - implementation-defined constants (no HTTPS)
  <http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/limits.h.html>`_
  for the definition of ``CHAR_BIT``.

Windows system strings
----------------------

Windows strings are commonly advertised as "UTF-16", however for environment
variable values and filesystem paths the system APIs do not enforce validity of
the 16-bit strings passed to it. In other words, it is UCS-2, but this term `is
deprecated (no HTTPS) <http://unicode.org/faq/utf_bom.html#utf16-11>`_.

So in practice, user code should not assume that these system strings are valid
UTF-16, and should be able to deal with invalid UTF-16 strings. The easiest way
to do this, is to treat them as opaque 16-bit sequences with no encoding.

- `File Management > About File Management > Creating, Deleting, and Maintaining Files
  <https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx>`_

- `Visual C++ / Documentation / C Runtime Library / [..] / CRT Alphabetical
  Function Reference / getenv_s, _wgetenv_s
  <https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/getenv-s-wgetenv-s>`_

- `... > C Language Reference > ... > C Identifiers > Multibyte and Wide Characters
  <https://msdn.microsoft.com/en-us/library/z207t55f.aspx>`_ Note that what
  Microsoft calls "Wide Characters" and "Unicode" is actually valid-or-invalid
  UTF-16 as described above, *not* decoded Unicode code points.

- `Unicode and Character Sets > About Unicode and Character Sets > Character Sets
  <https://msdn.microsoft.com/en-us/library/windows/desktop/dd374069(v=vs.85).aspx>`_
  This often-cited page is not actually relevant to filesystem paths or
  environment variable values, and rather instead refers to how Windows
  applications deal with userland, not system, character data.


Copyright
=========

Copyright © 2017 See Contributors List

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Contributors
============

Daniel Kahn Gillmor

Daniel Shahaf

HW42

Ian Jackson

Ximin Luo


Appendix
============

Test vectors
------------

Here are test vectors for implementations to check their correctness. They are
also available as part of an executable test suite in `our git repository
<https://anonscm.debian.org/cgit/reproducible/build-path-prefix-map-spec.git>`_.
They are intended for guidance and *not* as a substitute to the above
specification. In particular, it may be possible to match the behaviour
described below exactly but still violate the specification.

In the prescriptions below, statements of the form "E maps I to O" mean that
when E is set as the value of ``BUILD_PATH_PREFIX_MAP``, then a compliant
consumer implementing either algorithm 1 or 2 from *Applying the decoded
structure*, maps line-separated input paths I to line-separated output paths O.
Where E is wrapped by ``b'`` and ``'``, it is to be interpreted as a sequence
of bytes, represented in the same way as Python byte literals.

