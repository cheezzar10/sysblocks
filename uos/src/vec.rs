use std::mem;
use std::ptr;
use std::fmt;
use std::ops;
use std::slice;

use ::alloc;

pub struct Vec<T> {
	buf: *mut T,
	len: usize,
	cap: usize,
}

impl<T> Vec<T> {
	pub fn new(cap: usize) -> Vec<T> {
		let alloc_bytes = cap.checked_mul(mem::size_of::<T>());

		match alloc_bytes {
			Some(cap_bytes) => {
				println!("allocating {} bytes", cap_bytes);

				Vec { 
					buf: alloc::alloc(cap_bytes) as *mut T, 
					len: 0, 
					cap: cap 
				}
			},
			_ => panic!("vector capacity overflow!")
		}
	}

	pub fn push(&mut self, val: T) {
		// TODO double vector capacity if len == cap

		println!("vector buffer addr: {:p}", self.buf);

		let val_addr = self.buf.wrapping_add(self.len);
		println!("inserting element location addr: {:p}", val_addr);

		unsafe {
			ptr::write(val_addr, val);
		}

		self.len += 1;
	}

	pub fn swap(&mut self, i: usize, j: usize) {
		assert!(i >= 0 && i < self.len, "first index is out of bounds");
		assert!(j >= 0 && j < self.len, "second index is out bounds");

		if (i != j) {
			let i_addr = self.buf.wrapping_add(i);
			let j_addr = self.buf.wrapping_add(j);

			unsafe {
				ptr::swap_nonoverlapping(i_addr, j_addr, 1);
			}
		}
	}

	pub fn pop(&mut self) -> Option<T> {
		if self.len == 0 {
			None
		} else {
			// we can use mem::uninitialized or zeroed to create temporary value
			let val_ptr = self.buf.wrapping_add(self.len - 1);
			self.len -= 1;

			unsafe {
				// may be we should use mem::forget/mem::drop to properly release
				Some(ptr::read(val_ptr))
			}
		}
	}

	pub fn len(&self) -> usize {
		self.len
	}

	pub fn cap(&self) -> usize {
		self.cap
	}
}

impl<T> ops::Deref for Vec<T> {
	type Target = [T];

	fn deref(&self) -> &[T] {
		unsafe {
			slice::from_raw_parts(self.buf, self.len)
		}
	}
}

#[cfg(test)]
mod tests {
	use ::vec::*;

	struct Task {
		tid: usize,
		state: TaskState
	}

	impl fmt::Display for Task {
		fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
			write!(f, "Task: @{:p} {{ tid: {}, state: {} }}", self, self.tid, self.state)
		}
	}

	struct TaskState {
		ebx: u32,
		edx: u32,
		ecx: u32,
		eax: u32,
		eip: u32,
		cs: u32,
		eflags: u32
	}

	impl fmt::Display for TaskState {
		fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
			write!(f, "TaskState: {{ ebx: {:x}, edx: {:x}, ecx: {:x}, eax: {:x}, eip: {:x}, cs: {:x}, eflags: {:x} }}",
				self.ebx, self.edx, self.ecx, self.eax, self.eip, self.cs, self.eflags)
		}
	}

	#[test]
	fn test_new_vec() {
		let mut tasks: Vec<Task> = Vec::new(16);

		assert_eq!(0, tasks.len());
		assert_eq!(16, tasks.cap());

		let task = Task {
			tid: 1,
			state: TaskState {
				ebx: 0,
				edx: 0,
				ecx: 0,
				eax: 0,
				eip: 0,
				cs: 0,
				eflags: 0
			}
		};

		tasks.push(task);

		assert_eq!(1, tasks.len());

		let tasks_slice = &tasks;
		for (i, t) in (&tasks_slice).iter().enumerate() {
			println!("task: {}", t);
			assert_eq!(i+1, t.tid);
		}

		assert_eq!(1, tasks_slice[0].tid);

		// copying state of task
		let another_task = Task {
			tid: 2,
			state: TaskState {
				..tasks[0].state
			}
		};

		tasks.push(another_task);

		assert_eq!(2, tasks.len());

		tasks.swap(0, 1);

		assert_eq!(2, tasks[0].tid);
		assert_eq!(1, tasks[1].tid);
		assert_eq!(2, tasks.len);

		let popped_task = tasks.pop();
		match popped_task {
			Some(t) => assert_eq!(1, t.tid),
			None => panic!("none returned")
		}
		assert_eq!(1, tasks.len());
	}

	#[test]
	#[should_panic]
	fn test_vec_checks() {
		let mut tasks: Vec<Task> = Vec::new(4);

		// should panic here
		tasks.swap(0, 1);
	}
}
