<template>
  <el-card shadow="never">
    <template #header>
      <div class="card-header">
        <span style="font-size: 16px; font-weight: bold;">Tất cả đơn hàng hệ thống</span>
        <el-button type="success" size="small" @click="exportOrdersToExcel" :icon="Download" :loading="isExportingExcel">Xuất Danh Sách Đơn</el-button>
      </div>
    </template>

    <div class="filter-bar" style="display: flex; gap: 15px; margin-bottom: 20px; align-items: center;">
      <el-input v-model="searchQuery" placeholder="Tìm theo Mã đơn, Tên, SĐT..." style="width: 300px;" clearable :prefix-icon="Search" />
      <el-select v-model="statusFilter" placeholder="Lọc trạng thái" style="width: 180px;" clearable>
        <el-option label="Chờ xác nhận" value="pending" />
        <el-option label="Đã xác nhận" value="approved" />
        <el-option label="Đang giao hàng" value="shipping" />
        <el-option label="Hoàn thành" value="completed" />
        <el-option label="Đã hủy" value="cancelled" />
      </el-select>
      <el-button
        type="primary"
        size="small"
        :disabled="selectedRows.length === 0 || bulkLoading"
        :loading="bulkLoading"
        @click="handleBulkAdvance"
      >
        Cập nhật các đơn đã chọn ({{ selectedRows.length }})
      </el-button>
    </div>

    <div class="orders-table-wrap">
    <el-table
      :data="paginatedOrders"
      stripe
      class="orders-table"
      table-layout="fixed"
      style="width: 100%"
      @selection-change="handleSelectionChange"
    >
      <el-table-column type="selection" width="45" />
      <el-table-column prop="orderId" label="Mã Đơn" width="100" />
      <el-table-column prop="customerName" label="Họ Tên" width="140" show-overflow-tooltip />
      <el-table-column prop="phone" label="Điện thoại" width="110" />
      <el-table-column prop="address" label="Địa chỉ giao hàng" min-width="180" show-overflow-tooltip />
      <el-table-column label="Tổng tiền" width="120">
        <template #default="scope">
          <strong style="color: #d93025">{{ formatPrice(scope.row.total_amount) }}đ</strong>
        </template>
      </el-table-column>
      <el-table-column label="Nhận hàng" width="130" align="center">
        <template #default="scope">
          <el-tag v-if="scope.row.deliveryMethod === 'store'" type="warning" size="small">Tại cửa hàng</el-tag>
          <el-tag v-else size="small">Giao tận nhà</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Thanh toán" width="130" align="center">
        <template #default="scope">
          <el-tag v-if="scope.row.paymentMethod === 'payos'" type="success" size="small" effect="dark">PayOS</el-tag>
          <el-tag v-else-if="scope.row.paymentMethod === 'pay_at_store'" type="warning" size="small">Tại cửa hàng</el-tag>
          <el-tag v-else-if="scope.row.paymentMethod === 'bank_transfer'" type="primary" size="small">Chuyển khoản</el-tag>
          <el-tag v-else size="small">COD</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="date" label="Thời gian" width="150" />
      <el-table-column label="Tình trạng" width="220">
        <template #default="scope">
          <div style="display: flex; flex-direction: column; gap: 6px; align-items: flex-start;">
            <el-tag :type="getStatusTagType(scope.row.raw_status)" size="small" effect="dark">
              {{ getStatusLabel(scope.row.raw_status) }}
            </el-tag>
            <div style="display: flex; gap: 4px; flex-wrap: wrap;">
              <el-button
                v-if="getNextStatus(scope.row.raw_status)"
                size="small"
                type="primary"
                :loading="statusUpdatingId === scope.row.db_id"
                @click="advanceOrderStatus(scope.row)"
              >
                → {{ getNextStatusButtonLabel(scope.row.raw_status) }}
              </el-button>
              <el-button
                v-if="canCancelStatus(scope.row.raw_status)"
                size="small"
                type="danger"
                plain
                @click="cancelOrderStatus(scope.row)"
              >
                Hủy
              </el-button>
            </div>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="Thao tác" width="390" align="left" class-name="order-action-col">
        <template #default="scope">
          <div class="order-actions">
            <el-button size="small" type="primary" :icon="View" title="Xem Chi Tiết" @click="viewOrderDetails(scope.row)">Chi tiết</el-button>
            <el-button
              size="small"
              type="success"
              :icon="Printer"
              :disabled="!canPrintOrderDocuments(scope.row.raw_status)"
              :title="canPrintOrderDocuments(scope.row.raw_status) ? 'In Hóa Đơn' : 'Đơn đã hủy — không in hóa đơn'"
              @click="handlePrintInvoice(scope.row)"
            >Hóa đơn</el-button>
            <el-button
              size="small"
              type="warning"
              :icon="Document"
              :disabled="!canPrintOrderDocuments(scope.row.raw_status)"
              :title="canPrintOrderDocuments(scope.row.raw_status) ? 'In Phiếu Giao' : 'Đơn đã hủy — không in phiếu giao'"
              @click="handlePrintShipping(scope.row)"
            >Phiếu giao</el-button>
            <el-button size="small" type="danger" :icon="Delete" title="Xóa" @click="handleDeleteOrder(scope.row.db_id)">Xóa</el-button>
          </div>
        </template>
      </el-table-column>
    </el-table>
    </div>

    <div style="display: flex; justify-content: flex-end; margin-top: 20px;">
      <el-pagination v-model:current-page="currentPage" v-model:page-size="pageSize" :page-sizes="[10, 20, 50, 100]" :total="filteredOrders.length" layout="total, sizes, prev, pager, next" />
    </div>
  </el-card>

  <!-- MODAL XEM CHI TIẾT ĐƠN HÀNG -->
  <el-dialog v-model="orderDetailsVisible" title="Chi tiết Đơn Hàng" width="600px" top="5vh">
    <div v-if="selectedOrder" class="order-details-modal">
      <el-alert
        v-if="selectedOrder.raw_status === 'cancelled'"
        title="Đơn hàng này đã bị hủy"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 16px;"
      >
        Không giao hàng và không thu tiền. Chỉ xem lại thông tin đơn.
      </el-alert>
      <el-descriptions border :column="1" size="small" style="margin-bottom: 20px">
        <el-descriptions-item label="Mã Đơn Hàng"><strong>{{ selectedOrder.orderId }}</strong></el-descriptions-item>
        <el-descriptions-item label="Khách Hàng">{{ selectedOrder.customerName }} - {{ selectedOrder.phone }}</el-descriptions-item>
        <el-descriptions-item label="Địa chỉ giao">{{ selectedOrder.address }}</el-descriptions-item>
        <el-descriptions-item label="Ghi chú khách hàng"><span style="color:#E6A23C">{{ selectedOrder.note || 'Không có ghi chú' }}</span></el-descriptions-item>
        <el-descriptions-item label="Thanh Toán">
          <el-tag v-if="selectedOrder.paymentMethod === 'payos'" type="success" size="small" effect="dark">Thanh toán trực tuyến (PayOS)</el-tag>
          <el-tag v-else-if="selectedOrder.paymentMethod === 'pay_at_store'" type="warning" size="small">Thanh toán tại cửa hàng</el-tag>
          <el-tag v-else-if="selectedOrder.paymentMethod === 'bank_transfer'" type="primary" size="small">Chuyển khoản ngân hàng</el-tag>
          <el-tag v-else size="small" type="success">Thanh toán COD</el-tag>
        </el-descriptions-item>
      </el-descriptions>
      
      <h4>Các sản phẩm:</h4>
      <el-table :data="selectedOrder.items" style="width: 100%; margin-bottom: 20px" size="small" border>
        <el-table-column label="Hình ảnh" width="80" align="center">
          <template #default="scope">
            <el-image :src="scope.row.image_url" style="width: 40px; height: 40px; border-radius: 4px;" fit="cover" />
          </template>
        </el-table-column>
        <el-table-column prop="product_name" label="Tên SP" min-width="150" />
        <el-table-column label="Biến thể" min-width="140">
          <template #default="scope">
            <span style="color:#666;">{{ getVariantLabel(scope.row) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="quantity" label="SL" width="60" align="center" />
        <el-table-column label="Thành tiền" width="100" align="right">
          <template #default="scope">
            <strong>{{ formatPrice(scope.row.price * scope.row.quantity) }}đ</strong>
          </template>
        </el-table-column>
      </el-table>

      <div style="text-align: right; font-size: 14px; line-height: 1.8;">
        <p v-if="selectedOrder.discount_amount > 0">Tổng tiền hàng: {{ formatPrice(Number(selectedOrder.total_amount) + Number(selectedOrder.discount_amount)) }}đ</p>
        <p v-if="selectedOrder.discount_amount > 0">Giảm giá: <span style="color: green">-{{ formatPrice(selectedOrder.discount_amount) }}đ</span></p>
        <p style="font-size: 18px; font-weight: bold; color: #d93025; border-top: 1px solid #eee; padding-top: 10px; margin-top: 5px;">
          CẦN THU: {{ formatPrice(selectedOrder.total_amount) }}đ
        </p>
      </div>
    </div>
  </el-dialog>

  <!-- MODAL XEM TRƯỚC BẢN IN -->
  <el-dialog v-model="printPreviewVisible" :title="printType === 'invoice' ? 'Xem trước Hóa đơn' : 'Xem trước Phiếu giao hàng'" width="800px" top="5vh">
    <div id="print-area">
      <!-- MẪU HÓA ĐƠN BÁN HÀNG -->
      <div class="invoice-container" v-if="printingOrder && printType === 'invoice'">
        <div class="invoice-header">
          <div class="invoice-company-info">
            <h3>{{ shopInfo.shop_name }}</h3>
            <p><strong>Mã số thuế:</strong> 8361297258</p>
            <p><strong>Địa chỉ:</strong> {{ shopInfo.address }}</p>
            <p><strong>Hotline mua hàng:</strong> {{ shopInfo.hotline }}</p>
          </div>
        </div>
        <hr class="dashed-hr" />
        <div class="invoice-date">Ngày bán: {{ printingOrder.date }}</div>
        
        <div class="invoice-title">
          <h2>HÓA ĐƠN BÁN HÀNG</h2>
          <p>{{ printingOrder.rawOrderId }}</p>
        </div>

        <div class="invoice-customer">
          <p><strong>Khách hàng:</strong> {{ printingOrder.customerName }}</p>
          <p><strong>Địa chỉ:</strong> {{ printingOrder.address }}</p>
          <p><strong>Điện thoại:</strong> {{ printingOrder.phone }}</p>
          <p><strong>Người bán:</strong> Đèn Hoa Mỹ (Bán trực tiếp)</p>
        </div>

        <table class="invoice-table">
          <thead>
            <tr>
              <th width="40">STT</th>
              <th width="60">Hình ảnh</th>
              <th>Tên sản phẩm</th>
              <th width="40">SL</th>
              <th width="90">ĐƠN GIÁ</th>
              <th width="90">CHIẾT KHẤU</th>
              <th width="100">THÀNH TIỀN</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in printingOrder.items" :key="index">
              <td style="text-align: center;">{{ index + 1 }}</td>
              <td style="text-align: center;">
                <img :src="item.image_url" style="width: 40px; height: 40px; object-fit: cover;" />
              </td>
              <td>
                <div>{{ item.ten_san_pham || item.product_name }}</div>
                <div style="font-size: 11px; color: #666;" v-if="getVariantLabel(item) !== 'Mặc định'">
                  {{ getVariantLabel(item) }}
                </div>
              </td>
              <td style="text-align: center;">{{ item.quantity }}</td>
              <td style="text-align: right;">{{ formatPrice(item.price) }}</td>
              <td style="text-align: right;">0</td>
              <td style="text-align: right;">{{ formatPrice(item.price * item.quantity) }}</td>
            </tr>
          </tbody>
        </table>

        <div class="invoice-summary">
          <div v-if="Number(printingOrder.discount_amount) > 0" class="summary-row">
            <span>Tổng tiền hàng:</span>
            <span>{{ formatPrice(Number(printingOrder.total_amount) + Number(printingOrder.discount_amount)) }}</span>
          </div>
          <div v-if="Number(printingOrder.discount_amount) > 0" class="summary-row">
            <span>Chiết khấu Voucher:</span>
            <span>-{{ formatPrice(printingOrder.discount_amount) }}</span>
          </div>
          <div class="summary-row total-row">
            <span>Tổng cộng:</span>
            <span>{{ formatPrice(printingOrder.total_amount) }}</span>
          </div>
          <div class="summary-row">
            <span>Khách đã thanh toán:</span>
            <span>0</span>
          </div>
          <div class="summary-row amount-due">
            <span>Cần thu:</span>
            <span>{{ formatPrice(printingOrder.total_amount) }}</span>
          </div>
        </div>

        <div class="invoice-footer-notes">
          <p><strong>Cần thanh toán bằng chữ:</strong> Xin cảm ơn quý khách</p>
          <p><strong>Ghi chú:</strong> Thanh toán thu hộ</p>
          <p>** Do các yếu tố như thiết bị hình ảnh, công nghệ, ánh sáng nên màu sắc có thể khác biệt một chút.</p>
          <p>*** Sau 7 ngày kể từ ngày mua hàng Quý Khách không phản hồi thì cửa hàng mặc nhiên đồng ý chất lượng.</p>
          <h3 class="fragile-warning">Hàng dễ vỡ xin nhẹ tay - Được mở hàng kiểm tra</h3>
        </div>

        <div class="invoice-signatures">
          <div><strong>Khách hàng</strong></div>
          <div><strong>Người bán hàng</strong></div>
          <div><strong>Quản lý</strong></div>
        </div>
      </div>

      <!-- MẪU PHIẾU GIAO HÀNG -->
      <div class="shipping-container" v-if="printingOrder && printType === 'shipping'">
        <div class="shipping-block">
          <p class="shipping-row"><span class="shipping-label">NGƯỜI GỬI:</span><span class="shipping-value">{{ shopInfo.shop_name }}</span></p>
          <p class="shipping-row"><span class="shipping-label">ĐỊA CHỈ:</span><span class="shipping-value">{{ shopInfo.address }}</span></p>
          <p class="shipping-row"><span class="shipping-label">SĐT:</span><span class="shipping-value">{{ shopInfo.hotline }}</span></p>
        </div>

        <div class="shipping-block">
          <p class="shipping-row"><span class="shipping-label">NGƯỜI NHẬN:</span><span class="shipping-value">{{ printingOrder.customerName }}</span></p>
          <p class="shipping-row"><span class="shipping-label">ĐỊA CHỈ:</span><span class="shipping-value">{{ printingOrder.address }}</span></p>
          <p class="shipping-row"><span class="shipping-label">SĐT:</span><span class="shipping-value">{{ printingOrder.phone }}</span></p>
        </div>

        <p class="shipping-warning">HÀNG THỦY TINH DỄ VỠ<br />XIN VẬN CHUYỂN NHẸ TAY</p>

        <p class="shipping-row shipping-row--center">Tổng : ..........................thùng</p>

        <p class="shipping-row shipping-row--center shipping-emphasis">
          Số tiền thu hộ: {{ formatPrice(printingOrder.total_amount) }}
        </p>

        <p class="shipping-row shipping-row--center">
          <span class="shipping-label">Cước vận chuyển:</span>
          <span class="shipping-highlight">NGƯỜI NHẬN HÀNG THANH TOÁN</span>
        </p>
      </div>
    </div>
    
    <template #footer>
      <el-button @click="printPreviewVisible = false">Đóng</el-button>
      <el-button type="primary" :icon="Printer" @click="executePrint">Tiến hành In</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { Download, Printer, Document, Delete, Search, View } from '@element-plus/icons-vue'
import { ref, computed, nextTick, onMounted } from 'vue'
import { updateOrder, deleteOrder } from '../services/orderService'
import { useAuthStore } from '../stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import { formatPrice } from '../utils/format'
import {
  getStatusLabel,
  getStatusTagType,
  getNextStatus,
  getNextStatusButtonLabel,
  canCancelStatus,
  canPrintOrderDocuments,
} from '../utils/orderStatus'
import { useSettingsStore } from '../stores/settings'

const INVOICE_SHOP_DEFAULTS = {
  shop_name: 'ĐÈN HOA MỸ - THẾ GIỚI ĐÈN NGHỆ THUẬT',
  address: '905 Nguyễn Văn Linh, An Biên, Hải Phòng',
  hotline: '0978897579 - 02256533618',
}

const props = defineProps({
  allOrders: { type: Array, default: () => [] },
  webSettingsForm: { type: Object, default: () => ({}) }
})

const emit = defineEmits(['orders-changed'])
const authStore = useAuthStore()
const settingsStore = useSettingsStore()

const shopInfo = computed(() => {
  const fromAdmin = props.webSettingsForm || {}
  return {
    shop_name:
      fromAdmin.shop_name?.trim() ||
      settingsStore.sys_shop_name ||
      INVOICE_SHOP_DEFAULTS.shop_name,
    address:
      fromAdmin.address?.trim() ||
      settingsStore.sys_address ||
      INVOICE_SHOP_DEFAULTS.address,
    hotline:
      fromAdmin.hotline?.trim() ||
      settingsStore.sys_hotline ||
      INVOICE_SHOP_DEFAULTS.hotline,
  }
})

onMounted(() => {
  if (!props.webSettingsForm?.address?.trim() || !props.webSettingsForm?.hotline?.trim()) {
    settingsStore.fetchSettings()
  }
})

const selectedRows = ref([])
const bulkLoading = ref(false)
const statusUpdatingId = ref(null)

const printingOrder = ref(null)
const printType = ref('invoice')

const searchQuery = ref('')
const statusFilter = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

const filteredOrders = computed(() => {
  return props.allOrders.filter(order => {
    const matchSearch = order.orderId.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                        order.customerName.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                        order.phone.includes(searchQuery.value)
    const matchStatus = statusFilter.value ? order.raw_status === statusFilter.value : true
    return matchSearch && matchStatus
  })
})

const paginatedOrders = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredOrders.value.slice(start, end)
})

