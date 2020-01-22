use std::ptr;
use std::mem;

pub struct Allocator {
	mem_size: usize,
	free_block: *mut Header
}

impl Allocator {
	pub const fn new(mem: *mut u8, mem_sz: usize) -> Allocator {
		Allocator { mem_size: mem_sz, free_block: mem as *mut Header }
	}

	pub unsafe fn alloc(&self, size: usize) -> *mut u8 {
		println!("allocating {} bytes", size);
		println!("header struct size: {} bytes", mem::size_of::<Header>());

		let free_blk: &mut Header = match self.free_block.as_mut() {
			Some(r) => r,
			// _ => panic!("allocator managed memory block is null!")
			_ => return ptr::null_mut()
		};

		// !!! this code will work only if managed memory area is zeroed
		if free_blk.size == 0 {
			free_blk.size = (self.mem_size - mem::size_of::<Header>()) / mem::size_of::<Header>();
			println!("free list initialized: {} blocks available", free_blk.size);

			// currently head block is also the tail block, making it point to itself
			free_blk.next = self.free_block;
		}

		// TODO fix me, should proper align this memory block, try to use ptr::align_offset
		let size_blocks = size / mem::size_of::<Header>();
		println!("trying to allocate {} blocks", size_blocks);

		// free list search pointers
		let mut prev_blk = self.free_block;
		let mut curr_blk = (*prev_blk).next;

		// pointer to newly allocated block
		let mut alloc_blk: *mut Header = ptr::null_mut();
		loop {
			println!("prev = {:p}, curr = {:p}", prev_blk, curr_blk);

			if (*curr_blk).size == size_blocks {
				println!("found free block of exact size {} = {}", (*curr_blk).size, size_blocks);
				
				alloc_blk = curr_blk;
				println!("allocated block header addr = {:p}", alloc_blk);
				
				(*prev_blk).next = (*curr_blk).next;
				
				break;
			}

			if (*curr_blk).size > size_blocks {
				println!("found suitable free block of size {} > {}", (*curr_blk).size, size_blocks);

				// adjusting current block available space (allocated blocks + header block)
				(*curr_blk).size -= size_blocks + 1;

				// advancing pointer to the start of allocated block header
				alloc_blk = curr_blk.wrapping_add((*curr_blk).size + 1);
				(*alloc_blk).size = size_blocks;

				println!("allocated block header addr = {:p}", alloc_blk);
				break;
			}

			if curr_blk == self.free_block {
				println!("allocation failed");
				// list wrapped around
				break;
			}
			
			// advancing further
			prev_blk = curr_blk;
			curr_blk = (*curr_blk).next;
		}

		if !alloc_blk.is_null() {
			alloc_blk.wrapping_add(1) as *mut u8
		} else {
			alloc_blk as *mut u8
		}
	}

	pub unsafe fn dealloc(&self, ptr: *mut u8) {
		println!("deallocating memory at addr = {:p}", ptr);

		// free list search pointers
		let mut prev_blk = self.free_block;
		let mut curr_blk = (*prev_blk).next;

		// getting pointer to the deallocating block header
		let dealloc_blk: *mut Header = (ptr as *mut Header).wrapping_sub(1);
		println!("found deallocating memory block at addr = {:p} of size {}", dealloc_blk, (*dealloc_blk).size);

		while prev_blk < curr_blk {
			println!("prev = {:p}, curr = {:p}", prev_blk, curr_blk);

			// found deallocating block position in free list
			if prev_blk < dealloc_blk && curr_blk > dealloc_blk {
				println!("deallocating memory block is placed between blocks {:p} and {:p}", prev_blk, curr_blk);
				break;
			}
			
			// advancing further
			prev_blk = curr_blk;
			curr_blk = (*curr_blk).next;
		}

		if prev_blk.wrapping_add((*prev_blk).size + 1) == dealloc_blk {
			println!("merging deallocating memory block with previous block of size = {}", (*prev_blk).size);

			(*prev_blk).size += (*dealloc_blk).size + 1;
		} else if dealloc_blk.wrapping_add((*dealloc_blk).size + 1) == curr_blk {
			println!("merging deallocating memory block with next block of size = {}", (*curr_blk).size);
			
			(*dealloc_blk).size += (*curr_blk).size + 1;
			
			(*prev_blk).next = dealloc_blk;
			(*dealloc_blk).next = (*curr_blk).next;
		} else {
			println!("deallocating memory block added to free list: prev = {:p}, next = {:p}", prev_blk, curr_blk);

			(*prev_blk).next = dealloc_blk;
			(*dealloc_blk).next = curr_blk;
		}
	}
}

// TODO rename to MemBlock
struct Header {
	next: *mut Header,
	size: usize
}

#[cfg(test)]
mod tests {
	use std::mem::*;

	use ::alloc::*;

	struct Task {
		tid: usize,
		stack: *mut u32
	}

	struct TaskState {
		eax: u32,
		ebx: u32,
		ecx: u32,
		edx: u32
	}

	#[test]
	fn test_first_alloc_dealloc() {
		let mut mem: [u8; 64] = [0; 64];
		// saving our local memory origin pointer
		let mem_org: *const u8 = mem.as_ptr();

		let a = Allocator::new(mem.as_mut_ptr(), size_of_val(&mem));

		// cargo test -- --nocapture to see error messages
		println!("task struct size = {}", size_of::<Task>());

		assert_eq!(8, size_of::<Task>());
		assert_eq!(16, size_of::<TaskState>());
	
		unsafe {
			let task_raw_ptr = a.alloc(size_of::<Task>());
			let task_ptr: *mut Task = task_raw_ptr as *mut Task;
			if let Some(task_ref) = task_ptr.as_mut() {
				assert_eq!(0, task_ref.tid);

				// checking allocated memory block location
				assert_eq!(mem_org.wrapping_add(7 * size_of::<Task>()), task_raw_ptr);
				// checking allocated block header validity
				let mem_blk: *mut Header = task_ptr.wrapping_sub(1) as *mut Header;
				assert_eq!(1, (*mem_blk).size);

				task_ref.tid = 1;
				task_ref.stack = 0xffff as *mut u32;
			}
		}
	}

	#[test]
	fn test_alloc_two_small_and_dealloc() {
		let mut mem: [u8; 64] = [0; 64];
		let mem_ptr: *const u8 = mem.as_ptr();
		let head_mem_blk: *const Header = mem_ptr as *const Header;

		let allocator = Allocator::new(mem.as_mut_ptr(), size_of_val(&mem));

		unsafe {
			let task1_mem_ptr = allocator.alloc(size_of::<Task>());
			assert_eq!(5, (*head_mem_blk).size);

			let task2_mem_ptr = allocator.alloc(size_of::<Task>());
			assert_eq!(3, (*head_mem_blk).size);

			// memory layout check
			assert_eq!(mem_ptr.wrapping_add(7 * size_of::<Task>()), task1_mem_ptr);
			assert_eq!(mem_ptr.wrapping_add(5 * size_of::<Task>()), task2_mem_ptr);

			let task1_mem_blk: *mut Header = (task1_mem_ptr as *mut Task).wrapping_sub(1) as *mut Header;

			allocator.dealloc(task1_mem_ptr);

			// getting head of free list and checking that it's next link points to deallocated mem block
			assert_eq!(3, (*head_mem_blk).size);
			assert_eq!(task1_mem_blk, (*head_mem_blk).next);
			
		}
	}
}
