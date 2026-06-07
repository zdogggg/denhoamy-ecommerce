<?php
// ====================================
// API THỐNG KÊ - statistics.php
// ====================================
require_once 'db.php';
require_once __DIR__ . '/lib/auth_middleware.php';
require_once __DIR__ . '/lib/admin_route_guard.php';

$method = $_SERVER['REQUEST_METHOD'];

function isValidDateValue($value)
{
    if (!is_string($value) || $value === '') {
        return false;
    }
    $date = DateTime::createFromFormat('Y-m-d', $value);
    return $date && $date->format('Y-m-d') === $value;
}

function resolvePreviousPeriod($mode, $fromDate, $toDate, $year)
{
    $fromTs = strtotime($fromDate);
    $toTs = strtotime($toDate);
    switch ($mode) {
        case '7d':
            return [
                'from' => date('Y-m-d', strtotime('-7 days', $fromTs)),
                'to' => date('Y-m-d', strtotime('-7 days', $toTs))
            ];
        case '30d':
            return [
                'from' => date('Y-m-d', strtotime('-30 days', $fromTs)),
                'to' => date('Y-m-d', strtotime('-30 days', $toTs))
            ];
        case 'current_year':
        case 'custom_year':
            $prevYear = ((int) $year) - 1;
            return [
                'from' => $prevYear . '-01-01',
                'to' => $prevYear . '-12-31'
            ];
        case 'custom_range':
        default:
            $days = (int) floor(($toTs - $fromTs) / 86400);
            $days = max($days, 0);
            $prevTo = strtotime('-1 day', $fromTs);
            $prevFrom = strtotime("-{$days} days", $prevTo);
            return [
                'from' => date('Y-m-d', $prevFrom),
                'to' => date('Y-m-d', $prevTo)
            ];
    }
}

