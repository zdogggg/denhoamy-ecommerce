import api from './httpClient'
import { failFalse } from './serviceErrors'

const normalizeNumber = (value) => {
  const num = Number(value)
  return Number.isFinite(num) ? num : 0
}

const normalizeDashboardPayload = (payload = {}) => {
  const revenue = Array.isArray(payload.revenue) ? payload.revenue : []
  const monthlyFinance = Array.isArray(payload.monthly_finance) ? payload.monthly_finance : []
  const categories = Array.isArray(payload.categories) ? payload.categories : []
  const categoriesShare = Array.isArray(payload.categories_share) ? payload.categories_share : []
  const orderStatus = payload.order_status || {}
  const topProducts = Array.isArray(payload.topProducts) ? payload.topProducts : []
  const lowStock = Array.isArray(payload.lowStock) ? payload.lowStock : []
  const summary = payload.summary || {}
  const topSales = payload.top_sales || {}
  const financials = payload.financials || {}
  const financeCompare = payload.finance_compare || {}

  return {
    revenue: revenue.map((row) => ({
      month: row?.month || '',
      amount: normalizeNumber(row?.amount)
    })),
    monthly_finance: monthlyFinance.map((row) => ({
      month: row?.month || '',
      revenue: normalizeNumber(row?.revenue),
      profit: normalizeNumber(row?.profit)
    })),
    categories: categories.map((row) => ({
      category: row?.category || 'Khác',
      sold_count: normalizeNumber(row?.sold_count)
    })),
    categories_share: categoriesShare.map((row) => ({
      category: row?.category || 'Khác',
      sold_count: normalizeNumber(row?.sold_count),
      sold_pct: normalizeNumber(row?.sold_pct),
      revenue: normalizeNumber(row?.revenue),
      revenue_pct: normalizeNumber(row?.revenue_pct)
    })),
    order_status: {
      pending: normalizeNumber(orderStatus.pending),
      approved: normalizeNumber(orderStatus.approved),
      shipping: normalizeNumber(orderStatus.shipping),
      completed: normalizeNumber(orderStatus.completed),
      cancelled: normalizeNumber(orderStatus.cancelled)
    },
    top_sales: {
      min_sold: normalizeNumber(topSales.min_sold) || 2,
      limit: normalizeNumber(topSales.limit) || 5
    },
    topProducts: topProducts.map((row) => ({
      ...row,
      sold_count: normalizeNumber(row?.sold_count),
      revenue: normalizeNumber(row?.revenue),
      price: normalizeNumber(row?.price)
    })),
    lowStock: lowStock.map((row) => ({
      ...row,
      real_stock: normalizeNumber(row?.real_stock),
      severity: row?.severity || 'warning'
    })),
    summary: {
      total_orders: normalizeNumber(summary.total_orders),
      approved_orders: normalizeNumber(summary.approved_orders),
      cancelled_orders: normalizeNumber(summary.cancelled_orders),
      cancel_rate: normalizeNumber(summary.cancel_rate),
      pending_orders: normalizeNumber(summary.pending_orders),
      today_orders: normalizeNumber(summary.today_orders),
      orders_today: normalizeNumber(summary.orders_today || summary.today_orders),
      today_revenue: normalizeNumber(summary.today_revenue),
      avg_order_value: normalizeNumber(summary.avg_order_value),
      period: {
        mode: summary.period?.mode || 'custom_year',
        year: normalizeNumber(summary.period?.year),
        from: summary.period?.from || null,
        to: summary.period?.to || null
      }
    },
    financials: {
      total_revenue: normalizeNumber(financials.total_revenue),
      total_profit: normalizeNumber(financials.total_profit)
    },
    finance_compare: {
      revenue_current: normalizeNumber(financeCompare.revenue_current),
      revenue_previous: normalizeNumber(financeCompare.revenue_previous),
      revenue_change_pct: normalizeNumber(financeCompare.revenue_change_pct),
      profit_current: normalizeNumber(financeCompare.profit_current),
      profit_previous: normalizeNumber(financeCompare.profit_previous),
      profit_change_pct: normalizeNumber(financeCompare.profit_change_pct),
      aov_current: normalizeNumber(financeCompare.aov_current),
      aov_previous: normalizeNumber(financeCompare.aov_previous),
      aov_change_pct: normalizeNumber(financeCompare.aov_change_pct)
    }
  }
}

const buildDashboardParams = (options = {}) => {
  const params = {}
  if (options.year) params.year = options.year
  if (options.topLimit) params.top_limit = options.topLimit
  if (options.lowStockThreshold) params.low_stock_threshold = options.lowStockThreshold
  if (options.minTopSold != null) params.min_top_sold = options.minTopSold
  if (options.from) params.from = options.from
  if (options.to) params.to = options.to
  if (options.preset) params.preset = options.preset
  return params
}

const emptyData = () =>
  normalizeDashboardPayload({
    revenue: [],
    monthly_finance: [],
    categories: [],
    categories_share: [],
    order_status: {},
    topProducts: [],
    lowStock: [],
    summary: {},
    financials: {},
    finance_compare: {}
  })

export const getDashboardStats = async (options = {}) => {
  try {
    const response = await api.get('/statistics.php', { params: buildDashboardParams(options) })
    return {
      ...response.data,
      data: normalizeDashboardPayload(response.data?.data)
    }
  } catch (error) {
    console.error('Lỗi lấy thống kê', error)
    return { ...failFalse(), data: emptyData() }
  }
}
