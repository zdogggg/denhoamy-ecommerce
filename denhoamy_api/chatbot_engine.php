<?php
require_once 'db.php';
require_once __DIR__ . '/lib/rate_limit.php';
require_once __DIR__ . '/lib/product_pricing.php';
require_once __DIR__ . '/lib/logger.php';

checkChatbotRateLimit();

// ==========================================
// CẤU HÌNH: GROQ (tool calling) → RULE-BASED
// ==========================================
$GROQ_API_KEY = trim(getenv('GROQ_API_KEY') ?: '');
$GROQ_MODEL = getenv('GROQ_MODEL') ?: 'meta-llama/llama-4-scout-17b-16e-instruct';

$chatHistoryLimit = 16;

$requestData = json_decode(file_get_contents('php://input'), true) ?: [];
$userMessage = trim($requestData['message'] ?? '');
$chatHistory = $requestData['history'] ?? [];
$clientContext = $requestData['context'] ?? [];

if ($userMessage === '') {
    echo json_encode(['success' => false, 'message' => 'Ngữ cảnh trống.']);
    exit;
}

if (mb_strlen($userMessage) > 500) {
    echo json_encode(['success' => false, 'message' => 'Tin nhắn quá dài (tối đa 500 ký tự).'], JSON_UNESCAPED_UNICODE);
    exit;
}

$activeEngine = $GROQ_API_KEY !== '' ? 'groq' : 'rule_based';
$responseEngine = 'rule_based';

if (!is_array($chatHistory)) {
    $chatHistory = [];
}
if (count($chatHistory) > $chatHistoryLimit) {
    $chatHistory = array_slice($chatHistory, -$chatHistoryLimit);
}
// Tránh trùng tin user cuối (frontend đã push trước khi gọi API)
$lastIdx = count($chatHistory) - 1;
if ($lastIdx >= 0) {
    $last = $chatHistory[$lastIdx];
    if (
        is_array($last)
        && ($last['sender'] ?? '') === 'user'
        && trim($last['text'] ?? '') === $userMessage
    ) {
        array_pop($chatHistory);
    }
}

/** Sản phẩm gợi ý cho UI (card) */
$uiProducts = [];

function formatPriceVnd($price)
{
    return number_format((float) $price, 0, ',', '.') . ' VNĐ';
}

function mergeUiProducts(array &$uiProducts, $rows, $limit = 5)
{
    if (!is_array($rows)) {
        return;
    }
    foreach ($rows as $row) {
        if (empty($row['id'])) {
            continue;
        }
        $id = (int) $row['id'];
        if (isset($uiProducts[$id])) {
            continue;
        }
        $uiProducts[$id] = [
            'id' => $id,
            'ten_san_pham' => $row['ten_san_pham'] ?? '',
            'ma_san_pham' => $row['ma_san_pham'] ?? '',
            'price' => $row['sale_price'] ?? $row['price'] ?? 0,
            'sale_price' => $row['sale_price'] ?? $row['price'] ?? 0,
            'list_price' => $row['list_price'] ?? 0,
            'has_discount' => !empty($row['has_discount']),
            'show_from' => !empty($row['show_from']),
            'is_hot_deal' => !empty($row['is_hot_deal']),
            'image_url' => $row['image_url'] ?? '',
            'loai_den' => $row['loai_den'] ?? '',
            'stock' => isset($row['stock']) ? (int) $row['stock'] : null,
        ];
        if (count($uiProducts) >= $limit) {
            break;
        }
    }
}

// ==========================================
// TOOL IMPLEMENTATIONS
// ==========================================

/** Giá bán hiệu lực: min biến thể hoặc giá SP */
function effectiveSalePriceSql(): string
{
    return 'COALESCE(
        (SELECT MIN(pv.price) FROM product_variants pv WHERE pv.product_id = p.id AND pv.price > 0),
        p.price
    )';
}

/** Chuẩn hóa "60x80" → nhiều pattern LIKE cho kich_thuoc (60 x 80, 60x80...) */
function dimensionLikeTerms(string $raw): array
{
    $raw = trim($raw);
    if ($raw === '') {
        return [];
    }
    $terms = ['%' . $raw . '%'];
    $compact = preg_replace('/\s+/u', '', mb_strtolower($raw));
    $compact = str_replace(['×', '*', 'X'], 'x', $compact);
    if (preg_match('/^(\d+)\s*x\s*(\d+)$/iu', $compact, $m)) {
        $a = $m[1];
        $b = $m[2];
        $terms[] = "%{$a}%{$b}%";
        $terms[] = "%{$a} x {$b}%";
        $terms[] = "%{$a}x{$b}%";
    }
    return array_values(array_unique($terms));
}

function stripHtmlForChat(string $html): string
{
    $text = html_entity_decode(strip_tags($html), ENT_QUOTES | ENT_HTML5, 'UTF-8');
    return trim(preg_replace('/\s+/u', ' ', $text));
}

/** Cắt bớt nội dung chính sách dài khi trả lời rule-based (Groq tự tóm tắt). */
function truncateFaqForReply(string $text, int $maxLen = 1200): string
{
    if (mb_strlen($text) <= $maxLen) {
        return $text;
    }
    return mb_substr($text, 0, $maxLen) . '…';
}

function faqAnswerText($pdo, string $topic): string
{
    $faqJson = get_store_faq($pdo, $topic);
    $faq = json_decode($faqJson, true);
    $answer = is_array($faq) ? ($faq['answer'] ?? '') : '';
    return truncateFaqForReply($answer);
}

function fetchSettingValue($pdo, string $key): string
{
    $stmt = $pdo->prepare('SELECT setting_value FROM settings WHERE setting_key = ? LIMIT 1');
    $stmt->execute([$key]);
    $val = $stmt->fetchColumn();
    return is_string($val) ? $val : '';
}

/**
 * Chuẩn hóa số tiền VNĐ từ token (10, 10tr, 10.000.000, 10 triệu).
 */