if ($method === 'GET') {
    adminGuardRequire('dashboard');
    $currentYear = (int) date('Y');
    $year = isset($_GET['year']) ? (int) $_GET['year'] : $currentYear;
    if ($year < 2000 || $year > 2100) {
        $year = $currentYear;
    }

    $topLimit = isset($_GET['top_limit']) ? (int) $_GET['top_limit'] : 5;
    if ($topLimit < 1 || $topLimit > 20) {
        $topLimit = 5;
    }

    $lowStockThreshold = isset($_GET['low_stock_threshold']) ? (int) $_GET['low_stock_threshold'] : 5;
    if ($lowStockThreshold < 1 || $lowStockThreshold > 1000) {
        $lowStockThreshold = 5;
    }

    // Số lượng bán tối thiểu để được coi là "bán chạy" và lên bảng xếp hạng
    $minTopSold = isset($_GET['min_top_sold']) ? (int) $_GET['min_top_sold'] : 2;
    if ($minTopSold < 1 || $minTopSold > 10000) {
        $minTopSold = 2;
    }

    $fromDate = $_GET['from'] ?? null;
    $toDate = $_GET['to'] ?? null;
    $preset = $_GET['preset'] ?? null;
    $hasDateRange = isValidDateValue($fromDate) && isValidDateValue($toDate);

    $periodMode = 'custom_year';
    $periodStartDate = null;
    $periodEndDate = null;
    $effectiveYear = $year;

    if ($hasDateRange) {
        $periodMode = 'custom_range';
        $periodStartDate = $fromDate;
        $periodEndDate = $toDate;
    } else {
        switch ($preset) {
            case '7d':
                $periodMode = '7d';
                $periodStartDate = date('Y-m-d', strtotime('-6 days'));
                $periodEndDate = date('Y-m-d');
                break;
            case '30d':
                $periodMode = '30d';
                $periodStartDate = date('Y-m-d', strtotime('-29 days'));
                $periodEndDate = date('Y-m-d');
                break;
            case 'current_year':
                $periodMode = 'current_year';
                $effectiveYear = $currentYear;
                $periodStartDate = $currentYear . '-01-01';
                $periodEndDate = $currentYear . '-12-31';
                break;
            case 'custom_year':
            default:
                $periodMode = 'custom_year';
                $effectiveYear = $year;
                $periodStartDate = $effectiveYear . '-01-01';
                $periodEndDate = $effectiveYear . '-12-31';
                break;
        }
    }

    // Base filter cho các thống kê phụ thuộc thời gian
    $periodWhereSql = " AND DATE(o.created_at) BETWEEN ? AND ?";
    $periodParams = [$periodStartDate, $periodEndDate];

    // Đơn đã chốt bán: xác nhận + đang giao + hoàn thành (không tính pending/cancelled)
    $soldStatusSql = "('approved', 'shipping', 'completed')";

    // 1. Doanh thu theo tháng

    // Khởi tạo mảng 12 tháng với doanh thu = 0
    $monthlyRevenue = [];
    for ($i = 1; $i <= 12; $i++) {
        $monthlyRevenue[$i] = ['month' => "Tháng $i", 'amount' => 0];
    }

    $revenueWhereSql = "status IN $soldStatusSql AND DATE(created_at) BETWEEN ? AND ?";
    $revenueParams = [$periodStartDate, $periodEndDate];
    $stmt = $pdo->prepare("
        SELECT MONTH(created_at) as month, SUM(total) as revenue
        FROM orders
        WHERE $revenueWhereSql
        GROUP BY MONTH(created_at)
    ");
    $stmt->execute($revenueParams);
    $revenueData = $stmt->fetchAll();

    foreach ($revenueData as $row) {
        $m = (int) $row['month'];
        $monthlyRevenue[$m]['amount'] = (float) $row['revenue'];
    }

    // 1a. Phân bố trạng thái đơn hàng cho tab tổng quan
    $orderStatus = [
        'pending' => 0,
        'approved' => 0,
        'shipping' => 0,
        'completed' => 0,
        'cancelled' => 0
    ];
    $stmtOrderStatus = $pdo->prepare("
        SELECT status, COUNT(*) as total
        FROM orders
        WHERE DATE(created_at) BETWEEN ? AND ?
        GROUP BY status
    ");
    $stmtOrderStatus->execute([$periodStartDate, $periodEndDate]);
    $orderStatusData = $stmtOrderStatus->fetchAll();
    foreach ($orderStatusData as $row) {
        $status = $row['status'] ?? '';
        if (array_key_exists($status, $orderStatus)) {
            $orderStatus[$status] = (int) ($row['total'] ?? 0);
        }
    }

    // 1b. Doanh thu và lợi nhuận theo tháng cho tab tài chính
    $monthlyFinance = [];
    for ($i = 1; $i <= 12; $i++) {
        $monthlyFinance[$i] = ['month' => "Tháng $i", 'revenue' => 0, 'profit' => 0];
    }
    // Doanh thu tháng phải đồng nhất với KPI doanh thu (orders.total) để tránh lệch số
    foreach ($monthlyRevenue as $month => $item) {
        $monthlyFinance[$month]['revenue'] = (float) ($item['amount'] ?? 0);
    }

    $stmtMonthlyCost = $pdo->prepare("
        SELECT
            MONTH(o.created_at) as month,
            SUM(oi.quantity * COALESCE(oi.cost_price, 0)) as total_cost
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        WHERE o.status IN $soldStatusSql
          AND DATE(o.created_at) BETWEEN ? AND ?
        GROUP BY MONTH(o.created_at)
    ");
    $stmtMonthlyCost->execute([$periodStartDate, $periodEndDate]);
    $monthlyCostData = $stmtMonthlyCost->fetchAll();
    foreach ($monthlyCostData as $row) {
        $m = (int) $row['month'];
        $cost = (float) ($row['total_cost'] ?? 0);
        $monthlyFinance[$m]['profit'] = $monthlyFinance[$m]['revenue'] - $cost;
    }

    // 2. Tỉ lệ danh mục bán chạy 
    $stmtCategory = $pdo->prepare("
        SELECT 
            p.loai_den as category,
            SUM(oi.quantity) as sold_count,
            SUM(oi.quantity * COALESCE(oi.price, p.price, 0)) as revenue
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        JOIN orders o ON oi.order_id = o.id
        WHERE o.status IN $soldStatusSql
          AND p.deleted_at IS NULL
          $periodWhereSql
        GROUP BY p.loai_den
        ORDER BY sold_count DESC
    ");
    $stmtCategory->execute($periodParams);
    $categoryData = $stmtCategory->fetchAll();

    $totalSoldCount = 0.0;
    $totalCategoryRevenue = 0.0;
    foreach ($categoryData as $row) {
        $totalSoldCount += (float) ($row['sold_count'] ?? 0);
        $totalCategoryRevenue += (float) ($row['revenue'] ?? 0);
    }

    $categoriesShare = [];
    foreach ($categoryData as $row) {
        $soldCount = (float) ($row['sold_count'] ?? 0);
        $categoryRevenue = (float) ($row['revenue'] ?? 0);
        $categoriesShare[] = [
            'category' => $row['category'],
            'sold_count' => $soldCount,
            'sold_pct' => $totalSoldCount > 0 ? round(($soldCount / $totalSoldCount) * 100, 2) : 0,
            'revenue' => $categoryRevenue,
            'revenue_pct' => $totalCategoryRevenue > 0 ? round(($categoryRevenue / $totalCategoryRevenue) * 100, 2) : 0
        ];
    }

    // Giữ tương thích ngược: categories cũ chỉ gồm sold_count
    $legacyCategories = array_map(function ($row) {
        return [
            'category' => $row['category'],
            'sold_count' => (float) ($row['sold_count'] ?? 0)
        ];
    }, $categoryData);

    // 3. Top sản phẩm bán chạy (theo số lượng, hòa thì xếp theo doanh thu)
    $stmtTop = $pdo->prepare("
        SELECT
            p.id,
            p.ten_san_pham AS name,
            p.image_url AS image,
            SUM(oi.quantity) AS sold_count,
            SUM(oi.quantity * COALESCE(oi.price, p.price, 0)) AS revenue,
            ROUND(
                SUM(oi.quantity * COALESCE(oi.price, p.price, 0)) / NULLIF(SUM(oi.quantity), 0),
                0
            ) AS price
        FROM order_items oi
        JOIN products p ON oi.product_id = p.id
        JOIN orders o ON oi.order_id = o.id
        WHERE o.status IN $soldStatusSql
          AND oi.product_id IS NOT NULL
          AND p.deleted_at IS NULL
          $periodWhereSql
        GROUP BY p.id, p.ten_san_pham, p.image_url
        HAVING sold_count >= ?
        ORDER BY sold_count DESC, revenue DESC, p.id DESC
        LIMIT $topLimit
    ");
    $topParams = array_merge($periodParams, [$minTopSold]);
    $stmtTop->execute($topParams);
    $topProducts = array_map(static function ($row) {
        return [
            'id' => (int) ($row['id'] ?? 0),
            'name' => $row['name'] ?? '',
            'image' => $row['image'] ?? '',
            'price' => (float) ($row['price'] ?? 0),
            'sold_count' => (int) ($row['sold_count'] ?? 0),
            'revenue' => (float) ($row['revenue'] ?? 0),
        ];
    }, $stmtTop->fetchAll(PDO::FETCH_ASSOC));

    // 4. Sản phẩm sắp hết hàng (tính cả variants)
    $stmtLowStock = $pdo->prepare("
        SELECT p.id, p.ma_san_pham, p.ten_san_pham as name, p.image_url as image,
            CASE 
                WHEN EXISTS (SELECT 1 FROM product_variants pv WHERE pv.product_id = p.id)
                THEN (SELECT COALESCE(SUM(pv2.stock), 0) FROM product_variants pv2 WHERE pv2.product_id = p.id)
                ELSE p.stock
            END as real_stock
        FROM products p
        WHERE p.deleted_at IS NULL
        HAVING real_stock < ?
        ORDER BY real_stock ASC
    ");
    $stmtLowStock->execute([$lowStockThreshold]);
    $lowStockRaw = $stmtLowStock->fetchAll();
    $lowStock = array_map(function ($item) use ($lowStockThreshold) {
        $stock = (int) ($item['real_stock'] ?? 0);
        $severity = $stock <= 2 ? 'critical' : 'warning';
        if ($stock > $lowStockThreshold) {
            $severity = 'normal';
        }
        $item['severity'] = $severity;
        return $item;
    }, $lowStockRaw);

    // 5. Tính tổng doanh thu và lợi nhuận thực tế (từ giá nhập đã chốt trong đơn hàng)
    $stmtProfit = $pdo->prepare("
        SELECT 
            SUM(o.total) as total_revenue,
            SUM(oi.quantity * COALESCE(oi.cost_price, 0)) as total_cost
        FROM orders o
        JOIN order_items oi ON o.id = oi.order_id
        WHERE o.status IN $soldStatusSql
          $periodWhereSql
    ");
    $stmtProfit->execute($periodParams);
    $profitData = $stmtProfit->fetch(PDO::FETCH_ASSOC);

    $totalRevenue = (float) ($profitData['total_revenue'] ?? 0);
    $totalCost = (float) ($profitData['total_cost'] ?? 0);
    $totalProfit = $totalRevenue - $totalCost;

    // 6. Summary KPI cho dashboard
    $stmtSummary = $pdo->prepare("
        SELECT
            COUNT(*) as total_orders,
            SUM(CASE WHEN status IN $soldStatusSql THEN 1 ELSE 0 END) as approved_orders,
            SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
            SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_orders,
            SUM(CASE WHEN status IN $soldStatusSql THEN total ELSE 0 END) as realized_revenue
        FROM orders o
        WHERE 1=1 $periodWhereSql
    ");
    $stmtSummary->execute($periodParams);
    $summaryData = $stmtSummary->fetch(PDO::FETCH_ASSOC) ?: [];

    $approvedOrders = (int) ($summaryData['approved_orders'] ?? 0);
    $cancelledOrders = (int) ($summaryData['cancelled_orders'] ?? 0);
    $totalOrders = (int) ($summaryData['total_orders'] ?? 0);
    $realizedRevenue = (float) ($summaryData['realized_revenue'] ?? 0);
    $totalRevenue = $realizedRevenue;
    $totalProfit = $totalRevenue - $totalCost;
    $avgOrderValue = $approvedOrders > 0 ? ($realizedRevenue / $approvedOrders) : 0;
    $cancelRate = $totalOrders > 0 ? round(($cancelledOrders / $totalOrders) * 100, 2) : 0;

    $previousPeriod = resolvePreviousPeriod($periodMode, $periodStartDate, $periodEndDate, $effectiveYear);
    $prevFrom = $previousPeriod['from'];
    $prevTo = $previousPeriod['to'];

    $stmtCompare = $pdo->prepare("
        SELECT
            (SELECT COALESCE(SUM(total), 0)
             FROM orders
             WHERE status IN $soldStatusSql
               AND DATE(created_at) BETWEEN ? AND ?) as revenue_previous,
            (SELECT COALESCE(SUM(oi.quantity * COALESCE(oi.cost_price, 0)), 0)
             FROM orders o
             JOIN order_items oi ON o.id = oi.order_id
             WHERE o.status IN $soldStatusSql
               AND DATE(o.created_at) BETWEEN ? AND ?) as cost_previous,
            (SELECT COUNT(*)
             FROM orders
             WHERE status IN $soldStatusSql
               AND DATE(created_at) BETWEEN ? AND ?) as approved_previous
    ");
    $stmtCompare->execute([$prevFrom, $prevTo, $prevFrom, $prevTo, $prevFrom, $prevTo]);
    $compareData = $stmtCompare->fetch(PDO::FETCH_ASSOC) ?: [];

    $previousRevenue = (float) ($compareData['revenue_previous'] ?? 0);
    $previousCost = (float) ($compareData['cost_previous'] ?? 0);
    $previousProfit = $previousRevenue - $previousCost;
    $previousApproved = (int) ($compareData['approved_previous'] ?? 0);
    $previousAov = $previousApproved > 0 ? ($previousRevenue / $previousApproved) : 0;

    $calcChangePct = function ($current, $previous) {
        if ((float) $previous === 0.0) {
            return (float) $current > 0 ? 100.0 : 0.0;
        }
        return round((($current - $previous) / $previous) * 100, 2);
    };

    $stmtToday = $pdo->prepare("
        SELECT
            COUNT(*) as today_orders,
            SUM(CASE WHEN status IN $soldStatusSql THEN total ELSE 0 END) as today_revenue
        FROM orders
        WHERE DATE(created_at) = CURDATE()
    ");
    $stmtToday->execute();
    $todayData = $stmtToday->fetch(PDO::FETCH_ASSOC) ?: [];

    // Trả về JSON
    echo json_encode([
        'success' => true,
        'data' => [
            'revenue' => array_values($monthlyRevenue),
            'monthly_finance' => array_values($monthlyFinance),
            'order_status' => $orderStatus,
            'categories' => $legacyCategories,
            'categories_share' => $categoriesShare,
            'topProducts' => $topProducts,
            'top_sales' => [
                'min_sold' => $minTopSold,
                'limit' => $topLimit,
            ],
            'lowStock' => $lowStock,
            'summary' => [
                'total_orders' => $totalOrders,
                'approved_orders' => $approvedOrders,
                'cancelled_orders' => $cancelledOrders,
                'cancel_rate' => $cancelRate,
                'pending_orders' => (int) ($summaryData['pending_orders'] ?? 0),
                'today_orders' => (int) ($todayData['today_orders'] ?? 0),
                'orders_today' => (int) ($todayData['today_orders'] ?? 0),
                'today_revenue' => (float) ($todayData['today_revenue'] ?? 0),
                'avg_order_value' => $avgOrderValue,
                'period' => [
                    'mode' => $periodMode,
                    'year' => (int) $effectiveYear,
                    'from' => $periodStartDate,
                    'to' => $periodEndDate
                ]
            ],
            'financials' => [
                'total_revenue' => $totalRevenue,
                'total_profit' => $totalProfit
            ],
            'finance_compare' => [
                'revenue_current' => $totalRevenue,
                'revenue_previous' => $previousRevenue,
                'revenue_change_pct' => $calcChangePct($totalRevenue, $previousRevenue),
                'profit_current' => $totalProfit,
                'profit_previous' => $previousProfit,
                'profit_change_pct' => $calcChangePct($totalProfit, $previousProfit),
                'aov_current' => $avgOrderValue,
                'aov_previous' => $previousAov,
                'aov_change_pct' => $calcChangePct($avgOrderValue, $previousAov)
            ]
        ]
    ]);
    exit();
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
