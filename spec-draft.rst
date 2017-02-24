Specification
=============

This specification describes an environment variable ``BUILD_PATH_PREFIX_MAP``
which may be used by build tools to generate reproducible output that does not
include any paths that are dependent on the build-time filesystem layout.

A *producer* is a program that knows how to determine appropriate values for
this environment variable, such as a top-level distribution package builder,
and which can then pass these values to child processes that consume them.

A *consumer* is a program that relies on appropriate values for this variable
to be set by a higher level build tool, and which then can generate output that
is reproducible, independent of the filesystem layout of the build machine.

The actual value of this environment variable MUST NOT be saved into any output
meant to form part of a reproducible binary artefact.


Encoding and decoding the variable
----------------------------------

This section describes a data structure encoding, from a list-of-pairs where
each pair holds two strings, into a single string.

We use the phrases "left"- and "right end of the list", to respectively refer
to the parts of the list that correspond to the left (start) and right (end)
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
injective. See [2]_ for further details and guidance on how to do this.

The encoding is as follows:

- The ``:`` character separates encoded list items from each other.

  Empty subsequences between ``:`` characters, or between a ``:`` character and
  either the left or right end of the envvar, are valid and are ignored. [3]_

- Each encoded list item contains exactly one ``=`` character, that separates
  encoded pair elements.

  If there are zero or more than one ``=`` characters, this is a parse error
  and the whole environment variable is invalid. [4]_ In this case, the program
  should exit with an error code appropriate for the context, or if this is not
  possible then it must communicate the error in some way to the caller.

  The encoded pair elements may be empty; this does not need special-casing if
  the rest of the document is implemented correctly.

- Each encoded pair element is encoded with the following mapping:

  1. ``%`` → ``%#``
  2. ``=`` → ``%+``
  3. ``:`` → ``%.``

  When decoding, ``%`` characters at the end of a string are a parse error, as
  are ``%[X]`` substrings where ``[X]`` is any character not in ``#+.``.

  This encoding allows paths containing ``%``, ``=``, ``:`` to be mapped; since
  users may want to run their builds under such paths. However as a producer,
  if this is not possible for your users (e.g. because you directly restrict
  possible build paths) then you may avoid implementing this encoding logic.

  Implementation notes: due to our choice of characters, there is flexibility
  in the order in which these mappings may be applied; this is meant to ease
  implementation in a variety of programming languages. The only restriction is
  that the ``%`` → ``%#`` mapping for encoding must not be applied on
  already-encoded %-substrings; and that the ``%+`` → ``=``, ``%.`` → ``:``
  mappings for decoding must not be applied on already-decoded %-substrings.

  Our recommended approach for a high-level language with string replace:

  A. decoding:

     1. check elem does not match the regex ``/%[^#+.]|%$/g``, then
     2. ``elem.replace("%.", ':').replace("%+", '=').replace("%#", '%')``

  B. encoding:

     1. ``elem.replace("%#", '%').replace("%+", '=').replace("%.", ':')``

  Our recommended approach for a low-level language without string replace:

  A. decoding:

     - one single left-to-right pass with lookahead (e.g. our C example), or
     - one single left-to-right pass with lookbehind (e.g. our Rust example)

  B. encoding:

     we don't anticipate this to be a major use-case


Setting the encoded value
-------------------------

Producers SHOULD NOT overwrite existing values; instead they should append
their new mappings onto the right of any existing value.

Producers who build *general software* that uses this envvar, MUST NOT expect
any special contracts on the output emitted by *general consumers* based on
this variable - only that their output be reproducible when the build path
changes and the value of this envvar is changed to match the new paths.

On the other hand, if you know you will only support a limited set of
consumers, you may expect that they apply these mappings in specific ways.

See also the requirements for consumers in the next part for guidance.


Applying the decoded structure
------------------------------

Consumers MUST ensure that, at minimum: for all (*source*, *target*) prefix
pairs in the parsed list, with rightmost pairs taking priority: strings in the
final build output, that represent build-time paths derived from "source",
instead appear to represent potential run-time paths derived from "target".

As a consequence, consumers MUST apply mappings as above, regardless of whether
the *source* prefix ends with a directory separator or not.

We do not define "derived from" more specifically, since this may be different
for different consumers (languages, buildsystems, etc), and a more specific
definition might conflict with their idea of what that means.

Consumers SHOULD implement one of the following algorithms:

1. For each (source, target) prefix pair in the list-of-pairs, going from right
   to left: if the subject path starts with the source prefix, then replace
   this occurence with the target prefix, and return this new path, ignoring
   any pairs further left in the list.

2. As in (1) but with "starts with" replaced by "starts with, restricted to
   whole-path components". So for example,

   - ``/path/to/a/b/c`` "starts with" ``/path/to/a``
   - ``/path/to/aa/b/c`` does not "start with" ``/path/to/a``

   This has more robust semantics but is slightly more complex to implement.


Test vectors
============

TODO


Notes and links
===============

.. [1] In practice, this means any two byte sequences that are invalid UTF-8,
    or ``wchar_t`` sequences that are invalid UTF-16, are decoded into distinct
    application-level character string values. This is not satisfied by most
    standard Unicode decoding strategies, which is to replace all invalid input
    sequences with ``U+FFFD REPLACEMENT CHARACTER``.

.. [2] Detailed implementation notes and advice are available on `our wiki page
    <https://wiki.debian.org/ReproducibleBuilds/BuildPathProposal#Implementation_notes>`_.
    Example source code is also available on the above page, as well as in
    runnable form in `our git repository
    <https://anonscm.debian.org/git/reproducible/standards.git/tree/build-path-prefix-map>`_.

.. [3] This is to make it easier for producers to append values, e.g. as in
    ``envvar += ":" + encoded_pair`` which would be valid even if envvar is
    originally empty.

.. [4] This is to "fail early" in the cases that a naive producer does not
    encode characters like ``=`` but the build path or target path does
    actually contain them.


References
==========

POSIX system strings
--------------------

- `Definitions (no HTTPS)
  <http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html>`_
  - see "Pathname", "String" and "Byte".

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
deprecated (no HTTPS) <http://unicode.org/faq/utf_bom.html#utf16-1>`_.

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
