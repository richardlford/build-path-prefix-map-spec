#include "prefix_map.h"
#include <errno.h>

/* Parsing the variable. */
/* For Applying the variable, see prefix_map.h. */

int
unquote (char *src)
{
  for (char *dest = src; 0 != (*dest = *src); ++dest, ++src)
    switch (*src)
      {
      case ':':
      case '=':
	return 0; // should have been escaped
      case '%':
	switch (*(src + 1))
	  {
	  case ';':
	    *dest = ':';
	    goto unquoted;
	  case '+':
	    *dest = '=';
	  unquoted:
	  case '%':
	    ++src;
	  }
      }
  return 1;
}

int
parse_prefix_map (char *arg, struct prefix_map *map)
{
  char *p;
  p = strchr (arg, '=');
  if (!p)
    return 0;
  *p = '\0';
  if (!unquote (arg))
    return 0;
  map->old_prefix = xstrdup (arg);
  map->old_len = strlen (arg);
  p++;
  if (!unquote (p))
    return 0;
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

  char *sep = ":", *end;
  char *tok = strtok_r (copy, sep, &end);
  while (tok != NULL)
    {
      struct prefix_map *map = XNEW (struct prefix_map);
      if (!parse_prefix_map (tok, map))
	{
	  fprintf (stderr, "invalid value for prefix-map: '%s'\n", arg);
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