function normalizeVndNumber(string $numPart, string $unit = ''): float
{
    $numPart = trim($numPart);
    $unit = mb_strtolower(trim($unit));

    if (preg_match('/^\d{1,3}(\.\d{3})+$/', $numPart)) {
        $n = (float) str_replace('.', '', $numPart);
    } else {
        $clean = preg_replace('/[^\d.,]/', '', $numPart);
        if (str_contains($clean, ',') && !str_contains($clean, '.')) {
            $clean = str_replace(',', '.', $clean);
        } elseif (substr_count($clean, '.') > 1) {
            $clean = str_replace('.', '', $clean);
        }
        $n = (float) $clean;
    }

    if ($unit === 'triệu' || $unit === 'tr') {
        return $n * 1000000;
    }
    if (in_array($unit, ['nghìn', 'ngàn', 'k'], true)) {
        return $n * 1000;
    }
    if ($n > 0 && $n < 10000) {
        return $n * 1000000;
    }

    return $n;
}

/**
 * @return array{price_min: ?float, price_max: ?float, matched: bool}
 */
function parsePriceRangeFromMessage(string $message): array
{
    $result = ['price_min' => null, 'price_max' => null, 'matched' => false];
    $msg = mb_strtolower(trim($message));
    $msg = str_replace(['–', '—', '−'], '-', $msg);

    if (preg_match(
        '/(?:từ|khoảng)?\s*(\d+(?:\.\d{3})*|\d+(?:[.,]\d+)?)\s*(triệu|tr)?\s*(?:đến|to|-)\s*(\d+(?:\.\d{3})*|\d+(?:[.,]\d+)?)\s*(triệu|tr)\b/iu',
        $msg,
        $m
    )) {
        $unit = $m[4] ?: ($m[2] ?: 'triệu');
        $result['price_min'] = normalizeVndNumber($m[1], $unit);
        $result['price_max'] = normalizeVndNumber($m[3], $unit);
        $result['matched'] = true;
        return $result;
    }

    if (preg_match(
        '/(\d+(?:\.\d{3})*|\d+)\s*-\s*(\d+(?:\.\d{3})*|\d+)\s*(triệu|tr)\b/iu',
        $msg,
        $m
    )) {
        $result['price_min'] = normalizeVndNumber($m[1], $m[3]);
        $result['price_max'] = normalizeVndNumber($m[2], $m[3]);
        $result['matched'] = true;
        return $result;
    }

    if (preg_match(
        '/(?:trên|lớn hơn|hơn|>=|≥)\s*(\d+(?:\.\d{3})*|\d+(?:[.,]\d+)?)\s*(triệu|tr)\b/iu',
        $msg,
        $m
    )) {
        $result['price_min'] = normalizeVndNumber($m[1], $m[2]);
        $result['matched'] = true;
        return $result;
    }

    if (preg_match(
        '/từ\s*(\d+(?:\.\d{3})*|\d+(?:[.,]\d+)?)\s*(triệu|tr)\s*trở\s*lên/iu',
        $msg,
        $m
    )) {
        $result['price_min'] = normalizeVndNumber($m[1], $m[2]);
        $result['matched'] = true;
        return $result;
    }

    if (preg_match(
        '/(?:dưới|nhỏ hơn|tối đa|<=|≤)\s*(\d+(?:\.\d{3})*|\d+(?:[.,]\d+)?)\s*(triệu|tr|nghìn|ngàn|k)?/iu',
        $msg,
        $m
    )) {
        $result['price_max'] = normalizeVndNumber($m[1], $m[2] ?? 'triệu');
        $result['matched'] = true;
        return $result;
    }

    return $result;
}

/** @return array<string, mixed> */
function buildSearchArgsFromParsedPrice(array $parsedPrice, int $limit = 8): array
{
    $args = ['limit' => $limit];
    if ($parsedPrice['price_min'] !== null) {
        $args['price_min'] = $parsedPrice['price_min'];
    }
    if ($parsedPrice['price_max'] !== null) {
        $args['price_max'] = $parsedPrice['price_max'];
    }
    return $args;
}

function ruleBasedReplyFromPriceSearch($pdo, array $parsedPrice, string $prefix): ?string
{
    global $uiProducts;

    $searchJson = search_products($pdo, buildSearchArgsFromParsedPrice($parsedPrice, 8));
    $search = json_decode($searchJson, true);
    if (!empty($search['found']) && !empty($search['items'])) {
        $reply = $prefix . "Tìm thấy sản phẩm theo khoảng giá:\n";
        foreach ($search['items'] as $item) {
            $reply .= ruleBasedFormatProductLine($item) . "\n";
        }
        $reply .= "\nHotline: 0978.897.579";
        return $reply;
    }
    if (empty($search['found'])) {
        return $prefix . "Hiện không có sản phẩm trong khoảng giá Quý khách yêu cầu. "
            . "Quý khách vui lòng gọi hotline **0978.897.579** để được tư vấn mẫu gần nhất.";
    }

    return null;
}

/** Từ marketing/stopword — bỏ khi tokenize tìm kiếm */
function searchStopwords(): array
{
    return [
        'sang', 'trọng', 'cao', 'cấp', 'đẹp', 'mẫu', 'loại', 'tìm', 'xem', 'cho', 'của', 'và', 'các', 'có', 'không',
        'nào', 'gì', 'thì', 'là', 'được', 'với', 'trong', 'tại', 'shop', 'cửa', 'hàng', 'bạn', 'tôi', 'ạ', 'nhé',
        'hỏi', 'muốn', 'cần', 'giúp', 'về', 'thêm', 'nhiều', 'rẻ', 'đắt', 'triệu', 'vnđ', 'đồng', 'từ', 'đến', 'trên', 'dưới',
    ];
}

/** Tách câu hỏi dài thành từ khóa AND (vd. "đèn chùm pha lê sang trọng" → đèn + chùm + pha + lê) */
function tokenizeSearchKeywords(string $text): array
{
    $text = mb_strtolower(trim($text));
    $text = preg_replace('/[^\p{L}\p{N}\s]/u', ' ', $text);
    $parts = preg_split('/\s+/u', $text, -1, PREG_SPLIT_NO_EMPTY) ?: [];
    $stop = array_flip(searchStopwords());
    $tokens = [];
    foreach ($parts as $part) {
        if (mb_strlen($part) < 2) {
            continue;
        }
        if (isset($stop[$part])) {
            continue;
        }
        if (!in_array($part, $tokens, true)) {
            $tokens[] = $part;
        }
    }
    return array_slice($tokens, 0, 6);
}

