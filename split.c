#include "source_prefix_map.h"
#include <stdlib.h>
#include <stdio.h>

/* Parsing the variable. */
/* For Applying the variable, see source_prefix_map.h. */

int
parse_prefix_map (const char *arg, struct prefix_map *map)
{
  const char *p;
  p = strrchr (arg, '=');
  if (!p)
    return 0;
  map->old_prefix = xstrndup (arg, p - arg);
  map->old_len = p - arg;
  p++;
  map->new_prefix = xstrdup (p);
  map->new_len = strlen (p);
  return 1;
}

int
parse_prefix_maps (const char *arg, struct prefix_maps *maps)
{
  size_t len = strlen (arg);
  char *copy = (char *) alloca (len + 1);
  memcpy (copy, arg, len + 1); // strtok modifies the string so we have to copy it

  char *sep = "\t", *end;
  char *tok = strtok_r (copy, sep, &end);
  while (tok != NULL)
    {
      struct prefix_map *map = XNEW (struct prefix_map);
      if (!parse_prefix_map (tok, map))
	{
	  fprintf (stderr, "invalid value for prefix-map: %s\n", tok);
	  free (map);
	  return 0;
	}

      add_prefix_map (map, maps);
      tok = strtok_r (NULL, sep, &end);
    }

  return 1;
}

int
main (int argc, char *argv[])
{
  struct prefix_maps source_prefix_map = { NULL, 0 };

  const char *arg;
  arg = getenv ("SOURCE_PREFIX_MAP");
  if (arg)
    if (!parse_prefix_maps (arg, &source_prefix_map))
      {
	fprintf (stderr, "parse_prefix_map failed\n");
	return 1;
      }

  for (int i = 1; i < argc; i++)
    {
      fprintf (stderr, "%s", argv[i]);
      printf ("%s\n", remap_prefix (argv[i], &source_prefix_map));
    }

  return 0;
}
