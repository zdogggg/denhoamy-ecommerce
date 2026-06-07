/**
 * Phase 2 smoke tests — chạy: node scripts/phase2-smoke.mjs
 */
const API = process.env.API_URL || 'http://127.0.0.1:8080'

let passed = 0
let failed = 0

function ok(name) {
  passed++
  console.log(`  ✓ ${name}`)
}

function fail(name, detail) {
  failed++
  console.error(`  ✗ ${name}${detail ? `: ${detail}` : ''}`)
}

function assert(cond, name, detail) {
  if (cond) ok(name)
  else fail(name, detail)
}

// --- Pure logic (mirror cart.js / ProductDetail computed) ---
function testCartHelpers() {
  console.log('\n[cart helpers]')
  const getProductId = (id) => (String(id).includes('_') ? String(id).split('_')[0] : String(id))
  const getVariantId = (id) => (String(id).includes('_') ? String(id).split('_')[1] : null)

  assert(getProductId('42_7') === '42', 'product id from composite')
  assert(getVariantId('42_7') === '7', 'variant id from composite')
  assert(getProductId('99') === '99', 'product id plain')
  assert(getVariantId('99') === null, 'no variant plain')
}

function testDisplayStockLogic() {
  console.log('\n[displayStock logic]')
  const calc = ({ hasVariants, currentVariant, productStock }) => {
    const needsVariantSelection = hasVariants && !currentVariant
    if (needsVariantSelection) return { stock: 0, label: 'Chọn phân loại' }
    const stock = currentVariant ? Number(currentVariant.stock) : Number(productStock)
    return { stock, label: `${stock} sản phẩm` }
  }

  assert(calc({ hasVariants: true, currentVariant: null, productStock: 50 }).label === 'Chọn phân loại', 'variant unselected label')
  assert(calc({ hasVariants: true, currentVariant: null, productStock: 50 }).stock === 0, 'variant unselected stock 0')
  assert(calc({ hasVariants: true, currentVariant: { stock: 3 }, productStock: 50 }).stock === 3, 'uses variant stock')
  assert(calc({ hasVariants: false, currentVariant: null, productStock: 10 }).stock === 10, 'no variant uses product stock')
}

function testAddCartLabel() {
  console.log('\n[addCartButtonLabel logic]')
  const label = (canPurchase, needsVariantSelection) => {
    if (canPurchase) return 'THÊM VÀO GIỎ'
    if (needsVariantSelection) return 'CHỌN PHÂN LOẠI'
    return 'HẾT HÀNG'
  }
  assert(label(false, true) === 'CHỌN PHÂN LOẠI', 'needs variant')
  assert(label(false, false) === 'HẾT HÀNG', 'out of stock')
  assert(label(true, false) === 'THÊM VÀO GIỎ', 'can purchase')
}

async function apiPost(path, body, token) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  const res = await fetch(`${API}${path}`, { method: 'POST', headers, body: JSON.stringify(body) })
  const data = await res.json().catch(() => ({}))
  return { status: res.status, data }
}

async function apiGet(path, params = {}, token) {
  const qs = new URLSearchParams(params).toString()
  const url = `${API}${path}${qs ? `?${qs}` : ''}`
  const headers = { Accept: 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  const res = await fetch(url, { headers })
  const data = await res.json().catch(() => ({}))
  return { status: res.status, data }
}

async function apiPut(path, body, token) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  const res = await fetch(`${API}${path}`, { method: 'PUT', headers, body: JSON.stringify(body) })
  const data = await res.json().catch(() => ({}))
  return { status: res.status, data }
}

async function login(username, password) {
  const { status, data } = await apiPost('/auth.php', { action: 'login', username, password })
  if (status !== 200 || !data.success || !data.token) return null
  return { token: data.token, user: data.user }
}

async function testApi() {
  console.log('\n[API smoke — ' + API + ']')

  // Public payment_status
  const ps = await apiGet('/orders.php', { action: 'payment_status', orderId: '12' })
  assert(ps.status === 200 && ps.data.success === true, 'GET payment_status public', JSON.stringify(ps.data))

  // Auth required endpoints
  const pendingNoAuth = await apiGet('/orders.php', { action: 'pending_payos' })
  assert(pendingNoAuth.status === 401, 'pending_payos requires auth', `status ${pendingNoAuth.status}`)

  const retryNoAuth = await apiPost('/orders.php', { action: 'retry_payos', orderId: 1 })
  assert(retryNoAuth.status === 401, 'retry_payos requires auth', `status ${retryNoAuth.status}`)

  const cancelNoAuth = await apiPut('/orders.php', { action: 'cancel_pending', orderId: 1 })
  assert(cancelNoAuth.status === 401, 'cancel_pending requires auth', `status ${cancelNoAuth.status}`)

  // Admin login
  const admin = await login('admin', '123456')
  assert(!!admin?.token, 'admin login')

  if (admin?.token) {
    const orders = await apiGet('/orders.php', {}, admin.token)
    assert(orders.status === 200 && orders.data.success === true, 'admin GET orders')
  }

  // Customer login (seed user — common dev password)
  let customer = await login('0866830716', '123456')
  if (!customer) customer = await login('0987452316', '123456')

  if (customer?.token) {
    ok(`customer login (user ${customer.user.id})`)
    const pending = await apiGet('/orders.php', { action: 'pending_payos' }, customer.token)
    assert(pending.status === 200 && pending.data.success === true, 'customer pending_payos 200')
    if (pending.data.data === null) {
      ok('pending_payos returns null when no unpaid pending')
    } else {
      ok(`pending_payos found order #${pending.data.data.id}`)
    }

    // Invalid cancel should 404
    const badCancel = await apiPut('/orders.php', { action: 'cancel_pending', orderId: 999999 }, customer.token)
    assert(badCancel.status === 404, 'cancel_pending 404 for missing order', `status ${badCancel.status}`)
  } else {
    fail('customer login', 'could not login seed users with 123456 — skip customer API tests')
  }
}

async function testApiReachable() {
  try {
    const res = await fetch(`${API}/orders.php?action=payment_status&orderId=1`, { signal: AbortSignal.timeout(5000) })
    assert(res.ok || res.status === 404, 'API reachable at ' + API, `status ${res.status}`)
  } catch (e) {
    fail('API reachable', e.message)
  }
}

console.log('=== Phase 2 Smoke Tests ===')
testCartHelpers()
testDisplayStockLogic()
testAddCartLabel()
await testApiReachable()
await testApi()

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===`)
process.exit(failed > 0 ? 1 : 0)