function appendKeywordTokenConditions(array &$where, array &$params, array $tokens): void
{
    $fieldMatch = '(p.ten_san_pham LIKE ? OR p.ma_san_pham LIKE ? OR p.loai_den LIKE ?
        OR p.description LIKE ? OR s.chat_lieu LIKE ? OR s.kich_thuoc LIKE ?
        OR s.khong_gian_lap_dat LIKE ? OR s.phong_cach LIKE ?)';
    foreach ($tokens as $token) {
        $term = '%' . $token . '%';
        $where[] = $fieldMatch;
        for ($i = 0; $i < 8; $i++) {
            $params[] = $term;
        }
    }
}

/** LLM thường gửi string thay vì đúng type → ép kiểu an toàn */
function sanitizeSearchArgs(array $args): array
{
    if (isset($args['price_min']))    $args['price_min']    = (float) $args['price_min'];
    if (isset($args['price_max']))    $args['price_max']    = (float) $args['price_max'];
    if (isset($args['limit']))        $args['limit']        = (int) $args['limit'];
    if (isset($args['hot_deal_only'])) $args['hot_deal_only'] = filter_var($args['hot_deal_only'], FILTER_VALIDATE_BOOLEAN);
    if (isset($args['in_stock_only'])) $args['in_stock_only'] = filter_var($args['in_stock_only'], FILTER_VALIDATE_BOOLEAN);
    return $args;
}

function search_products($pdo, array $rawArgs)
{
    $args = sanitizeSearchArgs($rawArgs);
    $where = ['p.deleted_at IS NULL'];
    $params = [];

    $keyword = trim($args['keyword'] ?? '');
    if ($keyword !== '') {
        $tokens = tokenizeSearchKeywords($keyword);
        if ($tokens === []) {
            $tokens = [mb_strtolower($keyword)];
        }
        appendKeywordTokenConditions($where, $params, $tokens);
    }

    if (!empty($args['loai_den'])) {
        $where[] = 'p.loai_den LIKE ?';
        $params[] = '%' . trim($args['loai_den']) . '%';
    }

    if (!empty($args['phong_cach'])) {
        $where[] = 's.phong_cach LIKE ?';
        $params[] = '%' . trim($args['phong_cach']) . '%';
    }

    if (!empty($args['khong_gian'])) {
        $where[] = 's.khong_gian_lap_dat LIKE ?';
        $params[] = '%' . trim($args['khong_gian']) . '%';
    }

    $kichThuoc = trim($args['kich_thuoc'] ?? '');
    if ($kichThuoc !== '') {
        $sizeTerms = dimensionLikeTerms($kichThuoc);
        $sizeOr = [];
        foreach ($sizeTerms as $sizeTerm) {
            $sizeOr[] = '(s.kich_thuoc LIKE ? OR EXISTS (
                SELECT 1 FROM product_variants pv
                WHERE pv.product_id = p.id AND pv.kich_thuoc LIKE ?
            ))';
            $params[] = $sizeTerm;
            $params[] = $sizeTerm;
        }
        if ($sizeOr !== []) {
            $where[] = '(' . implode(' OR ', $sizeOr) . ')';
        }
    }

    $effectivePrice = effectiveSalePriceSql();
    if (!empty($args['price_min'])) {
        $where[] = "($effectivePrice) >= ?";
        $params[] = (float) $args['price_min'];
    }

    if (!empty($args['price_max'])) {
        $where[] = "($effectivePrice) <= ?";
        $params[] = (float) $args['price_max'];
    }

    if (!empty($args['hot_deal_only'])) {
        $where[] = 'p.is_hot_deal = 1';
    }

    if (!empty($args['in_stock_only'])) {
        $where[] = 'p.stock > 0';
    }

    $limit = min(8, max(1, (int) ($args['limit'] ?? 6)));
    $whereClause = implode(' AND ', $where);

    $sql = "SELECT p.id, p.ten_san_pham, p.ma_san_pham, p.loai_den, p.price, p.old_price, p.is_hot_deal,
                   p.image_url, p.stock, s.phong_cach, s.chat_lieu, s.kich_thuoc, s.khong_gian_lap_dat
            FROM products p
            LEFT JOIN product_specs s ON p.id = s.product_id
            WHERE $whereClause
            ORDER BY p.is_hot_deal DESC, p.id DESC
            LIMIT $limit";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

    global $uiProducts;

    if (!$results) {
        return json_encode(['found' => false, 'message' => 'Không tìm thấy sản phẩm phù hợp.'], JSON_UNESCAPED_UNICODE);
    }

    $productIds = array_map(static fn ($r) => (int) $r['id'], $results);
    $variantsByProduct = productPricingFetchVariantsByProductIds($pdo, $productIds);

    foreach ($results as &$r) {
        $pid = (int) $r['id'];
        $variants = $variantsByProduct[$pid] ?? [];
        productPricingEnrichRow($r, $variants);
        $r['price_formatted'] = formatPriceVnd($r['sale_price']);
        if (!empty($r['list_price'])) {
            $r['list_price_formatted'] = formatPriceVnd($r['list_price']);
        }
        $r['product_path'] = '/product/' . $r['id'];
    }
    unset($r);

    mergeUiProducts($uiProducts, $results);

    return json_encode(['found' => true, 'count' => count($results), 'items' => $results], JSON_UNESCAPED_UNICODE);
}