const orderDetailsVisible = ref(false)
const selectedOrder = ref(null)

const viewOrderDetails = (order) => {
  if (order.raw_status === 'cancelled') {
    ElMessage.warning('Đơn hàng này đã bị hủy.')
  }
  selectedOrder.value = order
  orderDetailsVisible.value = true
}

const printPreviewVisible = ref(false)
const isExportingExcel = ref(false)
const loadXLSX = async () => import('xlsx')
const scheduleXlsxPrefetch = () => {
  const prefetch = () => { loadXLSX().catch(() => {}) }
  if (typeof window !== 'undefined' && typeof window.requestIdleCallback === 'function') {
    window.requestIdleCallback(prefetch, { timeout: 2000 })
  } else {
    setTimeout(prefetch, 1200)
  }
}

// IN HÓA ĐƠN / PHIẾU GIAO
const handlePrintInvoice = (order) => {
  if (!canPrintOrderDocuments(order.raw_status)) {
    ElMessage.warning('Đơn đã hủy, không thể in hóa đơn.')
    return
  }
  printingOrder.value = order
  printType.value = 'invoice'
  printPreviewVisible.value = true
}

const handlePrintShipping = (order) => {
  if (!canPrintOrderDocuments(order.raw_status)) {
    ElMessage.warning('Đơn đã hủy, không thể in phiếu giao.')
    return
  }
  printingOrder.value = order
  printType.value = 'shipping'
  printPreviewVisible.value = true
}

