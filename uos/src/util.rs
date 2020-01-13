const RING_BUF_LEN: usize = 16;

pub struct RingBuf {
	buf: [u8; RING_BUF_LEN],
	rpos: usize,
	wpos: usize
}

impl RingBuf {
	pub const fn new() -> RingBuf {
		RingBuf { buf: [0; RING_BUF_LEN], rpos: 0, wpos: 0 }
	}

	pub fn push_back(&mut self, b: u8) {
		self.buf[self.wpos] = b;
		Self::adv(&mut self.wpos);
	}

	pub fn pop_front(&mut self) -> Option<u8> {
		if self.rpos == self.wpos {
			None
		} else {
			let rv = Some(self.buf[self.rpos]);
			Self::adv(&mut self.rpos);
			rv
		}
	}

	fn adv(pos: &mut usize) {
		if ((*pos + 1) & RING_BUF_LEN) != 0 {
			// wrapping buffer position around
			*pos = 0;
		} else {
			*pos += 1;
		}
	}
}
