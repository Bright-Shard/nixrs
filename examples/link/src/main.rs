mod ffi;

use {
    ffi::*,
    std::{
        ffi::CString,
        io::{self, Write as _},
        mem, ptr,
    },
};

fn main() {
    let state = unsafe { luaL_newstate() }.unwrap();
    unsafe { luaL_openlibs(state) };
    println!("Running Lua v{}", unsafe { lua_version(state) });

    let mut input = String::new();
    let stdin = io::stdin();

    loop {
        print!("> ");
        io::stdout().flush().unwrap();
        input.clear();
        stdin.read_line(&mut input).unwrap();

        if input == "" {
            println!("\nBye!");
            break;
        }

        unsafe {
            luaL_loadstring(state, CString::new(input.as_str()).unwrap().as_ptr());
            lua_callk(state, 0, 0, 0, unsafe { mem::transmute(ptr::null::<()>()) });
        }
    }
}