const executePrint = () => {
  const printArea = document.getElementById('print-area')
  if (!printArea) return

  const iframe = document.createElement('iframe')
  iframe.style.display = 'none'
  document.body.appendChild(iframe)

  const styles = `
    <style>
      body { font-family: 'Times New Roman', serif; color: #000; background: #fff; margin: 0; padding: 0; }
      .invoice-container { width: 210mm; padding: 15mm; margin: 0 auto; box-sizing: border-box; page-break-inside: avoid; break-inside: avoid; }
      .invoice-header { margin-bottom: 20px; }
      .invoice-company-info { text-align: right; font-size: 13px; line-height: 1.5; }
      .invoice-company-info h3 { margin: 0 0 5px 0; font-size: 16px; }
      .invoice-company-info p { margin: 2px 0; }
      .dashed-hr { border: none; border-top: 1px dashed #000; margin: 15px 0; }
      .invoice-date { font-size: 12px; margin-bottom: 20px; text-align: left; }
      .invoice-title { text-align: center; margin-bottom: 30px; }
      .invoice-title h2 { margin: 0 0 5px 0; font-size: 24px; text-transform: uppercase; font-weight: bold; }
      .invoice-title p { margin: 0; font-size: 14px; font-weight: bold; }
      .invoice-customer { font-size: 13px; line-height: 1.6; margin-bottom: 20px; }
      .invoice-customer p { margin: 3px 0; }
      .invoice-customer strong { display: inline-block; width: 100px; }
      .invoice-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 13px; }
      .invoice-table th, .invoice-table td { border: 1px solid #000; padding: 6px; }
      .invoice-table th { font-weight: bold; text-align: center; }
      .invoice-summary { width: 45%; float: right; font-size: 13px; line-height: 1.6; margin-bottom: 20px; clear: none; }
      .summary-row { display: flex; justify-content: space-between; margin-bottom: 3px; }
      .amount-due { font-weight: bold; font-size: 14px; border-top: 1px dashed #000; padding-top: 5px; margin-top: 5px; }
      .invoice-footer-notes { clear: both; font-size: 12px; line-height: 1.5; padding-top: 20px; }
      .invoice-footer-notes p { margin: 3px 0; }
      .fragile-warning { text-align: center; color: #d93025 !important; font-size: 16px; margin-top: 20px; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .invoice-signatures { display: flex; justify-content: space-around; margin-top: 30px; font-size: 13px; text-align: center; page-break-inside: avoid; break-inside: avoid; }

      .shipping-container { width: 210mm; padding: 20mm; margin: 0 auto; box-sizing: border-box; background: #fff; border: 3px solid #000; font-family: Arial, 'Helvetica Neue', sans-serif; font-size: 15px; line-height: 1.65; font-weight: 400; color: #000; }
      .shipping-block { margin-bottom: 22px; }
      .shipping-row { margin: 8px 0; display: flex; align-items: flex-start; gap: 10px; font-size: 15px; line-height: 1.65; font-weight: 400; }
      .shipping-row--center { justify-content: center; text-align: center; flex-wrap: wrap; }
      .shipping-label { font-weight: 700; min-width: 118px; flex-shrink: 0; }
      .shipping-value { font-weight: 400; flex: 1; }
      .shipping-warning { margin: 28px 0; text-align: center; font-size: 17px; font-weight: 700; line-height: 1.5; color: #d93025 !important; text-transform: uppercase; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .shipping-emphasis { font-weight: 700; }
      .shipping-highlight { color: #d93025 !important; font-weight: 700; text-transform: uppercase; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    </style>
  `

  iframe.contentDocument.write(`
    <html>
      <head>
        <title>In Đơn Hàng</title>
        ${styles}
      </head>
      <body>
        ${printArea.innerHTML}
      </body>
    </html>
  `)
  iframe.contentDocument.close()
  
  setTimeout(() => {
    iframe.contentWindow.focus()
    iframe.contentWindow.print()
    setTimeout(() => {
      document.body.removeChild(iframe)
    }, 1000)
  }, 500)
}

