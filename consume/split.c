#include "source_prefix_map.h"

/* Parsing the variable. */
/* For Applying the variable, see source_prefix_map.h. */

int
parse_prefix_map (const char *arg, struct prefix_map *map)
{
  const char *p;
  p = strrchr (arg, '='); // right-split, to allow for more mapping sources
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
	  fprintf (stderr, "invalid value for prefix-map: '%s'\n", tok);
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
  return generic_main (parse_prefix_maps, argc, argv);
}
