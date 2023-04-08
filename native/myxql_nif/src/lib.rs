extern crate rustler;

use rustler::{Env, Term};
use rustler::types::Binary;

rustler::init!(
    "Elixir.MyXQL.Protocol.ValuesNif",
    [
        take_int_lenenc_nif
    ],
    load = load
);

fn load(_env: Env, _info: Term) -> bool {
    true
}

#[rustler::nif]
fn take_int_lenenc_nif(binary: Binary) -> u64 {
    println!("binary {}", binary[0]);
    return 1
}
