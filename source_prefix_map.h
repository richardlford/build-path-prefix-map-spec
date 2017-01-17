/* This file also contains C code, in a real implementation it would be split. */

/* Some memory management primitives, basically copied from GCC. */

#include <malloc.h>
#include <alloca.h> // this is non-standard but is included in the GCC sources
#include <string.h>

#define XNEW(T)			((T *) malloc (sizeof (T)))
#define XNEWVEC(T, N)		((T *) malloc (sizeof (T) * (N)))

char *
xstrdup (const char *s)
{
  register size_t len = strlen (s) + 1;
  register char *ret = XNEWVEC (char, len);
  return (char *) memcpy (ret, s, len);
}

char *
xstrndup (const char *s, size_t n)
{
  char *result;
  size_t len = strlen (s);

  if (n < len)
    len = n;

  result = XNEWVEC (char, len + 1);

  result[len] = '\0';
  return (char *) memcpy (result, s, len);
}

/* Rest of it, including Applying the variable */

struct prefix_map
{
  const char *old_prefix;
  const char *new_prefix;
  size_t old_len;
  size_t new_len;
  struct prefix_map *next;
};

const char *
apply_prefix_map (const char *old_name, char *new_name,
		  struct prefix_map *map_head)
{
  struct prefix_map *map;
  const char *name;

  for (map = map_head; map; map = map->next)
    if (strncmp (old_name, map->old_prefix, map->old_len) == 0)
      break;
  if (!map)
    return old_name;

  name = old_name + map->old_len;
  memcpy (new_name, map->new_prefix, map->new_len);
  memcpy (new_name + map->new_len, name, strlen (name) + 1);
  return new_name;
}

struct prefix_maps
{
  struct prefix_map *head;
  size_t max_replace;
};

void
add_prefix_map (struct prefix_map *map, struct prefix_maps *maps)
{
  map->next = maps->head;
  maps->head = map;

  if (map->new_len > maps->max_replace)
    maps->max_replace = map->new_len;
}

/*
 * This function does not consume nor take ownership of filename; the caller is
 * responsible for freeing it, if and only if it was already responsible for
 * freeing it before the call.
 *
 * It allocates new memory only in the case that a mapping was made. That is,
 * if and only if filename != return-value, then the caller is responsible for
 * freeing return-value.
*/
const char *
remap_prefix_alloc (const char *filename, struct prefix_maps *maps, void *(*alloc)(size_t size))
{
  size_t maxlen = strlen (filename) + maps->max_replace + 1;
  char *newname = (char *) alloca (maxlen);
  const char *name = apply_prefix_map (filename, newname, maps->head);

  if (name == filename)
    return filename;

  size_t len = strlen (newname) + 1;
  return (char *) memcpy (alloc (len), newname, len);
}

// Like remap_prefix_alloc but with the system allocator.
const char *
remap_prefix (const char *filename, struct prefix_maps *maps)
{
  return remap_prefix_alloc (filename, maps, malloc);
}

#include <stdlib.h>
#include <stdio.h>

/*
 * Run as one of:
 *
 * $ SOURCE_PREFIX_MAP=${map} ./main ${path0} ${path1} ${path2}
 * $ printf "${map}\0${path0}\0${path1}\0${path2}\0" | ./main -
 */
int
generic_main (int (*parse_prefix_maps) (const char *, struct prefix_maps *), int argc, char *argv[])
{
  struct prefix_maps source_prefix_map = { NULL, 0 };

  int using_stdin = 0; // 0 = SOURCE_PREFIX_MAP envvar, 1 = stdin (for afl)
  char *mapstr = NULL;
  if (argc > 1 && strncmp (argv[1], "-", 1) == 0)
    {
      size_t len = 0;
      getdelim (&mapstr, &len, 0, stdin);
      if (ferror (stdin))
	goto err_stdin;
      using_stdin = 1;
    }
  else
    mapstr = getenv ("SOURCE_PREFIX_MAP");

  if (mapstr)
    if (!parse_prefix_maps (mapstr, &source_prefix_map))
      {
	fprintf (stderr, "parse_prefix_maps failed\n");
	return 1;
      }

  if (using_stdin)
    {
      free (mapstr); // as per contract of getdelim()

      char *arg = NULL;
      size_t len = 0;
      while (getdelim (&arg, &len, 0, stdin) != -1)
	{
	  printf ("%s\n", remap_prefix (arg, &source_prefix_map));
	}

      if (ferror (stdin))
	goto err_stdin;
    }
  else
    {
      for (int i = using_stdin ? 2 : 1; i < argc; i++)
	{
	  //fprintf (stderr, "%s", argv[i]);
	  printf ("%s\n", remap_prefix (argv[i], &source_prefix_map));
	}
    }

  return 0;

err_stdin:
  perror ("failed to read from stdin");
  return 1;
}
