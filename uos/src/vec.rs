use std::mem;

use ::alloc;

pub struct Vec<T> {
	data_ptr: *mut T,
	size: usize,
	capacity: usize,
}

impl<T> Vec<T> {
	fn new(cap: usize) -> Self {
		Self { 
			data_ptr: alloc::alloc(cap * mem::size_of::<T>()) as *mut T, 
			size: 0, 
			capacity: cap 
		}
	}
}
