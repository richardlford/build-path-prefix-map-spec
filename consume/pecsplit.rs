/* TODO: this needs an actual Rust person to review it first. I am a Rust newbie. */

use std::ffi::OsString;
use std::path::PathBuf;
use std::os::unix::ffi::{OsStrExt, OsStringExt}; // TODO: windows

fn pathbuf_to_u8(path: &PathBuf) -> &[u8] {
  path.as_os_str().as_bytes() // TODO: windows
}

/** Parsing the variable */

/* the polymorphism is to handle u8 (POSIX) and u16 (windows) */
fn dequote<T>(s: &[T]) -> Result<Vec<T>, &'static str> where u16: From<T>, T: From<u8>, T: Copy {
  // unfortunately we can't do sting-replace on arbitrary Vecs
  // s.replace("%.", ':').replace("%+", '=').replace("%#", '%')
  let mut v = Vec::with_capacity(s.len());
  let mut escaped = false;
  for c in s {
    v.push(*c);
    let c16 = u16::from(*c);
    match c16 {
      0x3A /* : */ => unreachable!(),
      0x3D /* = */ => unreachable!(),
      _ => if escaped {
        match c16 {
          0x23 /* # */ => { v.pop(); v.pop(); v.push(T::from(b'%')) },
          0x2B /* + */ => { v.pop(); v.pop(); v.push(T::from(b'=')) },
          0x2E /* . */ => { v.pop(); v.pop(); v.push(T::from(b':')) },
          _ => break // to the "Err" clause
        }
      }
    }
    escaped = c16 == 0x25
  }
  if escaped {
    Err("invalid %-escape sequence")
  } else {
    v.shrink_to_fit();
    Ok(v)
  }
}

fn decode(prefix_str: Option<OsString>) -> Result<Vec<(PathBuf, PathBuf)>, &'static str> {
  prefix_str.unwrap_or(OsString::new())
    .as_os_str().as_bytes() // TODO: windows
    .split(|b| *b == b':')
    .filter(|part| !part.is_empty())
    .map(|part| {
      let tuple = part
        .split(|b| *b == b'=')
        .collect::<Vec<_>>();
      if tuple.len() != 2 {
        Err("either too few or too many '='")
      } else {
        // TODO: windows
        let src = OsString::from_vec(try!(dequote(tuple[0])));
        let dst = OsString::from_vec(try!(dequote(tuple[1])));
        Ok((PathBuf::from(src), PathBuf::from(dst)))
      }
    })
    .collect::<Result<Vec<_>, _>>()
}

/** Applying the variable */

fn map_prefix(path: PathBuf, pm: &Vec<(PathBuf, PathBuf)>) -> PathBuf {
  for pair in pm.iter().rev() {
    let (ref src, ref dst) = *pair;
    if path.starts_with(src) {
      /* FIXME: this is different from what our other language examples do;
       * rust's [PathBuf.starts_with] only matches whole components. however
       * these all behave the same for our test cases.
       */
      return dst.join(path.strip_prefix(src).unwrap())
    }
  }
  path
}

/** Main program */

fn main() {
  use std::env;
  use std::io::{Write, stdout, stderr};

  let pm = decode(env::var_os("BUILD_PATH_PREFIX_MAP"))
    .unwrap_or_else(|msg| {
      writeln!(stderr(), "{}", msg).unwrap();
      std::process::exit(1)
    });

  //writeln!(&mut std::io::stderr(), "pm = {:?}", pm).unwrap();
  for arg in env::args_os().skip(1) {
    let path = map_prefix(PathBuf::from(arg), &pm);
    stdout().write_all(pathbuf_to_u8(&path)).unwrap();
    stdout().write_all(b"\n").unwrap();
  }
}
