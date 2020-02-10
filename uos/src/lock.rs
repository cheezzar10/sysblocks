use std::sync::atomic;
use std::thread;
use std::ops;

pub struct Mutex<T> {
	guarded: T,
	lock: atomic::AtomicBool
}

pub struct MutexGuard<'a, T> {
	mutex: &'a Mutex<T>
}

impl<T> Mutex<T> {
	pub const fn new(obj: T) -> Mutex<T> {
		Mutex {
			guarded: obj,
			lock: atomic::AtomicBool::new(false)
		}
	}

	pub fn lock(&self) -> MutexGuard<T> {
		println!("trying to lock mutex @{:p}", self);

		while self.lock.swap(true, atomic::Ordering::SeqCst) {
			thread::yield_now();
		}

		println!("mutex @{:p} locked", self);

		MutexGuard {
			mutex: self
		}
	}

	pub fn unlock(&self) {
		println!("unlocking mutex @{:p}", self);

		self.lock.store(false, atomic::Ordering::SeqCst);
	}
}

impl<'a, T> ops::Deref for MutexGuard<'a, T> {
	type Target = T;

	fn deref(&self) -> &T {
		&self.mutex.guarded
	}
}

impl<'a, T> ops::DerefMut for MutexGuard<'a, T> {
	fn deref_mut(&mut self) -> &mut T {
		let mtx_mut_ptr: *mut Mutex<T> = (self.mutex as *const Mutex<T>) as *mut Mutex<T>;

		unsafe {
			&mut (*mtx_mut_ptr).guarded
		}
	}
}

impl<'a, T> Drop for MutexGuard<'a, T> {
	fn drop(&mut self) {
		self.mutex.unlock()
	}
}

unsafe impl<T> Send for Mutex<T> {}

unsafe impl<T> Sync for Mutex<T> {}
