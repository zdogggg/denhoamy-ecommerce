let sessionExpiredHandler = null

export function setSessionExpiredHandler(fn) {
  sessionExpiredHandler = fn
}

export function triggerSessionExpired() {
  sessionExpiredHandler?.()
}