const getVariantLabel = (item) => {
  const size = (item?.variant_kich_thuoc || '').trim()
  const light = (item?.variant_anh_sang || '').trim()
  const parts = []
  if (size) parts.push(size)
  if (light) parts.push(light)
  return parts.length ? parts.join(' - ') : 'Mặc định'
}

const handleSelectionChange = (rows) => {
  selectedRows.value = rows
}

const applyStatusChange = async (orderId, newStatus) => {
  statusUpdatingId.value = orderId
  const result = await updateOrder(orderId, newStatus, authStore.user?.id)
  statusUpdatingId.value = null
  if (result && result.success) {
    ElMessage.success(result.message || 'Cập nhật trạng thái thành công!')
    emit('orders-changed')
    return true
  }
  ElMessage.error(result?.message || 'Lỗi khi cập nhật trạng thái đơn hàng')
  emit('orders-changed')
  return false
}

const advanceOrderStatus = async (order) => {
  const next = getNextStatus(order.raw_status)
  if (!next) return
  await applyStatusChange(order.db_id, next)
}

const cancelOrderStatus = (order) => {
  ElMessageBox.confirm(
    `Hủy đơn ${order.orderId}? Tồn kho và mã giảm giá (nếu có) sẽ được hoàn trả.`,
    'Xác nhận hủy',
    { confirmButtonText: 'Hủy đơn', cancelButtonText: 'Không', type: 'warning' }
  ).then(async () => {
    await applyStatusChange(order.db_id, 'cancelled')
  }).catch(() => {})
}

