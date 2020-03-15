extern crate libc;

use std::time;
use std::process;

fn signal_handler(sig: libc::c_int) {
	println!("signal trapped: {}", sig);
	process::abort();
}

fn main() {
    println!("Hello, world!");
	
	let cur_time = time::SystemTime::now();
	let ttime = cur_time.duration_since(time::UNIX_EPOCH).unwrap();
	println!("time = {}", ttime.as_secs());
	
	let rnd: libc::c_int;
	unsafe {
		libc::srand(ttime.as_secs() as libc::c_uint);
		rnd = libc::rand();
	}
	
	unsafe {
		libc::signal(libc::SIGSEGV, signal_handler as usize);
		
		let ptr = 0 as *const u64;
		println!("mem = {}", *ptr);
	}
	
	println!("rnd = {}", rnd);
}
