#include "source_prefix_map.h"
#include <errno.h>

/* Parsing the variable. */
/* For Applying the variable, see source_prefix_map.h. */

int
unquote (char *src)
{
  char *dest = src;
  char x[] = {0, 0, 0};
  char c;
  while (*src != 0)
    {
      switch (*src)
	{
	case '+':
	  *dest = ' ';
	  break;
	case '&':
	case ';':
	case '=':
	  return 0; // invalid, should have been escaped
	case '%':
	  if (!(x[0] = *++src) || !(x[1] = *++src))
	    return 0; // invalid, past end of string
	  sscanf(x, "%2hhx", &c);
	  if (errno != 0)
	    return 0; // invalid, not valid hex
	  *dest = c;
	  break;
	default:
	  *dest = *src;
	}
      ++dest, ++src;
    }
  *dest = '\0';
  return 1;
}

int
parse_prefix_map (char *arg, struct prefix_map *map)
{
  char *p;
  p = strchr (arg, '='); // left-split, to match the urlencode algorithm
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

  char *sep = "&;", *end;
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
