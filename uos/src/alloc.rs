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
