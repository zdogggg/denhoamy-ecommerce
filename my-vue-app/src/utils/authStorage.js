const REMEMBER_KEY = 'auth_remember'
const USER_KEY = 'auth_user'
export const AUTH_BROADCAST_KEY = 'auth_broadcast'

export function getAuthStorage() {
  return localStorage.getItem(REMEMBER_KEY) === '1' ? localStorage : sessionStorage
}

export function getStoredAuthUser() {
  if (localStorage.getItem(REMEMBER_KEY) === null && localStorage.getItem(USER_KEY)) {
    localStorage.setItem(REMEMBER_KEY, '1')
  }
  const raw = getAuthStorage().getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function clearStoredAuth() {
  localStorage.removeItem(USER_KEY)
  sessionStorage.removeItem(USER_KEY)
  localStorage.removeItem(REMEMBER_KEY)
}

export function broadcastAuthEvent(type) {
  const payload = JSON.stringify({ type, ts: Date.now() })
  localStorage.setItem(AUTH_BROADCAST_KEY, payload)
  localStorage.removeItem(AUTH_BROADCAST_KEY)
}
