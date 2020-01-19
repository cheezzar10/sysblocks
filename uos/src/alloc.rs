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

			if (*curr_blk).size > size_blocks {
				println!("allocating in free block of size {} > {}", (*curr_blk).size, size_blocks);

				// adjusting current block available space (allocated blocks + header block)
				(*curr_blk).size -= size_blocks + 1;

				// advancing pointer to the start of allocated block header
				alloc_blk = curr_blk.wrapping_add((*curr_blk).size + 1);
				(*alloc_blk).size = size_blocks;

				println!("allocated block header addr = {:p}", alloc_blk);
				break;
			}

			// TODO add exact size matching case
		}

		if !alloc_blk.is_null() {
			alloc_blk.wrapping_add(1) as *mut u8
		} else {
			alloc_blk as *mut u8
		}
	}

	pub unsafe fn dealloc(&self, ptr: *mut u8) {
		println!("deallocating memory block with addr = {:p}", ptr);

		// free list search pointers
		let mut prev_blk = self.free_block;
		let mut curr_blk = (*prev_blk).next;

		// getting pointer to the deallocating block header
		let dealloc_block: *mut Header = (ptr as *mut Header).wrapping_sub(1);
		println!("deallocating memory block header addr = {:p}", dealloc_block);

		loop {
			// free list wrap around condition
			if prev_blk >= curr_blk {
				(*prev_blk).next = dealloc_block;
				(*dealloc_block).next = curr_blk;
				break;
			}
		}
	}
}

// TODO rename to MemBlock
struct Header {
	next: *mut Header,
	size: usize
}