function get_product_specs($pdo, $keyword)
{
    $keyword = trim($keyword);
    if ($keyword === '') {
        return json_encode(['found' => false, 'message' => 'Thiếu mã hoặc tên sản phẩm.'], JSON_UNESCAPED_UNICODE);
    }

    $sql = "SELECT p.id, p.ten_san_pham, p.ma_san_pham, p.loai_den, p.price, p.old_price, p.stock,
                   p.image_url, p.description, p.is_hot_deal,
                   s.phong_cach, s.khong_gian_lap_dat, s.bong_den, s.dien_ap, s.chat_lieu, s.kich_thuoc, s.tinh_trang
            FROM products p
            LEFT JOIN product_specs s ON p.id = s.product_id
            WHERE p.deleted_at IS NULL
              AND (p.ma_san_pham = ? OR p.id = ? OR p.ten_san_pham LIKE ?)
            LIMIT 1";

    $stmt = $pdo->prepare($sql);
    $idTry = ctype_digit($keyword) ? (int) $keyword : 0;
    $stmt->execute([$keyword, $idTry, '%' . $keyword . '%']);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$product) {
        return json_encode(['found' => false, 'message' => 'Không tìm thấy sản phẩm.'], JSON_UNESCAPED_UNICODE);
    }

    $vStmt = $pdo->prepare('SELECT id, kich_thuoc, anh_sang, price, cost_price, stock FROM product_variants WHERE product_id = ?');
    $vStmt->execute([$product['id']]);
    $product['variants'] = $vStmt->fetchAll(PDO::FETCH_ASSOC);
    productPricingEnrichRow($product, $product['variants']);
    $product['price_formatted'] = formatPriceVnd($product['sale_price']);
    if (!empty($product['list_price'])) {
        $product['list_price_formatted'] = formatPriceVnd($product['list_price']);
    }
    $product['product_path'] = '/product/' . $product['id'];

    if (!empty($product['variants']) && count($product['variants']) > 1) {
        $summaryLines = [];
        foreach (array_slice($product['variants'], 0, 3) as $v) {
            $label = trim(($v['kich_thuoc'] ?? '') . ' ' . ($v['anh_sang'] ?? ''));
            if ($label === '') {
                $label = 'Biến thể #' . ($v['id'] ?? '');
            }
            $vPrice = formatPriceVnd($v['price'] ?? 0);
            $vStock = (int) ($v['stock'] ?? 0);
            $summaryLines[] = "{$label}: {$vPrice} (còn {$vStock} sp)";
        }
        $product['variants_summary'] = implode('; ', $summaryLines);
    }

    global $uiProducts;
    mergeUiProducts($uiProducts, [$product]);

    return json_encode(['found' => true, 'product' => $product], JSON_UNESCAPED_UNICODE);
}