const handleBulkAdvance = async () => {
  const eligible = selectedRows.value.filter((row) => getNextStatus(row.raw_status))
  if (eligible.length === 0) {
    ElMessage.warning('Không có đơn nào có thể tiến bước')
    return
  }
  bulkLoading.value = true
  let ok = 0
  let fail = 0
  for (const row of eligible) {
    const next = getNextStatus(row.raw_status)
    const result = await updateOrder(row.db_id, next, authStore.user?.id)
    if (result && result.success) ok++
    else fail++
  }
  bulkLoading.value = false
  selectedRows.value = []
  emit('orders-changed')
  if (fail === 0) {
    ElMessage.success(`Đã cập nhật ${ok} đơn hàng`)
  } else {
    ElMessage.warning(`Thành công ${ok}, thất bại ${fail}`)
  }
}

// XÓA ĐƠN HÀNG
const handleDeleteOrder = async (orderId) => {
  ElMessageBox.confirm('Bạn muốn xóa vĩnh viễn đơn hàng này chứ? Hồ sơ khách hàng và dữ liệu doanh thu có thể bị ảnh hưởng.', 'Cảnh báo xóa', {
    confirmButtonText: 'Đồng ý Xóa', cancelButtonText: 'Hủy bỏ', type: 'danger'
  }).then(async () => {
    const loading = ElMessage({ message: 'Đang xóa đơn hàng...', type: 'info', duration: 0 })
    const result = await deleteOrder(orderId)
    loading.close()
    if (result && result.success) {
      ElMessage.success('Xóa đơn hàng thành công!')
      emit('orders-changed')
    } else {
      ElMessage.error(result?.message || 'Có lỗi khi xóa đơn hàng')
    }
  }).catch(() => {})
}

