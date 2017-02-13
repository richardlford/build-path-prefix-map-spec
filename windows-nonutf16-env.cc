/* Test Windows environment variables with invalid UTF-16 characters.
 *
 * On GNU/linux, install mingw32 then compile with
 * $ x86_64-w64-mingw32-g++ -static-libstdc++ -static-libgcc test.c
 *
 * Expected output:
 * $ wine a.exe
 * first character: 0xdcf1
 * subsequent characters: testing
 */
#include <stdlib.h>
#include <stdio.h>

int main() {
  wchar_t* envvar;
  size_t requiredSize;

  _wputenv_s (L"my_special_envvar", L"\xdcf1testing"); // not valid UTF-16

  _wgetenv_s (&requiredSize, NULL, 0, L"my_special_envvar");
  envvar = (wchar_t*) malloc (requiredSize * sizeof (wchar_t));
  _wgetenv_s (&requiredSize, envvar, requiredSize, L"my_special_envvar");

  printf ("first character: 0x%x\n", envvar[0]);
  printf ("subsequent characters: %S\n", (envvar + 1));
  return 0;
}