function list_product_types($pdo)
{
    $stmt = $pdo->query("SELECT DISTINCT loai_den AS name, COUNT(*) AS cnt
                         FROM products WHERE deleted_at IS NULL AND loai_den IS NOT NULL AND loai_den != ''
                         GROUP BY loai_den ORDER BY cnt DESC LIMIT 15");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    return json_encode(['types' => $rows], JSON_UNESCAPED_UNICODE);
}

function get_store_faq($pdo, $topic)
{
    $faqs = [
        'hours' => 'Giờ mở cửa: Thứ 2 – Thứ 7, 8:00 – 17:30. Chủ nhật nghỉ.',
        'shipping' => 'Giao hàng toàn quốc. Đơn nội thành Hải Phòng giao nhanh 1–2 ngày. Tỉnh khác 3–7 ngày tùy khu vực. Phí ship báo khi xác nhận đơn.',
        'warranty' => 'Sản phẩm mới 100%, bảo hành theo chính sách từng dòng đèn (thường 6–24 tháng). Giữ hóa đơn và tem bảo hành.',
        'return' => 'Đổi trả trong 7 ngày nếu lỗi do nhà sản xuất, sản phẩm nguyên seal/chưa lắp. Liên hệ hotline trước khi gửi hàng.',
        'payment' => 'Thanh toán COD hoặc PayOS (trực tuyến) khi đặt hàng trên website.',
        'contact' => 'Hotline: 0978.897.579 | 0225.653.3618. Địa chỉ: 905 Nguyễn Văn Linh, An Biên, Hải Phòng. Facebook Messenger: Đèn Hoa Mỹ.',
        'general' => 'Đèn Hoa Mỹ chuyên đèn trang trí cao cấp: đèn chùm, thả, ốp trần, bàn, quạt. Tư vấn miễn phí qua hotline hoặc chat.',
    ];

    $topic = strtolower(trim($topic ?: 'general'));
    $content = $faqs[$topic] ?? $faqs['general'];

    $policyByTopic = [
        'warranty' => 'policy_bao_hanh',
        'return' => 'policy_doi_tra',
        'shipping' => 'policy_van_chuyen',
        'payment' => 'policy_huong_dan',
    ];

    if (isset($policyByTopic[$topic])) {
        $policyHtml = fetchSettingValue($pdo, $policyByTopic[$topic]);
        if ($policyHtml !== '') {
            $policyText = stripHtmlForChat($policyHtml);
            if ($policyText !== '') {
                $content = $policyText;
            }
        }
    }

    return json_encode(['topic' => $topic, 'answer' => $content], JSON_UNESCAPED_UNICODE);
}

function compare_products($pdo, array $rawIds)
{
    global $uiProducts;

    $ids = [];
    foreach ($rawIds as $id) {
        $id = (int) $id;
        if ($id > 0) {
            $ids[] = $id;
        }
    }
    $ids = array_slice(array_unique($ids), 0, 3);

    if (count($ids) < 2) {
        return json_encode([
            'found' => false,
            'message' => 'Cần ít nhất 2 ID sản phẩm (tối đa 3) để so sánh.',
        ], JSON_UNESCAPED_UNICODE);
    }

    $items = [];
    foreach ($ids as $id) {
        $specJson = get_product_specs($pdo, (string) $id);
        $spec = json_decode($specJson, true);
        if (!empty($spec['found']) && !empty($spec['product'])) {
            $p = $spec['product'];
            $items[] = [
                'id' => $p['id'],
                'ten_san_pham' => $p['ten_san_pham'],
                'ma_san_pham' => $p['ma_san_pham'],
                'sale_price' => $p['sale_price'] ?? $p['price'],
                'list_price' => $p['list_price'] ?? 0,
                'price_formatted' => $p['price_formatted'] ?? formatPriceVnd($p['sale_price'] ?? 0),
                'stock' => $p['stock'] ?? 0,
                'loai_den' => $p['loai_den'] ?? '',
                'phong_cach' => $p['phong_cach'] ?? '',
                'chat_lieu' => $p['chat_lieu'] ?? '',
                'kich_thuoc' => $p['kich_thuoc'] ?? '',
                'khong_gian_lap_dat' => $p['khong_gian_lap_dat'] ?? '',
                'product_path' => $p['product_path'] ?? '/product/' . $p['id'],
                'variants' => $p['variants'] ?? [],
            ];
        }
    }

    if (count($items) < 2) {
        return json_encode([
            'found' => false,
            'message' => 'Không đủ dữ liệu để so sánh (cần ít nhất 2 sản phẩm hợp lệ).',
        ], JSON_UNESCAPED_UNICODE);
    }

    return json_encode(['found' => true, 'count' => count($items), 'items' => $items], JSON_UNESCAPED_UNICODE);
}

// ==========================================
// TOOLS (OpenAI format)
// ==========================================
$tools = [
    [
        'type' => 'function',
        'function' => [
            'name' => 'search_products',
            'description' => 'Tìm sản phẩm trong kho: tên, mã, mô tả, chất liệu, kích thước, không gian lắp đặt, loại đèn, phong cách, khoảng giá (theo giá bán thực tế/biến thể), hot deal, còn hàng.',
            'parameters' => [
                'type' => 'object',
                'properties' => [
                    'keyword' => ['type' => 'string', 'description' => 'Từ khóa: tên, mô tả, chất liệu (pha lê, đồng...), loại đèn...'],
                    'loai_den' => ['type' => 'string', 'description' => 'Loại đèn, ví dụ: Đèn chùm, Đèn thả'],
                    'phong_cach' => ['type' => 'string', 'description' => 'Phong cách: Tân Cổ Điển, Hiện Đại, Cổ Điển...'],
                    'khong_gian' => ['type' => 'string', 'description' => 'Không gian lắp đặt: Phòng khách, Phòng ăn, Phòng ngủ...'],
                    'kich_thuoc' => ['type' => 'string', 'description' => 'Kích thước đèn, ví dụ: 60x80 hoặc 50 x 80 (cm)'],
                    'price_min' => ['type' => 'string', 'description' => 'Giá bán tối thiểu VNĐ. "1-10 triệu" → min=1000000. "trên 10 triệu" → min=10000000'],
                    'price_max' => ['type' => 'string', 'description' => 'Giá bán tối đa VNĐ. "1-10 triệu" → max=10000000. "dưới 5tr" → max=5000000'],
                    'hot_deal_only' => ['type' => 'string', 'description' => 'true nếu chỉ hot deal, false nếu không'],
                    'in_stock_only' => ['type' => 'string', 'description' => 'true nếu chỉ còn hàng, false nếu không'],
                    'limit' => ['type' => 'string', 'description' => 'Số kết quả tối đa (1-8), ví dụ: 5'],
                ],
            ],
        ],
    ],
    [
        'type' => 'function',
        'function' => [
            'name' => 'get_product_specs',
            'description' => 'Chi tiết một sản phẩm theo mã SP, ID hoặc tên gần đúng. Dùng khi khách hỏi mã cụ thể, giá, tồn kho, biến thể.',
            'parameters' => [
                'type' => 'object',
                'properties' => [
                    'keyword' => ['type' => 'string', 'description' => 'Mã SP (DC04200), ID hoặc tên sản phẩm'],
                ],
                'required' => ['keyword'],
            ],
        ],
    ],
    [
        'type' => 'function',
        'function' => [
            'name' => 'list_product_types',
            'description' => 'Liệt kê các loại đèn đang kinh doanh. Dùng khi khách hỏi "bên mình có những loại đèn gì".',
            'parameters' => ['type' => 'object', 'properties' => new stdClass()],
        ],
    ],
    [
        'type' => 'function',
        'function' => [
            'name' => 'get_store_faq',
            'description' => 'Chính sách cửa hàng (đọc nội dung từ website admin): giờ mở cửa, giao hàng, bảo hành, đổi trả, thanh toán/hướng dẫn mua, liên hệ. Không dùng cho giá sản phẩm.',
            'parameters' => [
                'type' => 'object',
                'properties' => [
                    'topic' => [
                        'type' => 'string',
                        'enum' => ['hours', 'shipping', 'warranty', 'return', 'payment', 'contact', 'general'],
                        'description' => 'Chủ đề FAQ',
                    ],
                ],
                'required' => ['topic'],
            ],
        ],
    ],
    [
        'type' => 'function',
        'function' => [
            'name' => 'compare_products',
            'description' => 'So sánh 2–3 sản phẩm theo ID (giá, kích thước, chất liệu, tồn kho). Dùng khi khách phân vân giữa các mẫu đã xem hoặc ID trong ngữ cảnh.',
            'parameters' => [
                'type' => 'object',
                'properties' => [
                    'product_ids' => [
                        'type' => 'array',
                        'items' => ['type' => 'string'],
                        'description' => 'Danh sách ID sản phẩm, ví dụ: ["77", "80"]',
                    ],
                ],
                'required' => ['product_ids'],
            ],
        ],
    ],
];

// ==========================================
// SYSTEM PROMPT + CONTEXT
// ==========================================
$contextBlock = '';
if (!empty($clientContext['productId'])) {
    $ctxProduct = get_product_specs($pdo, (string) $clientContext['productId']);
    $contextBlock = "\n\n## NGỮ CẢNH TRANG WEB\nKhách đang xem trang chi tiết sản phẩm. Dữ liệu tham khảo:\n" . $ctxProduct
        . "\nƯu tiên tư vấn về sản phẩm này trước khi gợi ý mẫu khác.";
}
$lastIds = [];
if (!empty($clientContext['lastProductIds']) && is_array($clientContext['lastProductIds'])) {
    foreach ($clientContext['lastProductIds'] as $id) {
        $id = (int) $id;
        if ($id > 0) {
            $lastIds[] = $id;
        }
    }
    $lastIds = array_slice(array_unique($lastIds), 0, 5);
}
if ($lastIds !== []) {
    $contextBlock .= "\n\n## SẢN PHẨM VỪA GỢI Ý (hội thoại gần nhất)\nID: " . implode(', ', $lastIds);
    foreach (array_slice($lastIds, 0, 2) as $pid) {
        $contextBlock .= "\n---\n" . get_product_specs($pdo, (string) $pid);
    }
    $contextBlock .= "\nKhi khách hỏi tiếp (cái này, mẫu trên, còn hàng, giá...) mà không nêu mã → dùng get_product_specs với ID trên.";
    if (count($lastIds) >= 2) {
        $contextBlock .= "\nKhi khách **so sánh / phân vân** giữa các mẫu → gọi compare_products với product_ids: ["
            . implode(', ', array_map(static fn ($id) => '"' . $id . '"', array_slice($lastIds, 0, 3))) . '].';
    }
}
if (!empty($clientContext['route'])) {
    $contextBlock .= "\nTrang hiện tại: " . $clientContext['route'];
}

$parsedPrice = parsePriceRangeFromMessage($userMessage);
if ($parsedPrice['matched']) {
    $preSearchJson = search_products($pdo, buildSearchArgsFromParsedPrice($parsedPrice, 8));
    $minLabel = $parsedPrice['price_min'] !== null ? number_format($parsedPrice['price_min'], 0, ',', '.') : '—';
    $maxLabel = $parsedPrice['price_max'] !== null ? number_format($parsedPrice['price_max'], 0, ',', '.') : '—';
    $contextBlock .= "\n\n## KẾT QUẢ LỌC GIÁ ĐÃ TRA (bắt buộc — chỉ liệt kê SP trong JSON, không bịa thêm)\n";
    $contextBlock .= "Khoảng giá parse: min={$minLabel} VNĐ, max={$maxLabel} VNĐ\n";
    $contextBlock .= $preSearchJson;
    $contextBlock .= "\nNếu found=false: nói rõ không có mẫu trong khoảng giá và mời gọi hotline. Không gợi ý SP ngoài danh sách.";
}

$systemPrompt = <<<PROMPT
## VAI TRÒ
Bạn là **Trợ lý AI** của **Đèn Hoa Mỹ** — đèn trang trí nội thất (chùm, thả, ốp trần, bàn, quạt; tân cổ điển & hiện đại).

## THÔNG TIN CỬA HÀNG
- Địa chỉ: 905 Nguyễn Văn Linh, An Biên, Hải Phòng
- Hotline: 0978.897.579 | 0225.653.3618
- Giờ: Thứ 2 – Thứ 7, 8:00 – 17:30 (Chủ nhật nghỉ)

## QUY TẮC
1. Xưng **"tôi"**, gọi khách **"Quý khách"**. Không emoji.
2. **Không bịa** tên, giá, mã, tồn kho. Chỉ dùng dữ liệu từ tool.
3. Giá bán thực tế là **sale_price** (hoặc price sau enrich). Nếu có **list_price** > sale_price → đó là giá gốc (đang giảm / Hot Deal). SP có biến thể có thể ghi **Từ X VNĐ** (show_from). Nếu tool trả **variants_summary** hoặc show_from=true → luôn ghi **Từ X VNĐ** và gợi ý khách cho biết kích thước / không gian cần lắp.
4. Câu hỏi về **sản phẩm/giá/mã/tồn kho** → **bắt buộc** gọi `search_products` hoặc `get_product_specs`.
5. Câu hỏi **ship, bảo hành, đổi trả, thanh toán, hướng dẫn mua** → gọi `get_store_faq` (topic: shipping / warranty / return / payment).
6. Ngoài phạm vi đèn/cửa hàng → từ chối lịch sự + hotline.
7. Có kết quả tool → bảng markdown: Tên | Giá | Loại/Chất liệu | Kích thước | Tồn kho. Giá = sale_price; nếu có list_price thì ghi giá gốc → giá bán.
8. Gợi ý xem chi tiết: dùng link markdown `[Xem chi tiết →](/product/{id})` — **không** liệt kê URL `/product/...` dạng text thuần hoặc bullet chỉ có đường dẫn. Khách sẽ thấy thẻ sản phẩm bên dưới — không cần lặp danh sách link.
9. Tối đa 3–4 đoạn. Kết bằng câu mời tư vấn thêm.
10. Câu hỏi nối tiếp (cái này, mẫu trên, còn hàng, giá bao nhiêu) → **ưu tiên** `get_product_specs` với ID/mã trong NGỮ CẢNH trước khi `search_products` mới.
11. Khách **so sánh 2–3 mẫu** hoặc "nên chọn mẫu nào" khi đã có ID trong ngữ cảnh → `compare_products` (không bịa).
12. Lọc **giá** → `price_min` / `price_max` (VNĐ nguyên): **1–10 triệu** = min 1000000, max 10000000; **trên 10 triệu** = min 10000000; **dưới 5tr** = max 5000000. Nếu có block KẾT QUẢ LỌC GIÁ ĐÃ TRA → dùng đúng dữ liệu đó. Lọc **kích thước** → `kich_thuoc`. Lọc **phòng** → `khong_gian`.

## TƯ VẤN KỸ THUẬT (không cần tool nếu không hỏi mã/giá cụ thể)
Được trả lời ngắn gọn dựa trên kinh nghiệm ngành đèn, **không bịa** tên/mã/giá sản phẩm:
- Treo đèn thả bàn ăn: thường đáy chao cách mặt bàn khoảng **75–90 cm** (bàn cao ~75 cm → treo ~150–165 cm từ sàn).
- Phòng khách/biệt thự: gợi ý phong cách (Tân Cổ Điển, Cổ Điển) + sau đó `search_products` để đưa mẫu thật.
- Diện tích phòng (m²): tư vấn **nguyên tắc** (phòng lớn → chùm size lớn hơn), hỏi thêm kích thước phòng/trần; có thể gợi ý SP qua `search_products` + `khong_gian` / `phong_cach`.
- Pha lê vs đồng: giải thích chất liệu/ánh sáng; nếu cần mẫu trong shop → `search_products` keyword pha lê / đồng.

## VÍ DỤ
Khách: "Đèn từ 1 đến 10 triệu?"
→ search_products(price_min=1000000, price_max=10000000, limit=8)
Khách: "Đèn trên 10 triệu?"
→ search_products(price_min=10000000, limit=8)
Khách: "Đèn thả dưới 1 triệu?"
→ search_products(loai_den="đèn thả", price_max=1000000, in_stock_only=true)
Khách: "Có đèn chùm pha lê không?"
→ search_products(keyword="đèn chùm pha lê", in_stock_only=true)
$contextBlock
PROMPT;

$messages = [['role' => 'system', 'content' => $systemPrompt]];

foreach ($chatHistory as $msg) {
    if (!is_array($msg) || empty($msg['text'])) {
        continue;
    }
    $role = ($msg['sender'] === 'bot' || $msg['sender'] === 'model') ? 'assistant' : 'user';
    $messages[] = ['role' => $role, 'content' => $msg['text']];
}

$messages[] = ['role' => 'user', 'content' => $userMessage];

// ==========================================
// GỌI API GROQ (OpenAI-compatible)
// ==========================================
function callGroq($messages, $tools, $model, $api_key)
{
    if ($api_key === '') {
        return ['error' => 'Groq API Key chưa được cấu hình.'];
    }

    $payload = [
        'model' => $model,
        'messages' => $messages,
        'temperature' => 0.25,
        'max_tokens' => 2048,
    ];

    if (!empty($tools)) {
        $payload['tools'] = $tools;
        $payload['tool_choice'] = 'auto';
    }

    $ch = curl_init('https://api.groq.com/openai/v1/chat/completions');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_TIMEOUT => 45,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $api_key,
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
    ]);
    $response = curl_exec($ch);
    if (curl_errno($ch)) {
        return ['error' => curl_error($ch)];
    }

    $result = json_decode($response, true);

    // Kiểm tra rate limit / quota error (429)
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    if ($httpCode === 429 || (isset($result['error']['code']) && $result['error']['code'] === 'rate_limit_exceeded')) {
        return ['error' => 'rate_limit', 'engine' => 'groq'];
    }

    return $result;
}

