use std::mem;

use ::alloc;

pub struct Vec<T> {
	buf: *mut T,
	len: usize,
	cap: usize,
}

impl<T> Vec<T> {
	fn new(cap: usize) -> Vec<T> {
		let alloc_len = cap.checked_mul(mem::size_of::<T>());
		match alloc_len {
			Some(l) => Vec { 
				// better use checked_mul to catch overflow error
				buf: alloc::alloc(cap * mem::size_of::<T>()) as *mut T, 
				len: 0, 
				cap: cap 
			},
			_ => panic!("vector capacity overflow!")
		}
	}
}
