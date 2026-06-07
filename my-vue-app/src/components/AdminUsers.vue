<template>
  <el-card shadow="never">
    <template #header><div class="card-header"><span>Danh sách người dùng</span></div></template>
    <el-tabs v-model="userActiveTab" class="custom-tabs">

      <!-- ==================== TAB KHÁCH HÀNG ==================== -->
      <el-tab-pane v-if="canManageCustomers" label="Khách hàng" name="customers">
        <el-table :data="customersData" stripe style="width: 100%" v-loading="loadingUsers">
          <el-table-column prop="id" label="ID" width="70" />
          <el-table-column label="Họ Tên">
            <template #default="scope">
              <div style="display: flex; align-items: center; gap: 10px">
                <el-avatar :size="30" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" />
                <span>{{ scope.row.name }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="phone" label="Số điện thoại" width="150" />
          <el-table-column prop="email" label="Email" />
          <el-table-column label="Tình trạng" width="150">
            <template #default="scope">
              <el-tag :type="scope.row.role === 'locked' ? 'info' : 'success'">
                {{ scope.row.role === 'locked' ? 'Bị khóa' : 'Hoạt động' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="Thao tác" width="120">
            <template #default="scope">
              <el-button v-if="scope.row.role === 'customer'" size="small" type="danger" plain @click="handleLockUser(scope.row)">Khóa</el-button>
              <el-button v-if="scope.row.role === 'locked'" size="small" type="success" plain @click="handleUnlockUser(scope.row)">Mở Khóa</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- ==================== TAB QUẢN TRỊ VIÊN & NHÂN VIÊN ==================== -->
      <el-tab-pane v-if="canManageAccounts" label="Quản trị viên & Nhân viên" name="admins">
        <div v-if="canManageAccounts" style="display: flex; justify-content: flex-end; margin-bottom: 15px;">
          <el-button type="primary" :icon="Plus" @click="openAddAdminDialog">Thêm Tài Khoản Mới</el-button>
        </div>
        <el-table :data="adminsData" stripe style="width: 100%" v-loading="loadingAdmins">
          <el-table-column prop="id" label="ID" width="70" />
          <el-table-column label="Họ Tên">
            <template #default="scope">
              <div style="display: flex; align-items: center; gap: 10px">
                <el-avatar :size="30" src="https://cube.elemecdn.com/3/7c/3ea6beec64369c2642b92c6726f1epng.png" />
                <span>{{ scope.row.name }}</span>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="username" label="Tên đăng nhập" width="150" />
          <el-table-column label="Vai trò" width="130">
            <template #default="scope">
              <el-tag :type="scope.row.role === 'admin' ? 'warning' : 'success'" effect="dark" round>
                {{ scope.row.role === 'admin' ? 'Admin' : 'Nhân viên' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="phone" label="Số điện thoại" width="140" />
          <el-table-column prop="email" label="Email" />
          <el-table-column label="Trạng thái" width="110">
            <template #default="scope">
              <el-tag :type="Number(scope.row.is_active) === 0 ? 'info' : 'success'" size="small">
                {{ Number(scope.row.is_active) === 0 ? 'Vô hiệu' : 'Hoạt động' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="Thao tác" width="160" align="center">
            <template #default="scope">
              <div style="display: flex; gap: 5px; justify-content: center;">
                <template v-if="scope.row.id !== 1">
                  <el-button v-if="Number(scope.row.is_active) !== 0" size="small" type="success" plain @click="handleToggleAdmin(scope.row, 0)">Vô hiệu</el-button>
                  <el-button v-else size="small" type="primary" plain @click="handleToggleAdmin(scope.row, 1)">Kích hoạt</el-button>
                </template>
                <el-button v-if="isSuperAdmin && scope.row.id !== 1" size="small" type="danger" plain @click="handleDeleteAdmin(scope.row)">Xoá</el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

    </el-tabs>
  </el-card>

  <!-- ==================== DIALOG THÊM TÀI KHOẢN ==================== -->
  <el-dialog v-model="addAdminDialogVisible" title="Thêm Tài Khoản Quản Trị / Nhân Viên" width="550px" top="5vh">
    <div style="margin-bottom: 20px;">
      <label style="display: block; margin-bottom: 8px; font-weight: 500;">Vai trò *</label>
      <div style="display: flex; gap: 10px;">
        <el-button
          v-if="isSuperAdmin"
          :type="newAdminForm.role === 'admin' ? 'primary' : 'default'"
          @click="newAdminForm.role = 'admin'"
          :icon="StarFilled"
        >Admin (Toàn quyền)</el-button>
        <el-button
          :type="newAdminForm.role === 'staff' ? 'success' : 'default'"
          @click="newAdminForm.role = 'staff'"
          :icon="User"
        >Nhân viên (Giới hạn)</el-button>
      </div>
    </div>

    <el-form :model="newAdminForm" label-position="top">
      <el-form-item label="Tên đăng nhập (username) *">
        <el-input v-model="newAdminForm.username" placeholder="VD: nhanvien01" />
      </el-form-item>
      <el-form-item label="Mật khẩu *">
        <el-input v-model="newAdminForm.password" type="password" show-password placeholder="Tối thiểu 6 ký tự" />
      </el-form-item>
      <el-form-item label="Họ và tên *">
        <el-input v-model="newAdminForm.name" placeholder="VD: Nguyễn Văn A" />
      </el-form-item>
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="Số điện thoại">
            <el-input v-model="newAdminForm.phone" placeholder="VD: 0912345678" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="Email">
            <el-input v-model="newAdminForm.email" placeholder="VD: nv@denhoamy.vn" />
          </el-form-item>
        </el-col>
      </el-row>

      <div v-if="newAdminForm.role === 'staff'" style="margin-top: 10px; padding: 15px; border: 1px dashed #E6A23C; border-radius: 8px; background: #fdf6ec;">
        <h4 style="margin: 0 0 12px 0; color: #E6A23C; font-size: 14px;">Phân quyền cho Nhân viên</h4>
        <el-row :gutter="10">
          <el-col :span="8" v-for="perm in permissionsList" :key="perm.key">
            <el-checkbox v-model="newAdminForm.permissions[perm.key]" :label="perm.label" style="margin-bottom: 8px;" />
          </el-col>
        </el-row>
      </div>
    </el-form>

    <template #footer>
      <el-button @click="addAdminDialogVisible = false">Hủy</el-button>
      <el-button :type="newAdminForm.role === 'admin' ? 'primary' : 'success'" @click="handleCreateAdmin">
        {{ newAdminForm.role === 'admin' ? 'Tạo Admin' : 'Tạo Nhân viên' }}
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Plus, User, StarFilled } from '@element-plus/icons-vue'
import { getUsers, updateUser, getAdmins, addAdmin, updateAdmin, deleteAdmin } from '../services/userService'
import { useAuthStore } from '../stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'

const authStore = useAuthStore()

const canManageCustomers = computed(() => authStore.hasPermission('customers'))
const canManageAccounts = computed(() => authStore.hasPermission('accounts'))
const isSuperAdmin = computed(() => authStore.isAdmin)

const userActiveTab = ref('customers')

// ==================== KHÁCH HÀNG ====================
const userData = ref([])
const loadingUsers = ref(false)

const fetchUsersData = async () => {
  if (!canManageCustomers.value) return
  loadingUsers.value = true
  const res = await getUsers()
  if (res && res.success) {
    userData.value = res.data
  } else if (res?.message) {
    ElMessage.error(res.message)
  }
  loadingUsers.value = false
}

const customersData = computed(() => userData.value.filter(u => u.role === 'customer' || u.role === 'locked'))

const handleLockUser = async (user) => {
  ElMessageBox.confirm(`Khóa tài khoản ${user.name}? Họ sẽ không thể đăng nhập.`, 'Cảnh báo', { type: 'warning' }).then(async () => {
    const res = await updateUser(user.id, 'locked')
    if (res && res.success) {
      ElMessage.success(`Đã khóa tài khoản ${user.name}`)
      fetchUsersData()
    } else {
      ElMessage.error(res?.message || 'Không thể khóa tài khoản')
    }
  }).catch(() => {})
}

const handleUnlockUser = async (user) => {
  const res = await updateUser(user.id, 'customer')
  if (res && res.success) {
    ElMessage.success(`Đã mở khóa tài khoản ${user.name}`)
    fetchUsersData()
  } else {
    ElMessage.error(res?.message || 'Không thể mở khóa tài khoản')
  }
}

// ==================== QUẢN TRỊ VIÊN & NHÂN VIÊN ====================
const adminsData = ref([])
const loadingAdmins = ref(false)

const fetchAdminsData = async () => {
  if (!canManageAccounts.value) return
  loadingAdmins.value = true
  const res = await getAdmins()
  if (res && res.success) {
    adminsData.value = res.data
  } else if (res?.message) {
    ElMessage.error(res.message)
  }
  loadingAdmins.value = false
}

const handleToggleAdmin = async (row, newStatus) => {
  const action = newStatus === 0 ? 'vô hiệu hóa' : 'kích hoạt'
  const loading = ElMessage({ message: `Đang ${action}...`, type: 'info', duration: 0 })
  const res = await updateAdmin({ id: row.id, is_active: newStatus })
  loading.close()
  if (res && res.success) {
    ElMessage.success(`Đã ${action} tài khoản ${row.name}!`)
    fetchAdminsData()
  } else {
    ElMessage.error(res?.message || `Lỗi khi ${action}`)
  }
}

const handleDeleteAdmin = (row) => {
  ElMessageBox.confirm(`Xoá vĩnh viễn tài khoản "${row.name}" (${row.username})? Hành động này không thể hoàn tác.`, 'Cảnh báo xoá', {
    confirmButtonText: 'Đồng ý Xoá',
    cancelButtonText: 'Hủy bỏ',
    type: 'error'
  }).then(async () => {
    const loading = ElMessage({ message: 'Đang xoá...', type: 'info', duration: 0 })
    const res = await deleteAdmin(row.id)
    loading.close()
    if (res && res.success) {
      ElMessage.success('Đã xoá tài khoản!')
      fetchAdminsData()
    } else {
      ElMessage.error(res?.message || 'Lỗi khi xoá tài khoản')
    }
  }).catch(() => {})
}

// ==================== DIALOG THÊM TÀI KHOẢN ====================
const addAdminDialogVisible = ref(false)

const permissionsList = [
  { key: 'dashboard', label: 'Thống kê' },
  { key: 'categories', label: 'Danh mục' },
  { key: 'products', label: 'Sản phẩm' },
  { key: 'orders', label: 'Đơn hàng' },
  { key: 'reviews', label: 'Đánh giá' },
  { key: 'customers', label: 'Khách hàng' },
  { key: 'coupons', label: 'Khuyến mãi' },
  { key: 'news', label: 'Tin tức' },
  { key: 'policy', label: 'Chính sách' },
  { key: 'accounts', label: 'Quản lý tài khoản' },
  { key: 'settings', label: 'Cài đặt HT' },
]

const getDefaultForm = () => ({
  role: isSuperAdmin.value ? 'admin' : 'staff',
  username: '',
  password: '',
  name: '',
  phone: '',
  email: '',
  permissions: {
    dashboard: true,
    categories: true,
    products: true,
    orders: true,
    reviews: true,
    customers: false,
    coupons: true,
    news: true,
    policy: true,
    accounts: false,
    settings: false,
  }
})

const newAdminForm = ref(getDefaultForm())

const openAddAdminDialog = () => {
  newAdminForm.value = getDefaultForm()
  if (!isSuperAdmin.value) {
    newAdminForm.value.role = 'staff'
  }
  addAdminDialogVisible.value = true
}

const handleCreateAdmin = async () => {
  const form = newAdminForm.value
  if (!form.username.trim()) return ElMessage.warning('Vui lòng nhập tên đăng nhập')
  if (!form.password || form.password.length < 6) return ElMessage.warning('Mật khẩu phải có ít nhất 6 ký tự')
  if (!form.name.trim()) return ElMessage.warning('Vui lòng nhập họ và tên')
  if (!isSuperAdmin.value && form.role === 'admin') {
    return ElMessage.warning('Bạn không có quyền tạo tài khoản Admin')
  }

  const loading = ElMessage({ message: 'Đang tạo tài khoản...', type: 'info', duration: 0 })
  const payload = {
    username: form.username.trim(),
    password: form.password,
    name: form.name.trim(),
    phone: form.phone || '',
    email: form.email || '',
    role: form.role,
    permissions: form.role === 'staff' ? { ...form.permissions } : null
  }

  const res = await addAdmin(payload)
  loading.close()

  if (res && res.success) {
    ElMessage.success(`Tạo tài khoản ${form.role === 'admin' ? 'Admin' : 'Nhân viên'} thành công!`)
    addAdminDialogVisible.value = false
    fetchAdminsData()
  } else {
    ElMessage.error(res?.message || 'Lỗi khi tạo tài khoản')
  }
}

const initActiveTab = () => {
  if (canManageCustomers.value) {
    userActiveTab.value = 'customers'
  } else if (canManageAccounts.value) {
    userActiveTab.value = 'admins'
  }
}

onMounted(() => {
  initActiveTab()
  fetchUsersData()
  fetchAdminsData()
})
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