// ==========================================
// RULE-BASED FALLBACK (khi Groq không khả dụng)
// ==========================================
function ruleBasedResolveProductId(array $clientContext): ?int
{
    if (!empty($clientContext['productId'])) {
        $id = (int) $clientContext['productId'];
        return $id > 0 ? $id : null;
    }
    if (!empty($clientContext['lastProductIds']) && is_array($clientContext['lastProductIds'])) {
        foreach ($clientContext['lastProductIds'] as $id) {
            $id = (int) $id;
            if ($id > 0) {
                return $id;
            }
        }
    }
    return null;
}

function ruleBasedFormatProductLine(array $p): string
{
    $priceText = formatPriceVnd($p['sale_price'] ?? $p['price'] ?? 0);
    if (!empty($p['show_from'])) {
        $priceText = 'Từ ' . $priceText;
    }
    if (!empty($p['list_price'])) {
        $priceText = formatPriceVnd($p['list_price']) . ' → ' . $priceText;
    }
    if (!empty($p['is_hot_deal'])) {
        $priceText .= ' (Hot Deal)';
    }
    $stock = isset($p['stock']) ? (int) $p['stock'] : 0;
    $stockText = $stock > 0 ? "Còn {$stock} sp" : 'Hết hàng';
    return "• {$p['ten_san_pham']} - {$priceText} ({$stockText})";
}

