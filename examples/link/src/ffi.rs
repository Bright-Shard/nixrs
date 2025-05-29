#![allow(non_camel_case_types)]

use core::{
    ffi::{c_char, c_double, c_int, c_void},
    ptr::NonNull,
};

pub type lua_State = c_void;
pub type lua_Number = c_double;
pub type lua_KContext = isize;
pub type lua_KFunction =
    extern "C" fn(L: NonNull<lua_State>, status: c_int, ctx: lua_KContext) -> c_int;

#[link(name = "lua")]
unsafe extern "C" {
    pub fn luaL_newstate() -> Option<NonNull<lua_State>>;
    pub fn lua_version(L: NonNull<lua_State>) -> lua_Number;
    pub fn luaL_loadstring(L: NonNull<lua_State>, s: *const c_char) -> c_int;
    pub fn luaL_openlibs(L: NonNull<lua_State>);
    pub fn lua_callk(
        L: NonNull<lua_State>,
        nargs: c_int,
        nresults: c_int,
        ctx: lua_KContext,
        k: lua_KFunction,
    ) -> c_int;
}