// XUẤT EXCEL
const exportOrdersToExcel = async () => {
  if (props.allOrders.length === 0) return ElMessage.warning('Không có dữ liệu đơn hàng để xuất')
  if (isExportingExcel.value) return
  isExportingExcel.value = true
  try {
    const XLSX = await loadXLSX()
    const paymentLabels = { cod: 'COD', pay_at_store: 'Tại cửa hàng', bank_transfer: 'Chuyển khoản', payos: 'PayOS' }
    const deliveryLabels = { home: 'Giao tận nhà', store: 'Nhận tại cửa hàng' }
    const dataToExport = props.allOrders.map(o => ({
      'Mã đơn': o.orderId,
      'Khách hàng': o.customerName,
      'SĐT': o.phone,
      'Nhận hàng': deliveryLabels[o.deliveryMethod] || o.deliveryMethod,
      'Địa chỉ': o.address,
      'Thanh toán': paymentLabels[o.paymentMethod] || o.paymentMethod,
      'Tổng tiền': o.total_amount,
      'Ngày đặt': o.date,
      'Trạng thái': o.status
    }))
    const ws = XLSX.utils.json_to_sheet(dataToExport)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'DanhSachDonHang')
    XLSX.writeFile(wb, 'BaoCao_DonHang.xlsx')
  } catch (error) {
    console.error('Lỗi xuất Excel đơn hàng:', error)
    ElMessage.error('Không thể tải module Excel. Vui lòng thử lại.')
  } finally {
    isExportingExcel.value = false
  }
}