function ruleBasedReply($userMessage, $pdo, array $clientContext = [])
{
    global $uiProducts;

    $prefix = '';
    $msg = mb_strtolower($userMessage);
    $reply = '';
    $contextProductId = ruleBasedResolveProductId($clientContext);
    $isFollowUp = (bool) preg_match(
        '/(còn hàng|tồn kho|hết hàng|cái này|mẫu này|mẫu trên|mẫu đó|giá|bao nhiêu|rẻ hơn|đắt hơn|ship|giao hàng)/u',
        $msg
    );

    $lastIds = [];
    if (!empty($clientContext['lastProductIds']) && is_array($clientContext['lastProductIds'])) {
        foreach ($clientContext['lastProductIds'] as $id) {
            $id = (int) $id;
            if ($id > 0) {
                $lastIds[] = $id;
            }
        }
    }
    $isCompare = (bool) preg_match('/(phân vân|so sánh|chọn mẫu|mẫu nào|nên chọn)/u', $msg);
    if ($isCompare && count($lastIds) >= 2) {
        $cmpJson = compare_products($pdo, array_slice($lastIds, 0, 3));
        $cmp = json_decode($cmpJson, true);
        if (!empty($cmp['found']) && !empty($cmp['items'])) {
            $reply = $prefix . "So sánh nhanh các mẫu:\n";
            foreach ($cmp['items'] as $item) {
                $reply .= ruleBasedFormatProductLine($item) . "\n";
                if (!empty($item['kich_thuoc'])) {
                    $reply .= "  Kích thước: {$item['kich_thuoc']}\n";
                }
                if (!empty($item['chat_lieu'])) {
                    $reply .= "  Chất liệu: {$item['chat_lieu']}\n";
                }
            }
            $reply .= "\nQuý khách bấm **Xem chi tiết** trên từng thẻ sản phẩm bên dưới. Hotline: 0978.897.579";
            return $reply;
        }
    }

    if ($contextProductId && $isFollowUp) {
        $specJson = get_product_specs($pdo, (string) $contextProductId);
        $spec = json_decode($specJson, true);
        if (!empty($spec['found']) && !empty($spec['product'])) {
            $p = $spec['product'];
            $reply = $prefix . ruleBasedFormatProductLine($p);
            if (preg_match('/(còn hàng|tồn kho|hết hàng)/u', $msg)) {
                $stock = (int) ($p['stock'] ?? 0);
                $reply .= "\n\n" . ($stock > 0
                    ? "Sản phẩm **còn hàng** ({$stock} sp trong kho)."
                    : 'Sản phẩm **tạm hết hàng**. Quý khách gọi hotline để đặt trước.');
            } elseif (preg_match('/(ship|giao hàng|vận chuyển)/u', $msg)) {
                $reply .= "\n\n" . faqAnswerText($pdo, 'shipping');
            }
            $reply .= "\n\nHotline: 0978.897.579";
            return $reply;
        }
    }

    if (preg_match('/(giờ|mở cửa|làm việc|lúc nào)/', $msg)) {
        $reply = $prefix . "Cửa hàng Đèn Hoa Mỹ mở cửa T2–T7, 8:00–17:30. Chủ nhật nghỉ.\nĐịa chỉ: 905 Nguyễn Văn Linh, An Biên, Hải Phòng.\nHotline: 0978.897.579";
    } elseif (preg_match('/(giao hàng|ship|vận chuyển|phí ship)/u', $msg)) {
        $reply = $prefix . faqAnswerText($pdo, 'shipping') . "\n\nHotline: 0978.897.579";
    } elseif (preg_match('/đổi trả/u', $msg)) {
        $reply = $prefix . faqAnswerText($pdo, 'return') . "\n\nHotline: 0978.897.579";
    } elseif (preg_match('/(bảo hành|hư hỏng)/u', $msg)) {
        $reply = $prefix . faqAnswerText($pdo, 'warranty') . "\n\nHotline: 0978.897.579";
    } elseif (preg_match('/(thanh toán|trả tiền|chuyển khoản|banking|cod|payos|mua hàng)/ui', $msg)) {
        $reply = $prefix . faqAnswerText($pdo, 'payment') . "\n\nHotline: 0978.897.579";
    } else {
        $parsedPrice = parsePriceRangeFromMessage($userMessage);
        if ($parsedPrice['matched']) {
            $priceReply = ruleBasedReplyFromPriceSearch($pdo, $parsedPrice, $prefix);
            if ($priceReply !== null) {
                return $priceReply;
            }
        }

        $kichThuoc = null;
        if (preg_match('/(\d+)\s*[x×]\s*(\d+)/u', $msg, $km)) {
            $kichThuoc = $km[1] . 'x' . $km[2];
        }

        if ($kichThuoc !== null) {
            $searchJson = search_products($pdo, ['limit' => 5, 'kich_thuoc' => $kichThuoc]);
            $search = json_decode($searchJson, true);
            if (!empty($search['found']) && !empty($search['items'])) {
                $reply = $prefix . "Tìm thấy sản phẩm phù hợp:\n";
                foreach ($search['items'] as $item) {
                    $reply .= ruleBasedFormatProductLine($item) . "\n";
                }
                $reply .= "\nHotline: 0978.897.579";
                return $reply;
            }
        }

        $searchJson = search_products($pdo, ['keyword' => $userMessage, 'limit' => 5]);
        $search = json_decode($searchJson, true);
        if (!empty($search['found']) && !empty($search['items'])) {
            $reply = $prefix . "Tìm thấy sản phẩm liên quan:\n";
            foreach ($search['items'] as $item) {
                $reply .= ruleBasedFormatProductLine($item) . "\n";
            }
            $reply .= "\nHotline: 0978.897.579";
            return $reply;
        }

        $reply = "Xin lỗi Quý khách, hệ thống AI tạm bận. Quý khách vui lòng gọi hotline 0978.897.579 hoặc 0225.653.3618 để được tư vấn trực tiếp.";
    }

    return $reply;
}

