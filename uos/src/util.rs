use std::sync::atomic::{ AtomicUsize, Ordering };
use std::cell::{ RefCell };

const RING_BUF_SIZE: usize = 16;

pub struct RingBuf {
	buf: RefCell<[u8; RING_BUF_SIZE]>,
	rpos: AtomicUsize,
	wpos: AtomicUsize
}

impl RingBuf {
	pub const fn new() -> RingBuf {
		RingBuf { 
			buf: RefCell::new([0; RING_BUF_SIZE]),
			rpos: AtomicUsize::new(0),
			wpos: AtomicUsize::new(0)
		}
	}

	pub fn push_back(&self, b: u8) {
		self.write_buf(b);
		Self::inc(&self.wpos);
	}

	// reducing mutable reference scope
	fn write_buf(&self, b: u8) {
		let mut buf_ref = self.buf.borrow_mut();
		buf_ref[self.wpos.load(Ordering::SeqCst)] = b;
	}

	pub fn pop_front(&self) -> Option<u8> {
		let rpos = self.rpos.load(Ordering::SeqCst);

		if rpos == self.wpos.load(Ordering::SeqCst) {
			None
		} else {
			let rv = Some(self.read_buf(rpos));
			Self::inc(&self.rpos);
			rv
		}
	}

	fn read_buf(&self, pos: usize) -> u8 {
		loop {
			let borrow_attempt_res = self.buf.try_borrow();

			if let Ok(buf_ref) = borrow_attempt_res {
				return buf_ref[pos]
			}
			// TODO here we should spin or suspend current task to make writer chance to make their work
		}
	}

	fn inc(pos: &AtomicUsize) {
		loop {
			let curr_pos = pos.load(Ordering::SeqCst);

			let new_pos = if ((curr_pos + 1) % RING_BUF_SIZE) == 0 {
				// wrapping buffer position around
				0
			} else {
				curr_pos + 1
			};

			let prev_pos = pos.compare_and_swap(curr_pos, new_pos, Ordering::SeqCst);
			if prev_pos == curr_pos {
				break;
			}
		}
	}
}

// may fail actually if writer and reader threads will be overlapped
unsafe impl Sync for RingBuf {}

#[cfg(test)]
mod tests {
	use super::*;

	#[test]
	fn test_ring_buf() {
		let kbd_buf = RingBuf::new();

		let missing_byte = kbd_buf.pop_front();
		if let Some(_) = missing_byte {
			panic!("attempt to get something from empty buffer returned something");
		}

		kbd_buf.push_back(b'p');
		kbd_buf.push_back(b's');

		// checking that we can read what has been written to buffer
		let some_byte = kbd_buf.pop_front();
		// println!("popped byte: {}", some_byte);
		assert_eq!(Some(b'p'), some_byte);
		assert_eq!(Some(b's'), kbd_buf.pop_front());

		// checking that buf is empty after reading all available bytes
		assert_eq!(None, kbd_buf.pop_front());
	}
}