onMounted(() => {
  scheduleXlsxPrefetch()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }

.orders-table-wrap {
  width: 100%;
  overflow-x: auto;
}

.orders-table-wrap :deep(.orders-table) {
  min-width: 1330px;
}

.orders-table-wrap :deep(.order-action-col .cell) {
  overflow: visible;
}

.order-actions {
  display: flex;
  gap: 4px;
  justify-content: flex-start;
  flex-wrap: nowrap;
  white-space: nowrap;
  padding-right: 4px;
}

.order-actions :deep(.el-button) {
  padding: 8px 8px !important;
}

.orders-table-wrap :deep(.el-button) {
  min-width: unset !important;
  height: 32px;
  flex-shrink: 0;
}

.invoice-container, .shipping-container {
  padding: 10px;
  font-family: 'Times New Roman', serif;
  color: #000;
  background: #fff;
  page-break-inside: avoid;
  break-inside: avoid;
}

.invoice-header { margin-bottom: 20px; }
.invoice-company-info { text-align: right; font-size: 13px; line-height: 1.5; }
.invoice-company-info h3 { margin: 0 0 5px 0; font-size: 16px; }
.invoice-company-info p { margin: 2px 0; }
.dashed-hr { border: none; border-top: 1px dashed #000; margin: 15px 0; }
.invoice-date { font-size: 12px; margin-bottom: 20px; text-align: left; }
.invoice-title { text-align: center; margin-bottom: 30px; }
.invoice-title h2 { margin: 0 0 5px 0; font-size: 24px; text-transform: uppercase; font-weight: bold; }
.invoice-title p { margin: 0; font-size: 14px; font-weight: bold; }
.invoice-customer { font-size: 13px; line-height: 1.6; margin-bottom: 20px; }
.invoice-customer p { margin: 3px 0; }
.invoice-customer strong { display: inline-block; width: 100px; }
.invoice-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 13px; }
.invoice-table th, .invoice-table td { border: 1px solid #000; padding: 6px; }
.invoice-table th { font-weight: bold; text-align: center; }
.invoice-summary { width: 45%; float: right; font-size: 13px; line-height: 1.6; margin-bottom: 20px; clear: none; }
.summary-row { display: flex; justify-content: space-between; margin-bottom: 3px; }
.amount-due { font-weight: bold; font-size: 14px; border-top: 1px dashed #000; padding-top: 5px; margin-top: 5px; }
.invoice-footer-notes { clear: both; font-size: 12px; line-height: 1.5; padding-top: 20px; }
.invoice-footer-notes p { margin: 3px 0; }
.fragile-warning { text-align: center; color: #d93025 !important; font-size: 16px; margin-top: 20px; }
.invoice-signatures { display: flex; justify-content: space-around; margin-top: 30px; font-size: 13px; text-align: center; page-break-inside: avoid; break-inside: avoid; }

/* Phiếu giao hàng — font thống nhất */
.shipping-container {
  padding: 20px;
  border: 3px solid #000;
  font-family: Arial, 'Helvetica Neue', sans-serif;
  font-size: 15px;
  line-height: 1.65;
  font-weight: 400;
  color: #000;
}
.shipping-block { margin-bottom: 22px; }
.shipping-row {
  margin: 8px 0;
  display: flex;
  align-items: flex-start;
  gap: 10px;
  font-size: 15px;
  line-height: 1.65;
  font-weight: 400;
}
.shipping-row--center { justify-content: center; text-align: center; flex-wrap: wrap; }
.shipping-label { font-weight: 700; min-width: 118px; flex-shrink: 0; }
.shipping-value { font-weight: 400; flex: 1; }
.shipping-warning {
  margin: 28px 0;
  text-align: center;
  font-size: 17px;
  font-weight: 700;
  line-height: 1.5;
  color: #d93025;
  text-transform: uppercase;
}
.shipping-emphasis { font-weight: 700; }
.shipping-highlight { color: #d93025; font-weight: 700; text-transform: uppercase; }

@media print {
  body * { visibility: hidden; }
  #print-area, #print-area * { visibility: visible; }
  #print-area { position: absolute; left: 0; top: 0; width: 100%; }
}
</style>