$max_iterations = 5;
$current_iteration = 0;
$finalReply = '';

// ====== ENGINE CHÍNH: GROQ (với tool calling) ======
if ($activeEngine === 'groq') {
    $groqRetried = false;
    while ($current_iteration < $max_iterations) {
        $groqResponse = callGroq($messages, $tools, $GROQ_MODEL, $GROQ_API_KEY);

        if (isset($groqResponse['error']) && $groqResponse['error'] === 'rate_limit') {
            if (!$groqRetried) {
                $groqRetried = true;
                logWarning('Groq rate limit, retry sau 2s', []);
                sleep(2);
                continue;
            }
            logWarning('Groq rate limit sau retry, fallback rule-based', []);
            $activeEngine = 'rule_based';
            break;
        }

        if (isset($groqResponse['error'])) {
            logWarning('Groq API error', ['error' => $groqResponse['error']]);
            $activeEngine = 'rule_based';
            break;
        }

        if (!isset($groqResponse['choices'][0]['message'])) {
            $apiMsg = $groqResponse['error']['message'] ?? null;
            $finalReply = $apiMsg
                ? 'Xin lỗi Quý khách, ' . $apiMsg
                : 'Xin lỗi Quý khách, tôi chưa xử lý được yêu cầu này. Quý khách vui lòng gọi hotline 0978.897.579.';
            break;
        }

        $responseMessage = $groqResponse['choices'][0]['message'];
        $finishReason = $groqResponse['choices'][0]['finish_reason'] ?? '';

        if ($finishReason === 'tool_use_failed') {
            $fallbackResponse = callGroq($messages, [], $GROQ_MODEL, $GROQ_API_KEY);
            $finalReply = $fallbackResponse['choices'][0]['message']['content']
                ?? 'Xin lỗi Quý khách, tôi không thể tra cứu kho lúc này. Vui lòng gọi hotline 0978.897.579.';
            $responseEngine = 'groq';
            break;
        }

        if ($finishReason === 'tool_calls' && !empty($responseMessage['tool_calls'])) {
            $messages[] = $responseMessage;

            foreach ($responseMessage['tool_calls'] as $toolCall) {
                $functionName = $toolCall['function']['name'] ?? '';
                $args = json_decode($toolCall['function']['arguments'] ?? '{}', true) ?? [];

                switch ($functionName) {
                    case 'search_products':
                        $toolResult = search_products($pdo, $args);
                        break;
                    case 'get_product_specs':
                        $toolResult = get_product_specs($pdo, $args['keyword'] ?? '');
                        break;
                    case 'list_product_types':
                        $toolResult = list_product_types($pdo);
                        break;
                    case 'get_store_faq':
                        $toolResult = get_store_faq($pdo, $args['topic'] ?? 'general');
                        break;
                    case 'compare_products':
                        $ids = $args['product_ids'] ?? [];
                        if (is_string($ids)) {
                            $decoded = json_decode($ids, true);
                            $ids = is_array($decoded) ? $decoded : preg_split('/\s*,\s*/', $ids);
                        }
                        if (!is_array($ids)) {
                            $ids = [];
                        }
                        $toolResult = compare_products($pdo, $ids);
                        break;
                    default:
                        $toolResult = json_encode(['error' => "Hàm '$functionName' không tồn tại."], JSON_UNESCAPED_UNICODE);
                }

                $messages[] = [
                    'role' => 'tool',
                    'tool_call_id' => $toolCall['id'],
                    'content' => $toolResult,
                ];
            }

            $current_iteration++;
            continue;
        }

        if (!empty($responseMessage['content'])) {
            $finalReply = $responseMessage['content'];
            $responseEngine = 'groq';
            break;
        }

        $finalReply = 'Xin lỗi Quý khách, tôi chưa có câu trả lời phù hợp. Vui lòng liên hệ hotline.';
        break;
    }
}

// ====== FALLBACK: RULE-BASED ======
if ($finalReply === '') {
    $finalReply = ruleBasedReply($userMessage, $pdo, is_array($clientContext) ? $clientContext : []);
    $responseEngine = 'rule_based';
}

header('Content-Type: application/json; charset=utf-8');

logInfo('chatbot_message', [
    'engine' => $responseEngine,
    'msg_len' => mb_strlen($userMessage),
    'products_count' => count($uiProducts),
    'ip_hash' => substr(hash('sha256', $_SERVER['REMOTE_ADDR'] ?? ''), 0, 12),
]);

echo json_encode([
    'success' => true,
    'reply' => $finalReply,
    'products' => array_values($uiProducts),
    'engine' => $responseEngine,
], JSON_UNESCAPED_UNICODE);
