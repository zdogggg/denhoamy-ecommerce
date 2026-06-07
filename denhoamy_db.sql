-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Máy chủ: db
-- Thời gian đã tạo: Th6 03, 2026 lúc 02:27 PM
-- Phiên bản máy phục vụ: 8.0.45
-- Phiên bản PHP: 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE DATABASE IF NOT EXISTS `denhoamy_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `denhoamy_db`;

--
-- Cơ sở dữ liệu: `denhoamy_db`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `admins`
--

CREATE TABLE `admins` (
  `id` int NOT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('admin','staff') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'staff' COMMENT 'admin = toan quyen, staff = gioi han',
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `avatar_url` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `permissions` json DEFAULT NULL COMMENT 'Phân quyền chi tiết cho từng admin',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `admins`
--

INSERT INTO `admins` (`id`, `username`, `role`, `password`, `name`, `phone`, `email`, `avatar_url`, `permissions`, `is_active`, `created_at`) VALUES
(1, 'admin', 'admin', '$2y$10$FFkw65Abpyo1tek/HUFL8ut0doc7RG0yUPczl6Qr9oz8QRpw.cw.y', 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', NULL, NULL, 1, '2026-04-09 02:33:55'),
(4, 'staff01', 'staff', '$2y$10$vXaOUV2Qkzwz3JNMj0l2fe.06qxEclaBK0yJGgfUlO87KBZLqdL3S', 'Nguyễn Đạt', '0397215638', 'staff01@denhoamy.com', NULL, '{\"news\": true, \"orders\": true, \"policy\": true, \"coupons\": true, \"reviews\": true, \"accounts\": false, \"products\": true, \"settings\": false, \"customers\": false, \"dashboard\": true, \"categories\": true}', 1, '2026-04-14 04:40:31');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `carts`
--

CREATE TABLE `carts` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `session_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `carts`
--

INSERT INTO `carts` (`id`, `user_id`, `session_id`, `created_at`, `updated_at`) VALUES
(1, 2, NULL, '2026-06-02 15:59:06', '2026-06-02 15:59:06');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `cart_items`
--

CREATE TABLE `cart_items` (
  `id` int NOT NULL,
  `cart_id` int NOT NULL,
  `product_id` int NOT NULL,
  `variant_id` int DEFAULT NULL,
  `quantity` int DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `categories`
--

CREATE TABLE `categories` (
  `id` int NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_id` int DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `categories`
--

INSERT INTO `categories` (`id`, `name`, `parent_id`, `sort_order`, `created_at`, `deleted_at`) VALUES
(2, 'Đèn Chùm', NULL, 0, '2026-04-09 03:05:07', NULL),
(3, 'Đèn Chùm Cổ Điển', 2, 0, '2026-04-09 03:05:16', NULL),
(4, 'Đèn Chùm Hiện Đại', 2, 0, '2026-04-09 03:05:30', NULL),
(5, 'Đèn Chùm Tân Cổ Điển', 2, 0, '2026-04-09 03:05:40', NULL),
(6, 'Đèn Thả', NULL, 0, '2026-04-09 03:05:56', NULL),
(7, 'Đèn Thả Cổ Điển', 6, 0, '2026-04-09 03:06:09', NULL),
(8, 'Đèn Thả Hiện Đại', 6, 0, '2026-04-09 03:06:42', NULL),
(9, 'Đèn Thả Tân Cổ Điển', 6, 0, '2026-04-09 03:06:53', NULL),
(10, 'Đèn Bàn', NULL, 0, '2026-04-09 03:07:00', NULL),
(11, 'Đèn Bàn Cổ Điển', 10, 0, '2026-04-09 03:07:20', NULL),
(12, 'Đèn Bàn Hiện Đại', 10, 0, '2026-04-09 03:07:31', NULL),
(13, 'Đèn Bàn Tân Cổ Điển', 10, 0, '2026-04-09 03:07:43', NULL),
(14, 'Đèn Ốp Trần', NULL, 0, '2026-04-09 03:07:55', NULL),
(15, 'Đèn Ốp Trần Cổ Điển', 14, 0, '2026-04-09 03:08:13', NULL),
(16, 'Đèn Ốp Trần Hiện Đại', 14, 0, '2026-04-09 03:08:26', NULL),
(17, 'Đèn Ốp Trần Tân Cổ Điển', 14, 0, '2026-04-09 03:08:42', NULL),
(18, 'Đèn Quạt', NULL, 0, '2026-04-09 03:08:51', NULL),
(19, 'Đèn Quạt Cổ Điển', 18, 0, '2026-04-09 03:09:02', NULL),
(20, 'Đèn Quạt Hiện Đại', 18, 0, '2026-04-09 03:09:18', NULL),
(21, 'Đèn Quạt Tân Cổ Điển', 18, 0, '2026-04-09 03:09:27', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `chat_messages`
--

CREATE TABLE `chat_messages` (
  `id` int NOT NULL,
  `session_id` int NOT NULL COMMENT 'Phien chat chua tin nhan nay',
  `sender` enum('user','bot') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'user = khach hang gui, bot = AI tra loi',
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Noi dung tin nhan',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `chat_sessions`
--

CREATE TABLE `chat_sessions` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL COMMENT 'NULL neu la khach vang lai chua dang nhap',
  `session_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Token dinh danh phien chat tren trinh duyet',
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tieu de phien chat (lay tu cau hoi dau tien)',
  `message_count` int DEFAULT '0' COMMENT 'Tong so tin nhan trong phien',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `coupons`
--

CREATE TABLE `coupons` (
  `id` int NOT NULL,
  `code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `discount_percent` int DEFAULT '0',
  `discount_amount` decimal(15,0) DEFAULT '0',
  `min_order_value` decimal(15,0) DEFAULT '0',
  `usage_limit` int DEFAULT NULL,
  `used_count` int DEFAULT '0',
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `max_discount_amount` decimal(15,0) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `coupons`
--

INSERT INTO `coupons` (`id`, `code`, `discount_percent`, `discount_amount`, `min_order_value`, `usage_limit`, `used_count`, `start_date`, `end_date`, `is_active`, `created_at`, `max_discount_amount`) VALUES
(1, 'GIAIPHONGMIENNAM', 10, 0, 1000000, 10, 4, '2026-04-09', '2026-05-06', 1, '2026-04-09 14:54:26', NULL),
(3, 'TETTHIEUNHI', 10, 0, 1000000, 10, 0, '2026-05-30', '2026-06-03', 1, '2026-04-10 14:56:17', 200000),
(5, 'FLASHSALE', 0, 100000, 1000000, 10, 5, '2026-05-26', '2026-06-30', 1, '2026-05-04 10:26:56', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `inventory_history`
--

CREATE TABLE `inventory_history` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `variant_id` int DEFAULT NULL,
  `admin_id` int DEFAULT NULL,
  `type` enum('in','out') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'in',
  `quantity` int DEFAULT NULL,
  `cost` decimal(15,0) DEFAULT '0',
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `news`
--

CREATE TABLE `news` (
  `id` int NOT NULL,
  `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `thumbnail` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `summary` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `author_id` int DEFAULT NULL,
  `is_published` tinyint(1) DEFAULT '1',
  `view_count` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `news`
--

INSERT INTO `news` (`id`, `title`, `slug`, `thumbnail`, `summary`, `content`, `author_id`, `is_published`, `view_count`, `created_at`, `updated_at`, `deleted_at`) VALUES
(1, 'OKOK', 'okok', '/uploads/products/gallery_69d7baf6dc8bf2.30903295.jpg', 'Okok', '<p><img src=\"/uploads/news/news_content_69d7bed31ccc09.69716638.png\"></p>', 1, 1, 10, '2026-04-09 14:43:13', '2026-04-15 11:26:17', NULL),
(3, 'ĐÈN CHÙM HIỆN ĐẠI DC03682 – SANG TRỌNG CHO KHÔNG GIAN SỐNG', 'den-chum-hien-dai-dc03682-sang-trong-cho-khong-gian-song', '/uploads/products/gallery_69df75c34443a5.37941740.jpg', 'Đèn chùm DC03682 là lựa chọn hoàn hảo dành cho những ai yêu thích phong cách hiện đại pha chút tân cổ điển. Với thiết kế tinh tế, chất liệu cao cấp và ánh sáng ấm áp, sản phẩm giúp nâng tầm không gian phòng khách, phòng ăn hoặc phòng ngủ.', '<h3>Khi ánh sáng trở thành nghệ thuật</h3><p>Nhìn vào <strong>đèn chùm DC03682</strong>, bạn sẽ dễ dàng cảm nhận được sự tinh tế trong từng chi tiết. Khung đèn kim loại mạ vàng uốn cong mềm mại, kết hợp cùng chao đèn thủy tinh trong suốt tạo nên một tổng thể vừa hiện đại, vừa mang hơi hướng tân cổ điển.</p><p>Không quá cầu kỳ, nhưng đủ để trở thành <strong>tâm điểm của cả căn phòng</strong>.</p><h3>Phù hợp với nhiều không gian sống</h3><p>Một trong những điểm mạnh của DC03682 là tính linh hoạt trong thiết kế. Dù bạn đang sở hữu:</p><ul><li>Căn hộ chung cư hiện đại</li><li>Nhà phố phong cách tối giản</li><li>Hay biệt thự sang trọng</li></ul><p>… thì mẫu đèn này vẫn có thể hòa hợp một cách tự nhiên.</p><p>Đặc biệt, khi lắp đặt tại <strong>phòng khách hoặc bàn ăn</strong>, ánh sáng vàng ấm từ đèn sẽ tạo cảm giác <strong>ấm cúng, gần gũi nhưng vẫn rất đẳng cấp</strong>.</p><h3>Thiết kế tối ưu cả thẩm mỹ và công năng</h3><p>Không chỉ đẹp, DC03682 còn được thiết kế để sử dụng lâu dài:</p><ul><li>Chất liệu kim loại sơn tĩnh điện → chống gỉ, bền màu</li><li>Chao thủy tinh dày → tán sáng tốt, không chói</li><li>Sử dụng bóng LED → tiết kiệm điện, tuổi thọ cao</li></ul><p>Tất cả đều hướng đến một trải nghiệm: <strong>đẹp – bền – tiện dụng</strong>.</p><h3>Vì sao nên chọn đèn chùm DC03682?</h3><p>Trong vô số mẫu đèn trên thị trường, DC03682 nổi bật nhờ:</p><p>✔ Thiết kế cân đối, dễ phối nội thất</p><p> ✔ Ánh sáng dịu, không gây khó chịu cho mắt</p><p> ✔ Phù hợp nhiều phong cách từ hiện đại đến tân cổ điển</p><p> ✔ Tăng giá trị thẩm mỹ cho không gian sống</p><h3>Một vài lưu ý khi sử dụng</h3><p>Để đảm bảo độ bền và hiệu quả ánh sáng, bạn nên:</p><ul><li>Lắp đặt bởi kỹ thuật viên chuyên nghiệp</li><li>Sử dụng đúng loại bóng phù hợp (LED/E27)</li><li>Vệ sinh định kỳ để giữ độ sáng và tính thẩm mỹ</li></ul><p><br></p><h3><img src=\"/uploads/news/news_content_69df75ab612755.46455853.jpg\">Kết luận</h3><p><strong>Đèn chùm DC03682</strong> không chỉ là một thiết bị chiếu sáng, mà còn là một món đồ trang trí mang lại “linh hồn” cho không gian sống. Nếu bạn đang tìm kiếm một giải pháp vừa đẹp mắt, vừa tiện dụng để nâng cấp ngôi nhà của mình, thì đây chắc chắn là một lựa chọn đáng cân nhắc.</p>', 1, 1, 18, '2026-04-15 11:25:56', '2026-05-27 03:53:41', NULL),
(4, 'Thị Trường Đèn Chiếu Sáng Hải Phòng: Xu Hướng Và Địa Chỉ Uy Tín', 'thi-truong-den-chieu-sang-hai-phong', '/uploads/products/gallery_6a1666d756b3e6.09076950.jpg', 'Thị trường đèn chiếu sáng Hải Phòng đang bùng nổ với xu hướng đèn LED tiết kiệm điện và đèn hoa mỹ sang trọng. Khám phá ngay xu hướng và địa chỉ cung cấp uy tín!', '<h2><strong>Thị Trường Đèn Chiếu Sáng Hải Phòng: Bùng Nổ Cùng Tốc Độ Đô Thị Hóa</strong></h2><p>Thị trường đèn chiếu sáng tại thành phố Hải Phòng đang phát triển mạnh mẽ hơn bao giờ hết. Nhờ tốc độ đô thị hóa nhanh chóng, sự bùng nổ của các khu công nghiệp và nhu cầu nâng cấp hạ tầng giao thông, hệ thống chiếu sáng tại đất Cảng đang có bước chuyển mình lớn.</p><p>Hiện nay, các công trình công cộng, tuyến đường lớn và khu đô thị mới đều ưu tiên đầu tư hệ thống đèn LED hiện đại nhằm tối ưu hiệu quả chiếu sáng và tiết kiệm điện năng.</p><p><img src=\"/uploads/products/gallery_6a166a11c1bbd9.03964136.jpg\"></p><h2><strong>Đèn Trang Trí Và Đèn Hoa Mỹ: Điểm Nhấn Không Gian Sống Thượng Lưu</strong></h2><p>Bên cạnh phân khúc chiếu sáng cơ bản, phân khúc đèn hoa mỹ và đèn trang trí đang trở thành \"tâm điểm\" tại thị trường Hải Phòng.</p><ul><li><strong>Ứng dụng đa dạng:</strong> Từ đèn chùm pha lê sang trọng, đèn sân vườn hiện đại đến các loại đèn trang trí nội thất độc đáo.</li><li><strong>Đối tượng khách hàng:</strong> Được các gia đình, chủ nhà hàng, khách sạn cao cấp đặc biệt ưa chuộng để nâng tầm thẩm mỹ cho không gian.</li></ul><p>Hải Phòng không chỉ là nơi tiêu thụ mà còn đóng vai trò là đầu mối phân phối, cung cấp nguồn hàng lớn cho toàn bộ thị trường miền Bắc, đáp ứng thị hiếu ngày càng khắt khe của người tiêu dùng.</p><p><strong>Xu hướng thiết kế:</strong> Các dòng sản phẩm liên tục được cập nhật mẫu mã, trải dài từ phong cách Hiện đại, Tối giản (Minimalism) cho đến Tân cổ điển sang trọng, phục vụ trọn vẹn mọi phân khúc khách hàng.</p><p><img src=\"/uploads/products/gallery_6a1670dfe33aa6.96095728.jpg\"></p><h2><strong>Công Nghệ LED Thông Minh – Xu Hướng Chủ Đạo Tương Lai</strong></h2><p><strong>Công nghệ LED tiếp tục khẳng định vị thế độc tôn nhờ vào 3 ưu điểm vượt trội:</strong></p><ol><li><strong>Tiết kiệm điện năng</strong> tối đa so với đèn truyền thống.</li><li><strong>Tuổi thọ cao</strong>, giảm thiểu chi phí bảo trì, thay mới.</li><li><strong>Thân thiện với môi trường</strong> và an toàn cho mắt người sử dụng.</li></ol><p>Với tiềm năng phát triển dồi dào từ các dự án đô thị và nhu cầu làm đẹp nhà cửa của người dân, thị trường đèn Hải Phòng hứa hẹn sẽ còn tiến xa trong thời gian tới.</p><p><img src=\"/uploads/products/gallery_6a1671258eb888.81317916.png\"></p><h2><strong>Đèn Hoa Mỹ – Giải Pháp Chiếu Sáng Toàn Diện Tại Hải Phòng</strong></h2><p><strong>Nếu bạn đang tìm kiếm các giải pháp chiếu sáng đô thị, đèn công nghiệp hay những mẫu đèn trang trí thời thượng nhất tại Hải Phòng, Đèn Hoa Mỹ</strong> tự hào là đối tác tin cậy của mọi công trình. Chúng tôi cam kết mang đến sản phẩm chính hãng, tiết kiệm năng lượng với chính sách bảo hành dài hạn.</p><ul><li><strong>Địa chỉ:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng</li><li><strong>Hotline/Zalo:</strong> 02256533618 - 0978897579</li><li><strong>Website:</strong> denhoamy.store</li></ul>', 1, 1, 9, '2026-05-27 03:38:43', '2026-05-27 05:07:18', NULL),
(5, 'Mách Bạn Giải Pháp Tiết Kiệm Điện Mùa Nắng Nóng Từ Đèn LED Tại Hải Phòng', 'giai-phap-tiet-kiem-dien-mua-he-hai-phong', '/uploads/products/gallery_6a166e637cd5f3.69971748.png', 'Nắng nóng kéo dài tại Hải Phòng khiến hóa đơn tiền điện tăng cao? Khám phá ngay giải pháp tiết kiệm điện thông minh từ hệ thống đèn LED và Đèn Hoa Mỹ!', '<p><img src=\"/uploads/products/gallery_6a166fec3cadd9.49423836.png\"></p><h2><strong>Giải Pháp Tiết Kiệm Điện Mùa Nắng Nóng Từ Hệ Thống Chiếu Sáng Gia Đình</strong></h2><p>Mùa hè năm nay, tình trạng nắng nóng kéo dài kỷ lục khiến nhu cầu sử dụng điện tại Hải Phòng tăng vọt. Hệ quả là nhiều khu vực phải đối mặt với tình trạng quá tải và lịch cắt điện luân phiên. Trong bối cảnh này, việc tiết kiệm điện không chỉ giúp cắt giảm chi phí sinh hoạt mà còn giảm tải áp lực cho hệ thống điện toàn thành phố.</p><p>Trước tình hình đó, nhiều hộ gia đình Đất Cảng đã chủ động tìm kiếm các giải pháp xanh, bắt đầu từ việc thay thế các thiết bị tiêu thụ điện lớn bằng những giải pháp tiết kiệm năng lượng, đặc biệt là hệ thống chiếu sáng.</p><h2><strong>Tại Sao Đèn LED Là \"Cứu Cánh\" Cho Hóa Đơn Tiền Điện Ngày Hè?</strong></h2><p>Theo các chuyên gia điện năng, đèn chiếu sáng là thiết bị hoạt động liên tục mỗi ngày. Việc chuyển đổi từ bóng đèn truyền thống (đèn sợi đốt, halogen) sang <strong>công nghệ đèn LED</strong> mang lại những lợi ích vượt trội:</p><ul><li><strong>Siêu tiết kiệm điện:</strong> Tiêu hao điện năng thấp hơn đến <strong>80%</strong> so với bóng đèn thông thường nhưng vẫn đảm bảo hiệu suất phát quang tối ưu.</li><li><strong>Tỏa nhiệt cực thấp:</strong> Khác với đèn sợi đốt tỏa nhiệt lượng lớn làm phòng thêm oi bức, đèn LED hoạt động rất mát, giúp giảm tải công suất cho điều hòa nhiệt độ.</li><li><strong>Tuổi thọ bền bỉ:</strong> Thời gian sử dụng lâu dài, giảm thiểu chi phí bảo trì, thay mới trong những năm tới.</li></ul><p><img src=\"/uploads/products/gallery_6a166f37b82ca2.29461779.jpg\"></p><h2><strong>Đèn Hoa Mỹ Hải Phòng: Đẹp Thời Thượng, Tối Ưu Điện Năng</strong></h2><p>Nắm bắt nhu cầu thực tế của người dân, các cửa hàng đèn hoa mỹ tại Hải Phòng đã nhanh chóng đẩy mạnh các dòng sản phẩm tích hợp công nghệ xanh. Giờ đây, khách hàng không còn phải đánh đổi giữa \"thẩm mỹ\" và \"tiết kiệm\".</p><p>Các dòng sản phẩm đang được săn đón nhất hiện nay bao gồm:</p><ol><li><strong>Đèn LED trang trí hiện đại:</strong> Kiểu dáng tinh tế, sử dụng chip LED cao cấp tiết kiệm điện.</li><li><strong>Đèn chùm LED thế hệ mới:</strong> Mang lại vẻ đẹp sang trọng, đẳng cấp cho phòng khách mà không lo tốn điện.</li><li><strong>Đèn thông minh (Smart Lighting):</strong> Tích hợp công nghệ cảm biến và điều chỉnh độ sáng linh hoạt theo nhu cầu thực tế, tối ưu hóa lượng điện tiêu thụ.</li></ol><p><strong>Xu hướng mua sắm:</strong> Người tiêu dùng Hải Phòng hiện nay đã thông thái hơn rất nhiều. Thay vì chọn các dòng đèn giá rẻ, trôi nổi, họ ưu tiên đầu tư vào các sản phẩm đèn hoa mỹ có nguồn gốc rõ ràng, độ bền cao và khả năng tiết kiệm điện lâu dài để tối ưu chi phí về sau.</p><p><img src=\"/uploads/products/gallery_6a1670531abdf2.28382046.jpg\"></p><h2><strong>Sẵn Sàng Sống Xanh Cùng Đèn Hoa Mỹ</strong></h2><p>Đừng để hóa đơn tiền điện mùa hè trở thành gánh nặng của gia đình bạn. Hãy để <strong>Đèn Hoa Mỹ</strong> đồng hành cùng bạn kiến tạo không gian sống vừa sang trọng, vừa kinh tế với bộ sưu tập đèn LED và đèn hoa mỹ tiết kiệm điện mới nhất.</p><ul><li><strong>Ưu đãi mùa hè:</strong> Tư vấn và khảo sát hệ thống chiếu sáng tiết kiệm điện miễn phí tại Hải Phòng.</li><li><strong>Địa chỉ:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng</li><li><strong>Hotline/Zalo:</strong> 02256533618 - 0978897579</li><li><strong>Website:</strong> denhoamy.store</li></ul><h2><br></h2>', 1, 1, 5, '2026-05-27 04:15:42', '2026-06-02 06:11:10', NULL),
(6, 'Xu Hướng Chọn Đèn Chùm Hoa Mỹ Cho Phòng Khách Biệt Thự Tại Hải Phòng', 'den-chum-hoa-my-phong-khach-biet-thu-hai-phong', '/uploads/products/gallery_6a1679b614a348.34727094.jpg', 'Nâng tầm đẳng cấp không gian sống với xu hướng chọn đèn chùm hoa mỹ cho phòng khách biệt thự tại Hải Phòng. Khám phá ngay các mẫu đèn sang trọng nhất!', '<p><img src=\"/uploads/products/gallery_6a1679c73f4763.71983316.jpg\"></p><h2><strong>Xu Hướng Chọn Đèn Chùm Hoa Mỹ Cho Phòng Khách Biệt Thự Tại Hải Phòng</strong></h2><p>Phòng khách được ví như \"gương mặt\" của một ngôi nhà, nơi thể hiện rõ nét nhất gu thẩm mỹ và đẳng cấp của gia chủ. Tại Hải Phòng, với sự bùng nổ của các khu đô thị cao cấp như Vinhomes Imperia, Vinhomes Marina hay các căn biệt thự sân vườn sang trọng, việc thiết kế không gian sống thượng lưu đang trở thành xu hướng mạnh mẽ.</p><p>Để kiến tạo nên một không gian phòng khách biệt thự bề thế, một hệ thống chiếu sáng thông thường là chưa đủ. Đó là lý do tại sao các dòng <strong>Đèn chùm Hoa Mỹ</strong> cao cấp đang trở thành món \"trang sức\" không thể thiếu, nâng tầm đẳng cấp cho mọi công trình Đất Cảng.</p><h2><strong>Tại Sao Biệt Thự Cao Cấp Cần Một Bộ Đèn Chùm Hoa Mỹ?</strong></h2><p>Không đơn thuần là thiết bị phát sáng, một bộ đèn chùm hoa mỹ được ví như một tác phẩm nghệ thuật ngự trị tại trung tâm phòng khách. Đối với không gian biệt thự, dòng đèn này mang lại những giá trị vượt trội:</p><ul><li><strong>Tạo điểm nhấn thị giác tuyệt đối:</strong> Trần nhà biệt thự thường cao và thoáng. Một bộ đèn chùm pha lê hay đèn thả thông tầng kiêu sa sẽ lấp đầy \"khoảng trống\", tạo nên sự bề thế ngay khi bước vào nhà.</li><li><strong>Tôn vinh ngôn ngữ thiết kế:</strong> Dù biệt thự của bạn theo đuổi phong cách Tân cổ điển hoàng gia hay Hiện đại sang trọng, đèn hoa mỹ luôn có những thiết kế đồng điệu để tôn lên đường nét của phào chỉ, nội thất da, gỗ cao cấp.</li><li><strong>Phong thủy tốt lành:</strong> Ánh sáng từ các hạt pha lê cao cấp giúp tán sắc ánh sáng lung linh, kích hoạt năng lượng tích cực, mang lại may mắn và sự thịnh vượng cho gia chủ.</li></ul><h2><strong>Hai Xu Hướng Đèn Chùm Biệt Thự Được Ưa Chuộng Nhất Tại Hải Phòng</strong></h2><p><strong>1. Đèn chùm pha lê Tân cổ điển – Vẻ đẹp hoàng gia vượt thời gian</strong></p><p>Hợp với các căn biệt thự có kiến trúc Châu Âu, sử dụng nhiều chi tiết dát vàng, phào chỉ cầu kỳ. Thân đèn thường được làm bằng đồng nguyên chất kết hợp với vô số hạt pha lê K9 tinh khiết, mang lại ánh sáng lộng lẫy, quyền quý.</p><p><strong>2. Đèn thả thông tầng hiện đại – Sự đột phá của không gian mở</strong></p><p>Dành riêng cho các căn biệt thự có thiết kế thông tầng, phòng khách duplex hiện đại. Các mẫu đèn thả dáng dài, đèn thả vòng LED mềm mại tạo nên một \"dải ngân hà\" ánh sáng nghệ thuật, thanh lịch và đầy phóng khoáng.</p><p><img src=\"/uploads/products/gallery_6a167a6785e339.71815631.png\"></p><h2><strong>Bí Quyết Chọn Đèn Chùm Hoa Mỹ Chuẩn Kiến Trúc Cho Gia Chủ</strong></h2><p>Để chọn được một bộ đèn chùm xứng tầm với không gian biệt thự, các gia chủ tại Hải Phòng cần lưu ý 3 nguyên tắc cốt lõi từ chuyên gia:</p><ul><li><strong>Tỷ lệ thuận với chiều cao trần:</strong> Nếu trần cao từ 3m - 3.5m, nên ưu tiên đèn chùm có độ thả vừa phải. Nếu là không gian thông tầng trên 4.5m, các dòng đèn thả dáng dài, kết cấu nhiều tầng mới đủ sức cân bằng không gian.</li><li><strong>Độ tương hợp màu sắc:</strong> Ánh sáng vàng ấm (2700K - 3000K) luôn là lựa chọn hoàn hảo nhất cho phòng khách biệt thự, mang lại cảm giác ấm cúng, sang trọng và tôn da, tôn màu nội thất.</li><li><strong>Ưu tiên công nghệ LED thông minh:</strong> Hãy chọn các mẫu đèn hoa mỹ sử dụng chip LED cao cấp để vừa có ánh sáng mịn, không nhấp nháy gây hại mắt, lại vừa tiết kiệm điện năng và có tuổi thọ lên tới hàng chục năm.</li></ul><p><img src=\"/uploads/products/gallery_6a167b8449f1d6.45958635.png\"></p><h2><strong>Đèn Hoa Mỹ – Tinh Hoa Đèn Trang Trí Biệt Thự Tại Hải Phòng</strong></h2><p>Tự hào là đơn vị tiên phong cung cấp các giải pháp chiếu sáng nghệ thuật cao cấp tại Hải Phòng, <strong>Đèn Hoa Mỹ</strong> sở hữu bộ sưu tập đèn chùm hoa mỹ độc bản, cam kết nâng tầm đẳng cấp cho không gian sống của bạn.</p><ul><li><strong>Sản phẩm chính hãng:</strong> Nhập khẩu nguyên bộ, chất liệu đồng, pha lê K9 cao cấp, bảo hành dài hạn.</li><li><strong>Dịch vụ chuyên nghiệp:</strong> Đội ngũ kiến trúc sư ánh sáng hỗ trợ khảo sát tận công trình tại Hải Phòng, tư vấn mẫu đèn đo ni đóng giày cho từng gia chủ.</li><li><strong>Hỗ trợ lắp đặt:</strong> Đội ngũ kỹ thuật viên tay nghề cao, đảm bảo thi công an toàn, thẩm mỹ tuyệt đối cho các hệ trần thạch cao, trần gỗ biệt thự.</li></ul><p>Liên hệ ngay với chúng tôi hôm nay để nhận catalog các mẫu đèn chùm biệt thự mới nhất và ưu đãi đặc quyền!</p><ul><li><strong>Showroom:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng</li><li><strong>Hotline/Zalo:</strong> 02256533618 - 0978897579</li><li><strong>Website:</strong> denhoamy.store</li></ul>', 1, 1, 3, '2026-05-27 05:05:21', '2026-05-27 05:08:13', NULL),
(7, 'Thiết Kế Ánh Sáng Phòng Ngủ Ấm Cúng Với Đèn Trang Trí Tại Hải Phòng', 'thiet-ke-anh-sang-phong-ngu-den-trang-tri-hai-phong', '/uploads/products/gallery_6a1fd484543006.85326699.png', 'Bí quyết thiết kế ánh sáng phòng ngủ ấm cúng và lãng mạn với các mẫu đèn trang trí, đèn hoa mỹ hot nhất tại Hải Phòng. Xem ngay để nâng tầm không gian sống!', '<h2><img src=\"/uploads/products/gallery_6a1fd48b8aa382.42167263.png\"></h2><h2><strong>Thiết Kế Ánh Sáng Phòng Ngủ Ấm Cúng Với Đèn Trang Trí Đèn Hoa Mỹ Tại Hải Phòng</strong></h2><p>Nếu như phòng khách là nơi khẳng định đẳng cấp của gia chủ với những bộ đèn chùm bề thế, thì phòng ngủ lại là không gian riêng tư tối thượng – nơi chúng ta trút bỏ mọi áp lực sau một ngày làm việc dài để tái tạo năng lượng.</p><p>Tại Hải Phòng, xu hướng thiết kế phòng ngủ hiện đại ngày nay không chỉ dừng lại ở chăn ấm nệm êm, mà còn đặc biệt chú trọng vào <strong>nghệ thuật bài trí ánh sáng</strong>. Việc lựa chọn các dòng <strong>đèn trang trí và đèn hoa mỹ</strong> phù hợp chính là chìa khóa vàng giúp biến phòng ngủ của bạn thành một không gian nghỉ dưỡng ấm cúng, lãng mạn và đầy tinh tế.</p><h2><strong>Tầm Quan Trọng Của Ánh Sáng Đèn Hoa Mỹ Trong Phòng Ngủ</strong></h2><p><img src=\"/uploads/products/gallery_6a1fd670a403a4.71857778.png\"></p><p>Không ít gia đình tại Hải Phòng thường mắc sai lầm khi chỉ lắp một chiếc đèn tuýp hoặc đèn LED âm trần tỏa ánh sáng trắng buốt cho phòng ngủ. Ánh sáng quá chói này vô tình ức chế hormone melatonin, gây khó ngủ và khiến không gian trở nên lạnh lẽo.</p><p>Thay vào đó, hệ thống đèn trang trí hoa mỹ thế hệ mới mang lại những giá trị tuyệt vời:</p><ul><li><strong>Tạo hiệu ứng thư giãn sâu:</strong> Ánh sáng dịu nhẹ, được tán sắc qua các chất liệu cao cấp như thủy tinh mờ, pha lê hay vải nghệ thuật giúp xoa dịu thị giác, đưa bạn vào giấc ngủ ngon và sâu hơn.</li><li><strong>Tăng tính thẩm mỹ và lãng mạn:</strong> Một chiếc đèn thả trần nghệ thuật hay đèn tường tinh tế sẽ là điểm nhấn đắt giá, giúp căn phòng có chiều sâu và cá tính riêng, cực kỳ phù hợp cho các cặp đôi mới cưới làm phòng tân hôn.</li><li><strong>Linh hoạt theo nhu cầu sử dụng:</strong> Đọc sách, xem điện thoại, trang điểm hay ngủ ngon – mỗi hoạt động đều cần một kịch bản ánh sáng khác nhau mà chỉ đèn thông minh, đèn hoa mỹ nhiều chế độ mới đáp ứng được.</li></ul><h2><strong>Xu Hướng Phối Lớp Ánh Sáng (Layering Light) Cho Phòng Ngủ Hiện Đại</strong></h2><p><img src=\"/uploads/products/gallery_6a1fd69bf30af6.10675255.jpg\"></p><p>Để phòng ngủ đạt chuẩn \"resort 5 sao\", <strong>Đèn Hoa Mỹ</strong> gợi ý bạn công thức phối 3 lớp ánh sáng hoàn hảo sau:</p><h3><strong>1. Ánh sáng tổng thể (Ambient Light) dịu nhẹ</strong></h3><p>Thay vì dùng đèn ốp trần thô kệch, hãy chọn một mẫu <strong>đèn trần LED hoa mỹ</strong> có thiết kế tối giản hoặc đèn mâm pha lê áp trần loại nhỏ. Lớp ánh sáng này nên là màu trung tính hoặc vàng ấm để bao phủ không gian một cách nhẹ nhàng.</p><h3><strong>2. Ánh sáng điểm nhấn (Accent Light) từ Đèn thả đầu giường</strong></h3><p>Đây đang là trend cực hot tại các căn hộ cao cấp và nhà phố Hải Phòng. Thay vì dùng đèn ngủ để bàn truyền thống chiếm diện tích, việc thả từ trần xuống 2 chiếc <strong>đèn thả hoa mỹ dáng dài</strong> ở hai bên đầu giường vừa tạo cảm giác thanh lịch, vừa làm bừng sáng góc riêng tư một cách nghệ thuật.</p><h3><strong>3. Ánh sáng chức năng (Task Light) thông minh</strong></h3><p>Sử dụng các dải đèn LED vát góc giấu trong khe tủ quần áo, hoặc đèn tường hoa mỹ có khớp xoay điều hướng tại khu vực bàn trang điểm, góc đọc sách để phục vụ các nhu cầu cá nhân mà không làm ảnh hưởng đến người bên cạnh.</p><h2><strong>Bí Quyết Chọn Đèn Trang Trí Phòng Ngủ Từ Chuyên Gia Ánh Sáng</strong></h2><p>Khi chọn mua đèn hoa mỹ cho phòng ngủ, các gia chủ Đất Cảng nên nằm lòng các lưu ý sau:</p><ul><li><strong>Ưu tiên đèn đổi màu (3 chế độ):</strong> Nên chọn loại đèn tích hợp chip LED đổi màu (Trắng - Trung tính - Vàng). Ban ngày cần dọn dẹp bật ánh sáng trắng; buổi tối cần thư giãn, lãng mạn thì chuyển sang ánh sáng vàng ấm áp.</li></ul><p><img src=\"/uploads/products/gallery_6a1fd7d2bbf8a1.07287592.png\"></p><ul><li><strong>Chất liệu thân thiện, không lóa mắt:</strong> Nên chọn chao đèn bằng thủy tinh dạng khói, vải dạ hoặc đá tự nhiên để ánh sáng đi qua được mềm mại, không bị chói trực diện vào mắt khi nằm trên giường.</li></ul><p><img src=\"/uploads/products/gallery_6a1fd8ee568f78.60374229.png\"></p><ul><li><strong>Kích thước vừa vặn:</strong> Tránh các mẫu đèn quá rườm rà, cồng kềnh tạo cảm giác đè nén, nặng nề khi ngủ.</li></ul><p><img src=\"/uploads/products/gallery_6a1fd90d33aa29.01343544.png\"></p><h2><strong>Đổi Mới Không Gian Phòng Ngủ Cùng Đèn Hoa Mỹ</strong></h2><p>Bạn muốn sở hữu một phòng ngủ ấm cúng, chuẩn gu và hợp phong thủy? Hãy để <strong>Đèn Hoa Mỹ</strong> giúp bạn hiện thực hóa điều đó. Chúng tôi mang đến hàng trăm mẫu đèn trang trí phòng ngủ, đèn thả đầu giường nghệ thuật với công nghệ LED tiết kiệm điện, an toàn cho sức khỏe.</p><ul><li>Khảo sát, tư vấn thiết kế ánh sáng phòng ngủ miễn phí tại Hải Phòng.</li><li>Cam kết sản phẩm tinh tế, độ bền cao, chip LED không nhấp nháy.</li></ul><p>Liên hệ ngay để nhận ưu đãi thiết kế không gian phòng cưới, phòng ngủ mùa cưới năm nay!</p><ul><li><strong>Showroom:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng</li><li><strong>Hotline/Zalo:</strong> 02256533618 - 0978897579</li><li><strong>Website:</strong> denhoamy.store</li></ul>', 1, 1, 2, '2026-06-03 07:34:41', '2026-06-03 11:29:23', NULL),
(8, '5 Sai Lầm Khi Mua Đèn Trang Trí Tại Hải Phòng Và Cách Khắc Phục', 'sai-lam-khi-mua-den-trang-tri-hai-phong', '/uploads/products/gallery_6a200f9d642a08.22024462.png', 'Tránh ngay 5 sai lầm phổ biến khi mua đèn trang trí tại Hải Phòng gây lãng phí tiền bạc. Bỏ túi kinh nghiệm chọn đèn hoa mỹ chuẩn đẹp và an toàn từ chuyên gia!', '<h2><strong><img src=\"/uploads/products/gallery_6a200fa65db6b7.78761415.png\">5 Sai Lầm Thường Gặp Khi Mua Đèn Trang Trí Tại Hải Phòng Và Cách Khắc Phục</strong></h2><p>Để hoàn thiện một ngôi nhà đẹp, hệ thống ánh sáng đóng vai trò quyết định đến 80% tính thẩm mỹ của không gian. Tuy nhiên, việc lựa chọn và lắp đặt đèn trang trí, đèn hoa mỹ chưa bao giờ là điều dễ dàng, đặc biệt là với những gia chủ lần đầu xây sửa nhà.</p><p>Thực tế tại Hải Phòng, rất nhiều khách hàng do chưa có kinh nghiệm đã gặp phải tình trạng \"tiền mất tật mang\", mua đèn về nhưng lắp lên không hợp hoặc nhanh hỏng. Dưới đây là <strong>5 sai lầm phổ biến nhất</strong> mà <strong>Đèn Hoa Mỹ</strong> đã tổng hợp, giúp bạn tránh lãng phí ngân sách và sở hữu không gian sống hoàn hảo nhất.</p><h3><strong>1. Chỉ Nhìn Hình Ảnh Trên Mạng Rồi Đặt Mua (Sai Lầm Về Kích Thước)</strong></h3><ul><li><strong>Thực trạng:</strong> Nhiều gia chủ lướt mạng thấy mẫu đèn chùm hoặc đèn thả quá lung linh liền chốt đơn ngay. Khi nhận hàng mới ngã ngửa vì đèn quá to làm phòng khách bị ngột ngạt, hoặc đèn quá nhỏ lọt thỏm giữa trần nhà bề thế.</li><li><strong>Giải pháp:</strong> Trước khi mua, bạn cần đo chính xác diện tích phòng và chiều cao trần (từ sàn đến trần thạch cao). Công thức vàng từ chuyên gia: Đường kính đèn chùm lý tưởng thường bằng <strong>1/5 đến 1/4</strong> chiều rộng của căn phòng.</li></ul><h3><strong>2. Chọn Đèn Không Ăn Nhập Với Phong Cách Kiến Trúc</strong></h3><ul><li><strong>Thực trạng:</strong> Nhà thiết kế theo phong cách Hiện đại, tối giản nhưng gia chủ lại rước về một bộ đèn chùm pha lê Tân cổ điển rườm rà, dát vàng bóng lộn. Sự \"lệch pha\" này khiến không gian tổng thể trở nên rối mắt và kém tinh tế.</li><li><strong>Giải pháp:</strong> Hãy định hình rõ phong cách nội thất ngay từ đầu. Nội thất Bắc Âu, Hiện đại hợp với đèn LED thả trần hình khối tối giản. Nội thất Đông Dương (Indochine) hay Cổ điển hợp với đèn thân đồng, gốm sứ hoặc thủy tinh mờ.</li></ul><h3><strong>3. Ham Rẻ Mua Đèn Không Rõ Nguồn Gốc (Hại Mắt, Nhanh Cháy)</strong></h3><ul><li><strong>Thực trạng:</strong> Thị trường đèn trang trí Hải Phòng hiện nay có rất nhiều phân khúc giá. Nhiều dòng đèn giá rẻ, trôi nổi sử dụng chip LED kém chất lượng. Hệ quả là đèn có hiện tượng nhấp nháy liên tục (gây mỏi mắt, cận thị), ánh sáng bị suy hao nhanh chóng và rất dễ chập cháy sau vài tháng sử dụng.</li><li><strong>Giải pháp:</strong> Ưu tiên chọn các sản phẩm đèn hoa mỹ sử dụng <strong>chip LED cao cấp</strong> (như Cree, Osram, Philips...). Đèn chất lượng cao sẽ cho ánh sáng mịn, độ hoàn màu (CRI) cao trên 80 giúp vật thể hiện lên chân thực và an toàn tuyệt đối cho mắt.</li></ul><h3><strong>4. Bỏ Qua Công Năng Và Nhiệt Độ Màu Của Ánh Sáng</strong></h3><ul><li><strong>Thực trạng:</strong> Lắp ánh sáng trắng buốt trong phòng ngủ tạo cảm giác lạnh lẽo, khó ngủ. Ngược lại, lắp ánh sáng vàng quá tối ở khu vực bàn bếp khiến việc nấu nướng, chuẩn bị thức ăn gặp khó khăn.</li><li><strong>Giải pháp:</strong> Phân bổ màu sắc ánh sáng theo đúng công năng:</li><li class=\"ql-indent-1\"><strong>Phòng khách/Phòng bếp:</strong> Ưu tiên ánh sáng trung tính (4000K) hoặc tích hợp đèn đổi màu để linh hoạt sử dụng.</li><li class=\"ql-indent-1\"><strong>Phòng ngủ/Phòng thư giãn:</strong> Sử dụng ánh sáng vàng ấm (2700K - 3000K) mang lại sự dễ chịu.</li></ul><h3><strong>5. Tự Ý Lắp Đặt Đèn Nặng Lên Trần Thạch Cao Kém Gia Cố</strong></h3><ul><li><strong>Thực trạng:</strong> Các dòng đèn chùm pha lê, đèn thả thông tầng bằng đồng có trọng lượng rất lớn (từ 10kg đến vài chục kg). Nhiều gia chủ tự mua về rồi thuê thợ điện nước thông thường lắp trực tiếp lên tấm thạch cao mà không gia cố khung xương sắt bên trong, tiềm ẩn nguy cơ sập trần cực kỳ nguy hiểm.</li><li><strong>Giải pháp:</strong> Với các dòng đèn hoa mỹ kích thước lớn, bắt buộc phải có đội ngũ kỹ thuật chuyên nghiệp khảo sát trần bê tông, khoan ty ren và gia cố cáp treo an toàn trước khi treo đèn.</li></ul><h2><strong>Mua Đèn Trang Trí Chuẩn Gu, An Tâm Tuyệt Đối Tại Đèn Hoa Mỹ</strong></h2><p><img src=\"/uploads/products/gallery_6a200e0f5fd926.88783516.jpeg\"></p><p>Thay vì phải tự mình \"đánh cược\" với những rủi ro trên, hãy để <strong>Đèn Hoa Mỹ</strong> đồng hành cùng công trình của bạn tại Hải Phòng. Chúng tôi không chỉ bán đèn, chúng tôi mang đến giải pháp chiếu sáng toàn diện:</p><ul><li><strong>Xem hàng thực tế:</strong> Showroom tại Hải Phòng trưng bày sẵn các mẫu đèn giúp khách hàng trải nghiệm thực tế chất liệu pha lê, đồng và màu sắc ánh sáng.</li><li><strong>Tư vấn từ Kiến trúc sư:</strong> Hỗ trợ tính toán công suất, kích thước đèn phù hợp với bản vẽ kỹ thuật của nhà bạn.</li><li><strong>Thi công trọn gói an toàn:</strong> Đội ngũ kỹ thuật viên tay nghề cao, chuyên trị các ca trần cao, trần thông tầng biệt thự, đảm bảo an toàn tuyệt đối.</li></ul><p>Đừng ngần ngại liên hệ ngay với chúng tôi để được tư vấn miễn phí tận công trình!</p><ul><li><strong>Showroom:</strong> 905 Nguyễn Văn Linh, An Biên, Hải Phòng</li><li><strong>Hotline/Zalo:</strong> 02256533618 - 0978897579</li><li><strong>Website:</strong> denhoamy.store</li></ul>', 1, 1, 0, '2026-06-03 11:29:04', '2026-06-03 11:29:04', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `orders`
--

CREATE TABLE `orders` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `customer_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_method` enum('home','store') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'home',
  `note` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `payment_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'cod',
  `total` decimal(15,0) DEFAULT '0',
  `coupon_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coupon_id` int DEFAULT NULL,
  `discount_amount` decimal(15,0) DEFAULT '0',
  `status` enum('pending','approved','shipping','completed','cancelled') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `processed_by` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `customer_name`, `phone`, `email`, `address`, `delivery_method`, `note`, `payment_method`, `total`, `coupon_code`, `coupon_id`, `discount_amount`, `status`, `processed_by`, `created_at`, `deleted_at`, `updated_at`) VALUES
(4, NULL, 'Đỗ Thắng', '0987452316', 'minhhieutran0609@gmail.com', '79 Hồng Bàng', 'home', '', 'bank_transfer', 900000, 'GIAIPHONGMIENNAM', NULL, 100000, 'completed', 1, '2026-04-10 04:53:45', NULL, '2026-05-28 04:13:47'),
(5, NULL, 'Đỗ Thắng', '0987452316', 'dothang@gmail.com', 'Tôn Đức Thắng - Hồng Bàng', 'home', 'Giao vao gio hanh chinh', 'bank_transfer', 13318200, 'GIAIPHONGMIENNAM', NULL, 1479800, 'completed', 1, '2026-04-10 14:50:46', NULL, '2026-05-29 14:54:38'),
(6, NULL, 'Đỗ Thắng', '0987452316', 'dothang@denhoamy.com', '22 Hồng Bàng', 'home', '', 'bank_transfer', 1080000, 'GIAIPHONGMIENNAM', NULL, 120000, 'completed', 1, '2026-04-19 06:43:45', NULL, '2026-05-29 14:54:38'),
(7, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', '22 An Lạc', 'home', '', 'bank_transfer', 2682000, 'GIAIPHONGMIENNAM', NULL, 298000, 'cancelled', 1, '2026-05-04 11:30:28', NULL, '2026-05-28 04:13:47'),
(8, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', '22 An Lạc', 'home', '', 'bank_transfer', 1500000, NULL, NULL, 0, 'cancelled', NULL, '2026-05-04 11:37:52', NULL, '2026-05-28 04:14:18'),
(9, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', '79 An Lạc', 'home', '', 'bank_transfer', 3560000, NULL, NULL, 0, 'cancelled', NULL, '2026-05-05 15:51:32', NULL, '2026-05-28 04:14:18'),
(10, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', '123 Le Loi, Hai Phong', 'home', '', 'cod', 890000, NULL, NULL, 0, 'cancelled', NULL, '2026-05-22 11:16:51', NULL, '2026-05-28 04:14:18'),
(12, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', '79 An Lạc', 'home', '', 'payos', 890000, NULL, NULL, 0, 'cancelled', NULL, '2026-05-24 01:37:35', NULL, '2026-05-28 04:14:19'),
(13, 1, 'Trần Minh Hiếu', '0987452316', 'hieu.it@denhoamy.com', 'Nhận hàng tại cửa hàng: 905 Nguyễn Văn Linh, An Biên, Hải Phòng', 'home', '', 'payos', 899000, NULL, NULL, 0, 'completed', 1, '2026-05-25 14:25:32', NULL, '2026-05-28 04:15:38'),
(14, 1, 'Đỗ Tiến Thắng', '0987452316', 'user_Thang983@yahoo.com', 'Tôn đức thắng', 'home', '', 'cod', 950000, 'FLASHSALE', NULL, 100000, 'shipping', 1, '2026-05-31 12:16:42', NULL, '2026-05-31 12:17:22'),
(15, 2, 'Trần Minh Hiếu', '0866830716', 'minhhieutran0609@gmail.com', '79 An Lạc, Hồng Bàng, Hải Phòng', 'home', '', 'cod', 1200000, 'FLASHSALE', NULL, 100000, 'cancelled', 1, '2026-05-31 13:05:31', NULL, '2026-05-31 13:56:54'),
(16, 2, 'Trần Minh Hiếu', '0866830716', 'minhhieutran0609@gmail.com', 'Nhận hàng tại cửa hàng: 905 Nguyễn Văn Linh, An Biên, Hải Phòng', 'store', '', 'pay_at_store', 1100000, 'FLASHSALE', NULL, 100000, 'approved', 1, '2026-05-31 14:26:48', NULL, '2026-06-02 05:01:31'),
(17, 1, 'Trần Minh Hiếu', '0978897579', 'hieu.it@denhoamy.com', 'Nhận hàng tại cửa hàng: 905 Nguyễn Văn Linh, An Biên, Hải Phòng', 'store', '', 'pay_at_store', 3360000, 'FLASHSALE', NULL, 100000, 'pending', NULL, '2026-06-02 05:03:23', NULL, '2026-06-02 05:03:23'),
(18, 2, 'Trần Minh Hiếu', '0866830716', 'minhhieutran0609@gmail.com', '88 Tôn Đức Thắng', 'home', '', 'cod', 1100000, 'FLASHSALE', NULL, 100000, 'pending', NULL, '2026-06-02 06:08:36', NULL, '2026-06-02 06:08:36'),
(19, 2, 'Trần Minh Hiếu', '0866830716', 'minhhieutran0609@gmail.com', 'Nhận hàng tại cửa hàng: 905 Nguyễn Văn Linh, An Biên, Hải Phòng', 'store', '', 'payos', 1000000, 'FLASHSALE', NULL, 100000, 'pending', NULL, '2026-06-02 06:09:52', NULL, '2026-06-02 06:09:52');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `order_items`
--

CREATE TABLE `order_items` (
  `id` int NOT NULL,
  `order_id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `variant_id` int DEFAULT NULL,
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` int DEFAULT '1',
  `price` decimal(15,0) DEFAULT '0',
  `cost_price` decimal(15,2) DEFAULT '0.00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `variant_id`, `product_name`, `quantity`, `price`, `cost_price`) VALUES
(4, 4, 121, 163, 'Đèn ốp trần đồng DO00636 - [30 x 70 - Vàng Trắng]', 1, 1000000, 550000.00),
(5, 5, 83, 27, 'Đèn chùm hợp kim DC04244 - [35 x 80 - Trắng]', 2, 899000, 799000.00),
(6, 5, 76, NULL, 'Đèn chùm đồng DC04042', 1, 13000000, 0.00),
(7, 6, 90, 63, 'Đèn chùm đồng DC03759 - [40x60 - Vàng Trắng]', 1, 1200000, 890000.00),
(8, 7, 136, NULL, 'Đèn quạt hợp kim DQ00780', 1, 990000, 0.00),
(9, 7, 136, 210, 'Đèn quạt hợp kim DQ00780 - [110x45 - Vàng Trắng]', 1, 990000, 820000.00),
(10, 7, 102, NULL, 'Đèn bàn đồng DB01956', 1, 1000000, 0.00),
(11, 8, 101, NULL, 'Đèn thả đồng DT03279', 1, 1500000, 0.00),
(12, 9, 137, 214, 'Đèn quạt hợp kim DQ00752 - [107x45 - Vàng Trắng]', 4, 890000, 0.00),
(13, 10, 137, 218, 'Đèn quạt hợp kim DQ00752 - [107x45 - Vàng Trắng]', 1, 890000, 699000.00),
(15, 12, 137, 218, 'Đèn quạt hợp kim DQ00752 - [107x45 - Vàng Trắng]', 1, 890000, 699000.00),
(16, 13, 85, 39, 'Đèn chùm hợp kim DC04200 - [70 x 80 - Vàng]', 1, 899000, 799000.00),
(17, 14, 100, 97, 'Đèn thả đồng DT03143 - [30x40 - Vàng Trắng]', 1, 1050000, 790000.00),
(18, 15, 109, 125, 'Đèn bàn đồng DB02258 - [18x35 - Vàng Trắng]', 1, 1300000, 990000.00),
(19, 16, 87, 47, 'Đèn chùm đồng DC03935 - [40 x 60 - Vàng Trắng]', 1, 1200000, 899000.00),
(20, 17, 122, NULL, 'Đèn ốp trần đồng DO00634', 1, 960000, 450000.00),
(21, 17, 96, NULL, 'Đèn thả đồng DT03294', 1, 1250000, 850000.00),
(22, 17, 114, NULL, 'Đèn bàn đồng DB01174', 1, 1250000, 920000.00),
(23, 18, 133, 202, 'Đèn quạt đồng DQ00387 - [100x40 - Vàng Trắng]', 1, 1200000, 890000.00),
(24, 19, 98, 89, 'Đèn thả đồng DT03228 - [25x35 - Vàng Trắng ]', 1, 1100000, 750000.00);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `token_hash` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `password_reset_tokens`
--

INSERT INTO `password_reset_tokens` (`id`, `user_id`, `token_hash`, `expires_at`, `used_at`, `created_at`) VALUES
(1, 1, '3982b20671f143ace4f6299129d7b6016951e03432283e89e46a6b2e3d14bbc9', '2026-05-24 14:48:27', NULL, '2026-05-24 14:18:27'),
(2, 2, 'd9b0643e291dacb84d49530f3d2a22e2dc4160e5a37e03c519440b3189b1dbd5', '2026-05-25 01:52:23', '2026-05-25 01:22:53', '2026-05-25 01:22:23'),
(3, 2, '16448a4c66640ec9eb20f81c6792776685f9c29f804da09b15a8d3765a654b93', '2026-06-02 06:43:53', NULL, '2026-06-02 06:13:53');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `payments`
--

CREATE TABLE `payments` (
  `id` int NOT NULL,
  `order_id` int NOT NULL,
  `payment_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(15,0) NOT NULL,
  `method` enum('cod','bank_transfer','momo','vnpay','payos','pay_at_store') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'cod',
  `status` enum('pending','completed','failed','refunded') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `evidence_url` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `payments`
--

INSERT INTO `payments` (`id`, `order_id`, `payment_code`, `amount`, `method`, `status`, `evidence_url`, `created_at`) VALUES
(1, 4, NULL, 900000, 'bank_transfer', 'pending', NULL, '2026-04-10 04:53:45'),
(2, 5, NULL, 13318200, 'bank_transfer', 'pending', NULL, '2026-04-10 14:50:46'),
(3, 6, NULL, 1080000, 'bank_transfer', 'pending', NULL, '2026-04-19 06:43:45'),
(4, 7, NULL, 2682000, 'bank_transfer', 'pending', NULL, '2026-05-04 11:30:28'),
(5, 8, NULL, 1500000, 'bank_transfer', 'pending', NULL, '2026-05-04 11:37:52'),
(6, 9, NULL, 3560000, 'bank_transfer', 'pending', NULL, '2026-05-05 15:51:32'),
(7, 10, NULL, 890000, 'cod', 'pending', NULL, '2026-05-22 11:16:51'),
(8, 12, NULL, 890000, 'payos', 'pending', NULL, '2026-05-24 01:37:35'),
(9, 13, NULL, 899000, 'payos', 'pending', NULL, '2026-05-25 14:25:32'),
(10, 14, NULL, 950000, 'cod', 'pending', NULL, '2026-05-31 12:16:42'),
(11, 15, NULL, 1200000, 'cod', 'pending', NULL, '2026-05-31 13:05:31'),
(12, 16, NULL, 1100000, 'pay_at_store', 'pending', NULL, '2026-05-31 14:26:48'),
(13, 17, NULL, 3360000, 'pay_at_store', 'pending', NULL, '2026-06-02 05:03:23'),
(14, 18, NULL, 1100000, 'cod', 'pending', NULL, '2026-06-02 06:08:36'),
(15, 19, NULL, 1000000, 'payos', 'pending', NULL, '2026-06-02 06:09:52');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `products`
--

CREATE TABLE `products` (
  `id` int NOT NULL,
  `category_id` int DEFAULT NULL,
  `ten_san_pham` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ma_san_pham` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `loai_den` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `price` decimal(15,2) NOT NULL,
  `cost_price` decimal(15,0) DEFAULT '0',
  `old_price` decimal(15,2) DEFAULT '0.00',
  `is_hot_deal` tinyint(1) NOT NULL DEFAULT '0',
  `stock` int DEFAULT '15',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `image_url` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `gallery` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `products`
--

INSERT INTO `products` (`id`, `category_id`, `ten_san_pham`, `ma_san_pham`, `loai_den`, `price`, `cost_price`, `old_price`, `is_hot_deal`, `stock`, `description`, `image_url`, `gallery`, `created_at`, `deleted_at`) VALUES
(76, NULL, 'Đèn chùm đồng DC04042', 'DC04042', 'Đèn Chùm Cổ Điển', 10000000.00, 7999000, 0.00, 0, 30, '', '/uploads/products/product_69d71c30213985.26567730.jpg', '[\"\\/uploads\\/products\\/gallery_69d71c3581fb23.57905349.jpg\",\"\\/uploads\\/products\\/gallery_69d71c35778205.90595727.jpg\"]', '2026-04-09 03:28:36', NULL),
(77, NULL, 'Đèn chùm đồng DY01160', 'DY01160', 'Đèn Chùm Cổ Điển', 9000000.00, 6800000, 0.00, 0, 4, '', '/uploads/products/product_69d720778aaee0.70816890.jpg', '[\"\\/uploads\\/products\\/gallery_69d7207a48d139.69865229.jpg\",\"\\/uploads\\/products\\/gallery_69d7207a48d6d4.38182450.jpg\"]', '2026-04-09 03:45:08', NULL),
(78, NULL, 'Đèn chùm đồng DC03153', 'DC03153', 'Đèn Chùm Cổ Điển', 6000000.00, 4500000, 0.00, 0, 8, '', '/uploads/products/product_69d720d7ef4920.00500017.jpg', '[\"\\/uploads\\/products\\/gallery_69d720da2e0731.51530153.jpg\"]', '2026-04-09 03:47:41', NULL),
(79, NULL, 'Đèn chùm đồng DC02977', 'DC02977', 'Đèn Chùm Cổ Điển', 5000000.00, 4500000, 0.00, 0, 4, '', '/uploads/products/product_69d722ac8cd8c4.33165156.jpg', '[\"\\/uploads\\/products\\/gallery_69d722aea9a4f3.19936120.jpg\"]', '2026-04-09 03:54:57', NULL),
(80, NULL, 'Đèn chùm đồng DC03111', 'DC03111', 'Đèn Chùm Cổ Điển', 5000000.00, 4800000, 0.00, 0, 4, '', '/uploads/products/product_69d788315e14f2.71253668.jpg', '[\"\\/uploads\\/products\\/gallery_69d788339040a1.16281735.jpg\"]', '2026-04-09 11:06:28', NULL),
(81, NULL, 'Đèn chùm hợp kim DC04290', 'DC04290', 'Đèn Chùm Hiện Đại', 899000.00, 699000, 0.00, 0, 8, '', '/uploads/products/product_69d789bead9666.96179277.jpg', '[]', '2026-04-09 11:13:04', NULL),
(82, NULL, 'Đèn chùm hợp kim DC04249', 'DC04249', 'Đèn Chùm Hiện Đại', 799000.00, 699000, 0.00, 0, 8, '', '/uploads/products/product_69d78a48ae76c0.95764478.jpg', '[\"\\/uploads\\/products\\/gallery_69d78a4bee8618.83088258.jpg\",\"\\/uploads\\/products\\/gallery_69d78a4be48d15.88816358.jpg\"]', '2026-04-09 11:15:29', NULL),
(83, NULL, 'Đèn chùm hợp kim DC04244', 'DC04244', 'Đèn Chùm Hiện Đại', 899000.00, 799000, 0.00, 0, 6, '', '/uploads/products/product_69d78ae8341139.34642308.jpg', '[\"\\/uploads\\/products\\/gallery_69d78aeabc7a57.83793796.jpg\",\"\\/uploads\\/products\\/gallery_69d78aeab310c6.07049535.jpg\"]', '2026-04-09 11:18:04', NULL),
(84, NULL, 'Đèn chùm hợp kim DC04168', 'DC04168', 'Đèn Chùm Hiện Đại', 699000.00, 599000, 0.00, 0, 8, '', '/uploads/products/product_69d78b8b4651f3.52531662.jpg', '[\"\\/uploads\\/products\\/gallery_69d78b8d8fa4b8.79090630.jpg\"]', '2026-04-09 11:20:29', NULL),
(85, NULL, 'Đèn chùm hợp kim DC04200', 'DC04200', 'Đèn Chùm Hiện Đại', 899000.00, 799000, 0.00, 0, 8, '', '/uploads/products/product_69d78c153c8441.60281145.jpg', '[\"\\/uploads\\/products\\/gallery_69d78c17664421.60404299.jpg\"]', '2026-04-09 11:23:08', NULL),
(86, NULL, 'Đèn chùm đồng DC04307', 'DC04307', 'Đèn Chùm Tân Cổ Điển', 1500000.00, 989000, 0.00, 0, 8, '', '/uploads/products/product_69d78cb2f38444.71839975.jpg', '[\"\\/uploads\\/products\\/gallery_69d78cb5960f30.01158316.jpg\",\"\\/uploads\\/products\\/gallery_69d78cb58ca5b4.38915139.jpg\"]', '2026-04-09 11:25:43', NULL),
(87, NULL, 'Đèn chùm đồng DC03935', 'DC03935', 'Đèn Chùm Tân Cổ Điển', 1200000.00, 899000, 0.00, 0, 7, '', '/uploads/products/product_69d78d55346096.56193541.jpg', '[\"\\/uploads\\/products\\/gallery_69d78d586f36e4.34037836.jpg\",\"\\/uploads\\/products\\/gallery_69d78d586227c7.79929363.jpg\"]', '2026-04-09 11:28:27', NULL),
(88, NULL, 'Đèn chùm đồng DC03934', 'DC03934', 'Đèn Chùm Tân Cổ Điển', 900000.00, 855000, 0.00, 0, 8, '', '/uploads/products/product_69d78dbd88b158.62130059.jpg', '[\"\\/uploads\\/products\\/gallery_69d78dbf9ef104.21693810.jpg\"]', '2026-04-09 11:29:57', NULL),
(89, NULL, 'Đèn chùm đồng DC03882', 'DC03882', 'Đèn Chùm Tân Cổ Điển', 1100000.00, 950000, 0.00, 0, 8, '', '/uploads/products/product_69d78e3ec716d5.27089904.jpg', '[\"\\/uploads\\/products\\/gallery_69d78e411f01d5.63001302.jpg\",\"\\/uploads\\/products\\/gallery_69d78e4115b6e6.72190854.jpg\"]', '2026-04-09 11:32:20', NULL),
(90, NULL, 'Đèn chùm đồng DC03759', 'DC03759', 'Đèn Chùm Tân Cổ Điển', 1200000.00, 890000, 0.00, 0, 7, '', '/uploads/products/product_69d78eb82714c4.04398082.jpg', '[\"\\/uploads\\/products\\/gallery_69d78ebabaf885.36423087.jpg\",\"\\/uploads\\/products\\/gallery_69d78ebab13c86.03455424.jpg\"]', '2026-04-09 11:34:20', NULL),
(91, NULL, 'Đèn thả đồng DT02193', 'DT02193', 'Đèn Thả Cổ Điển', 1000000.00, 550000, 0.00, 0, 4, '', '/uploads/products/product_69d78fa6da22a8.74732097.jpg', '[\"\\/uploads\\/products\\/gallery_69d78fab5c2fd6.48744760.jpg\",\"\\/uploads\\/products\\/gallery_69d78fab518ca1.61908250.jpg\"]', '2026-04-09 11:38:24', NULL),
(92, NULL, 'Đèn thả đồng DT01951', 'DT01951', 'Đèn Thả Cổ Điển', 960000.00, 450000, 0.00, 0, 4, '', '/uploads/products/product_69d7900794dc42.60895894.jpg', '[\"\\/uploads\\/products\\/gallery_69d7900998e803.93927355.jpg\"]', '2026-04-09 11:39:54', NULL),
(93, NULL, 'Đèn thả đồng DT01375', 'DT01375', 'Đèn Thả Cổ Điển', 860000.00, 530000, 0.00, 0, 8, '', '/uploads/products/product_69d7904fb34af0.70778604.jpg', '[\"\\/uploads\\/products\\/gallery_69d7905259afa9.93375519.jpg\",\"\\/uploads\\/products\\/gallery_69d790524f54b6.99049591.jpg\"]', '2026-04-09 11:41:49', NULL),
(94, NULL, 'Đèn thả đồng DT01193', 'DT01193', 'Đèn Thả Cổ Điển', 960000.00, 780000, 0.00, 0, 8, '', '/uploads/products/product_69d790dd017b52.97869071.jpg', '[\"\\/uploads\\/products\\/gallery_69d790df7610e3.52046612.jpg\",\"\\/uploads\\/products\\/gallery_69d790df6d1b73.74697123.jpg\"]', '2026-04-09 11:43:29', NULL),
(95, NULL, 'Đèn thả đồng DT01138', 'DT01138', 'Đèn Thả Cổ Điển', 1200000.00, 970000, 0.00, 0, 4, '', '/uploads/products/product_69d79130066976.20559681.jpg', '[\"\\/uploads\\/products\\/gallery_69d79133248c57.00259426.jpg\",\"\\/uploads\\/products\\/gallery_69d791331c44c5.58744768.jpg\",\"\\/uploads\\/products\\/gallery_69d791331ab1b5.49230867.jpg\"]', '2026-04-09 11:44:56', NULL),
(96, NULL, 'Đèn thả đồng DT03294', 'DT03294', 'Đèn Thả Hiện Đại', 1250000.00, 850000, 0.00, 0, 8, '', '/uploads/products/product_69d794d863e633.73494060.jpg', '[\"\\/uploads\\/products\\/gallery_69d794db39bec6.13468292.jpg\",\"\\/uploads\\/products\\/gallery_69d794db3065a9.29469814.jpg\"]', '2026-04-09 12:00:33', NULL),
(97, NULL, 'Đèn thả đồng DT03295', 'DT03295', 'Đèn Thả Hiện Đại', 1180000.00, 890000, 0.00, 0, 8, '', '/uploads/products/product_69d795551fa860.05204176.jpg', '[\"\\/uploads\\/products\\/gallery_69d79557795d32.40006096.jpg\"]', '2026-04-09 12:02:34', NULL),
(98, NULL, 'Đèn thả đồng DT03228', 'DT03228', 'Đèn Thả Hiện Đại', 1100000.00, 750000, 0.00, 0, 7, '', '/uploads/products/product_69d795fe6e8746.93963512.jpg', '[\"\\/uploads\\/products\\/gallery_69d79600b40789.70300699.jpg\"]', '2026-04-09 12:05:22', NULL),
(99, NULL, 'Đèn thả đồng DT03220', 'DT03220', 'Đèn Thả Hiện Đại', 1300000.00, 980000, 0.00, 0, 8, '', '/uploads/products/product_69d796707df876.60552306.jpg', '[\"\\/uploads\\/products\\/gallery_69d796729bab22.84731919.jpg\"]', '2026-04-09 12:07:15', NULL),
(100, NULL, 'Đèn thả đồng DT03143', 'DT03143', 'Đèn Thả Hiện Đại', 1050000.00, 790000, 0.00, 0, 7, '', '/uploads/products/product_69d796d874bb71.11113221.jpg', '[\"\\/uploads\\/products\\/gallery_69d796dab3d7d6.61624110.jpg\"]', '2026-04-09 12:09:03', NULL),
(101, NULL, 'Đèn thả đồng DT03279', 'DT03279', 'Đèn Thả Tân Cổ Điển', 1500000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d797edf2d840.13464742.jpg', '[]', '2026-04-09 12:13:38', NULL),
(102, NULL, 'Đèn bàn đồng DB01956', 'DB01956', 'Đèn Bàn Cổ Điển', 1000000.00, 0, 0.00, 0, 4, '', '/uploads/products/product_69d7a795558568.35687163.jpg', '[\"\\/uploads\\/products\\/gallery_69d7a79890e113.01302241.jpg\",\"\\/uploads\\/products\\/gallery_69d7a79887ee74.94337730.jpg\",\"\\/uploads\\/products\\/gallery_69d7a79887e6c2.43579748.jpg\"]', '2026-04-09 13:20:43', NULL),
(103, NULL, 'Đèn bàn đồng DB01929', 'DB01929', 'Đèn Bàn Cổ Điển', 960000.00, 0, 0.00, 0, 2, '', '/uploads/products/product_69d7a8180b6670.61903178.jpg', '[\"\\/uploads\\/products\\/gallery_69d7a81a3f7542.91943895.jpg\",\"\\/uploads\\/products\\/gallery_69d7a81a35ee60.00215874.jpg\"]', '2026-04-09 13:22:57', NULL),
(104, NULL, 'Đèn bàn đồng DB01648', 'DB01648', 'Đèn Bàn Cổ Điển', 860000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7a969f068c2.56432460.jpg', '[\"\\/uploads\\/products\\/gallery_69d7a96cb5c248.73402564.jpg\"]', '2026-04-09 13:28:15', NULL),
(105, NULL, 'Đèn bàn đồng DB01640', 'DB01640', 'Đèn Bàn Cổ Điển', 960000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7a9d09850a9.73887463.jpg', '[\"\\/uploads\\/products\\/gallery_69d7a9d37203f3.84309175.jpg\",\"\\/uploads\\/products\\/gallery_69d7a9d367e745.29795517.jpg\"]', '2026-04-09 13:29:58', NULL),
(106, NULL, 'Đèn bàn đồng DB01534', 'DB01534', 'Đèn Bàn Cổ Điển', 1200000.00, 0, 0.00, 0, 2, '', '/uploads/products/product_69d7aa0e4f9cf8.03780850.jpg', '[\"\\/uploads\\/products\\/gallery_69d7aa10a734d0.16824513.jpg\"]', '2026-04-09 13:30:59', NULL),
(107, NULL, 'Đèn bàn đồng DB02267', 'DB02267', 'Đèn Bàn Hiện Đại', 1250000.00, 880000, 0.00, 0, 8, '', '/uploads/products/product_69d7aa9ab59de1.46762185.jpg', '[\"\\/uploads\\/products\\/gallery_69d7aa9d0f65d3.16220317.jpg\"]', '2026-04-09 13:33:20', NULL),
(108, NULL, 'Đèn bàn đồng DB02271', 'DB02271', 'Đèn Bàn Hiện Đại', 1180000.00, 850000, 0.00, 0, 8, '', '/uploads/products/product_69d7ab05a968e8.68091176.jpg', '[]', '2026-04-09 13:35:06', NULL),
(109, NULL, 'Đèn bàn đồng DB02258', 'DB02258', 'Đèn Bàn Hiện Đại', 1300000.00, 990000, 0.00, 0, 8, '', '/uploads/products/product_69d7abd547e249.72503748.jpg', '[\"\\/uploads\\/products\\/gallery_69d7abd769a3f6.60671050.jpg\"]', '2026-04-09 13:38:32', NULL),
(110, NULL, 'Đèn bàn đồng DB02257', 'DB02257', 'Đèn Bàn Hiện Đại', 1100000.00, 799000, 0.00, 0, 8, '', '/uploads/products/product_69d7ac38444eb1.79148817.jpg', '[]', '2026-04-09 13:40:09', NULL),
(111, NULL, 'Đèn bàn đồng DB02253', 'DB02253', 'Đèn Bàn Hiện Đại', 1350000.00, 999000, 0.00, 0, 8, '', '/uploads/products/product_69d7ac9b6702f6.57955252.jpg', '[\"\\/uploads\\/products\\/gallery_69d7ac9db4f3c6.95923441.jpg\"]', '2026-04-09 13:41:50', NULL),
(112, NULL, 'Đèn bàn đồng DB02147', 'DB02147', 'Đèn Bàn Tân Cổ Điển', 1200000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7ad5a80ba89.61132575.jpg', '[\"\\/uploads\\/products\\/gallery_69d7ad5cc235c8.85656072.jpg\"]', '2026-04-09 13:45:03', NULL),
(113, NULL, 'Đèn bàn đồng DB01957', 'DB01957', 'Đèn Bàn Tân Cổ Điển', 1150000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7adb99efa83.45064335.jpg', '[\"\\/uploads\\/products\\/gallery_69d7adbc03af55.18784849.jpg\",\"\\/uploads\\/products\\/gallery_69d7adbbee2671.92799294.jpg\"]', '2026-04-09 13:46:38', NULL),
(114, NULL, 'Đèn bàn đồng DB01174', 'DB01174', 'Đèn Bàn Tân Cổ Điển', 1250000.00, 0, 0.00, 0, 7, '', '/uploads/products/product_69d7ae487c0136.16279357.jpg', '[\"\\/uploads\\/products\\/gallery_69d7ae49c39417.49766475.jpg\"]', '2026-04-09 13:49:03', NULL),
(115, NULL, 'Đèn bàn đồng DB01193', 'DB01193', 'Đèn Bàn Tân Cổ Điển', 1100000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7aebf011e60.70173031.jpg', '[\"\\/uploads\\/products\\/gallery_69d7aec1786b43.19726884.jpg\",\"\\/uploads\\/products\\/gallery_69d7aec16f2576.73448004.jpg\"]', '2026-04-09 13:51:03', NULL),
(120, NULL, 'Đèn bàn đồng DB01635', 'DB01635', 'Đèn Bàn Tân Cổ Điển', 6800000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69d7b2e32c10e7.19917577.jpg', '[\"\\/uploads\\/products\\/gallery_69d7b2e825d040.11235542.jpg\"]', '2026-04-09 14:08:41', NULL),
(121, NULL, 'Đèn ốp trần đồng DO00636', 'DO00636', 'Đèn Ốp Trần Cổ Điển', 1000000.00, 0, 2000000.00, 0, 4, 'Okokàipahwipfhwafhawiphf', '/uploads/products/product_69d7cc02858f09.49504904.jpg', '[\"\\/uploads\\/products\\/gallery_69d7cc04e60ab1.96969647.jpg\",\"\\/uploads\\/products\\/gallery_69d7cc06e606e4.38165142.jpg\"]', '2026-04-09 15:55:56', NULL),
(122, NULL, 'Đèn ốp trần đồng DO00634', 'DO00634', 'Đèn Ốp Trần Cổ Điển', 960000.00, 0, 0.00, 0, 3, '', '/uploads/products/product_69df6a9615d582.69794346.jpg', '[\"\\/uploads\\/products\\/gallery_69df6a985baf01.24928883.jpg\",\"\\/uploads\\/products\\/gallery_69df6a985bb416.39151012.jpg\"]', '2026-04-15 10:39:53', NULL),
(123, NULL, 'Đèn ốp trần đồng DO00586', 'DO00586', 'Đèn Ốp Trần Cổ Điển', 860000.00, 0, 0.00, 0, 4, '', '/uploads/products/product_69df6b1a8491d7.79070641.jpg', '[\"\\/uploads\\/products\\/gallery_69df6b1ca1c1e1.64687563.jpg\"]', '2026-04-15 10:41:41', NULL),
(124, NULL, 'Đèn ốp trần đồng DO00585', 'DO00585', 'Đèn Ốp Trần Cổ Điển', 960000.00, 0, 0.00, 0, 2, '', '/uploads/products/product_69df6b77502233.11229783.jpg', '[\"\\/uploads\\/products\\/gallery_69df6b79405597.90935187.jpg\"]', '2026-04-15 10:43:04', NULL),
(125, NULL, 'Đèn ốp trần đồng DO00560', 'DO00560', 'Đèn Ốp Trần Cổ Điển', 1200000.00, 0, 0.00, 0, 4, '', '/uploads/products/product_69df6bce228af6.04923606.jpg', '[\"\\/uploads\\/products\\/gallery_69df6bd086d6b5.16714122.jpg\",\"\\/uploads\\/products\\/gallery_69df6bd07cb031.32017001.jpg\"]', '2026-04-15 10:44:10', NULL),
(126, NULL, 'Đèn ốp trần DO01314', 'DO01314', 'Đèn Ốp Trần Tân Cổ Điển', 1200000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df6ca842cf44.83108018.jpg', '[\"\\/uploads\\/products\\/gallery_69df6caa754771.62870968.jpg\",\"\\/uploads\\/products\\/gallery_69df6caa6af858.06682242.jpg\"]', '2026-04-15 10:48:30', NULL),
(127, NULL, 'Đèn ốp trần DO00838', 'DO00838', 'Đèn Ốp Trần Tân Cổ Điển', 5500000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df6d16f37269.07124241.jpg', '[]', '2026-04-15 10:49:55', NULL),
(128, NULL, 'Đèn ốp trần DO00835', 'DO00835', 'Đèn Ốp Trần Tân Cổ Điển', 5500000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df6dab1baf89.65423933.jpg', '[]', '2026-04-15 10:51:24', NULL),
(130, NULL, 'Đèn ốp trần DO00836', 'DO00836', 'Đèn Ốp Trần Tân Cổ Điển', 12000000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df6e38a617c1.08712153.jpg', '[]', '2026-04-15 10:54:44', NULL),
(132, NULL, 'Đèn ốp trần DO00837', 'DO00837', 'Đèn Ốp Trần Tân Cổ Điển', 6500000.00, 0, 0.00, 0, 4, '', '/uploads/products/product_69df6f1f6de6b0.31683089.jpg', '[\"\\/uploads\\/products\\/gallery_69df6f219a8cd3.02274615.jpg\",\"\\/uploads\\/products\\/gallery_69df6f219a9250.72864206.jpg\"]', '2026-04-15 10:58:13', NULL),
(133, NULL, 'Đèn quạt đồng DQ00387', 'DQ00387', 'Đèn Quạt Tân Cổ Điển', 1200000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df703cd7a6b5.41555765.jpg', '[\"\\/uploads\\/products\\/gallery_69df703f85b576.87842549.jpg\",\"\\/uploads\\/products\\/gallery_69df703f7ba2b1.32113295.jpg\"]', '2026-04-15 11:03:37', NULL),
(134, NULL, 'Đèn quạt hợp kim DQ00964', 'DQ00964', 'Đèn Quạt Tân Cổ Điển', 950000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df70a2e07210.96262557.jpg', '[\"\\/uploads\\/products\\/gallery_69df70a4e22685.34309194.jpg\"]', '2026-04-15 11:05:03', NULL),
(135, NULL, 'Đèn quạt hợp kim DQ00771', 'DQ00771', 'Đèn Quạt Tân Cổ Điển', 850000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df7147838564.88552765.jpg', '[\"\\/uploads\\/products\\/gallery_69df71498061d1.81623285.jpg\"]', '2026-04-15 11:06:51', NULL),
(136, NULL, 'Đèn quạt hợp kim DQ00780', 'DQ00780', 'Đèn Quạt Tân Cổ Điển', 990000.00, 0, 0.00, 0, 8, '', '/uploads/products/product_69df719ea301e6.39665545.jpg', '[\"\\/uploads\\/products\\/gallery_69df71a0a90109.67402435.jpg\"]', '2026-04-15 11:08:18', NULL),
(137, NULL, 'Đèn quạt hợp kim DQ00752', 'DQ00752', 'Đèn Quạt Tân Cổ Điển', 890000.00, 699000, 908700.00, 0, 6, '', '/uploads/products/product_69df71f5ef3491.65287541.jpg', '[\"\\/uploads\\/products\\/gallery_69df71fb3affe9.14640701.jpg\"]', '2026-04-15 11:09:48', NULL),
(138, NULL, 'Đèn chùm đồng DC03110', 'DC03110', 'Đèn Chùm Cổ Điển', 6500000.00, 5750000, 7500000.00, 0, 4, '', '/uploads/products/product_6a156b37b7a193.21413390.jpg', '[\"\\/uploads\\/products\\/gallery_6a156b39e09df3.48885774.jpg\"]', '2026-05-26 09:45:16', NULL),
(139, NULL, 'Đèn chùm đồng DC03109', 'DC03109', 'Đèn Chùm Cổ Điển', 6000000.00, 4500000, 6000000.00, 0, 4, '', '/uploads/products/product_6a1fa1937d5f94.21325708.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa195c59bf3.84355748.jpg\"]', '2026-06-03 03:39:16', NULL),
(140, NULL, 'Đèn chùm đồng DC03108', 'DC03108', 'Đèn Chùm Cổ Điển', 8000000.00, 7500000, 8000000.00, 0, 8, '', '/uploads/products/product_6a1fa1f0bbef83.83174679.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa1f2cd6840.44951128.jpg\"]', '2026-06-03 03:40:54', NULL),
(141, NULL, 'Đèn chùm đồng DC02859', 'DC02859', 'Đèn Chùm Cổ Điển', 8000000.00, 6999000, 8000000.00, 0, 4, '', '/uploads/products/product_6a1fa313274728.69747552.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa31518cbb3.09766780.jpg\"]', '2026-06-03 03:42:19', NULL),
(142, NULL, '', 'SP1780458209426', '', 5000000.00, 4500000, 5000000.00, 0, 4, '', '/uploads/products/product_6a1fa2a8a4fbc8.79859339.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa2aaed7698.98366744.jpg\"]', '2026-06-03 03:43:28', NULL),
(143, NULL, 'Đèn chùm đồng DC02857', 'DC02857', 'Đèn Chùm Cổ Điển', 5000000.00, 4500000, 5000000.00, 0, 4, '', '/uploads/products/product_6a1fa3362f14b8.92249045.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa33865c869.99187786.jpg\"]', '2026-06-03 03:45:46', NULL),
(144, NULL, 'Đèn chùm đồng DC01641', 'DC01641', 'Đèn Chùm Cổ Điển', 1000000.00, 599000, 1000000.00, 0, 8, '', '/uploads/products/product_6a1fa48abd56e6.88860332.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa48d03a416.47078762.jpg\"]', '2026-06-03 03:52:04', NULL),
(145, NULL, 'Đèn chùm đồng DC02872', 'DC02872', 'Đèn Chùm Cổ Điển', 900000.00, 780000, 900000.00, 0, 4, '', '/uploads/products/product_6a1fa4ef716e84.36416241.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa4f23f0b84.10938642.jpg\"]', '2026-06-03 03:53:09', NULL),
(146, NULL, 'Đèn chùm đồng DC02863', 'DC02863', 'Đèn Chùm Cổ Điển', 1300000.00, 950000, 1300000.00, 0, 4, '', '/uploads/products/product_6a1fa57097cd01.72435523.jpg', '[]', '2026-06-03 03:55:01', NULL),
(147, NULL, 'Đèn chùm đồng DC02861', 'DC02861', 'Đèn Chùm Cổ Điển', 980000.00, 650000, 980000.00, 0, 8, '', '/uploads/products/product_6a1fa5c03849f6.38182975.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa5c5b63471.75758417.jpg\"]', '2026-06-03 03:56:48', NULL),
(148, NULL, 'Đèn chùm đồng DC02960', 'DC02960', 'Đèn Chùm Cổ Điển', 750000.00, 660000, 750000.00, 0, 4, '', '/uploads/products/product_6a1fa61176d9c8.98783165.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa61371a777.72862559.jpg\"]', '2026-06-03 03:57:48', NULL),
(149, NULL, 'Đèn thả đồng DT01116', 'DT01116', 'Đèn Thả Cổ Điển', 690000.00, 650000, 690000.00, 0, 8, '', '/uploads/products/product_6a1fa6e998e5b1.47537791.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa6efed78c7.81503937.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa6efed7654.77179908.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa6eff08cb6.37370471.jpg\"]', '2026-06-03 04:02:05', NULL),
(150, NULL, 'Đèn thả đồng DT00877', 'DT00877', 'Đèn Thả Cổ Điển', 450000.00, 430000, 450000.00, 0, 4, '', '/uploads/products/product_6a1fa7543b5e45.64761323.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa755e07d71.36971561.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa755dd8747.03036247.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa755dd9cd5.98948817.jpg\"]', '2026-06-03 04:03:15', NULL),
(151, NULL, 'Đèn thả đồng DT01106', 'DT01106', 'Đèn Thả Cổ Điển', 650000.00, 630000, 650000.00, 0, 8, '', '/uploads/products/product_6a1fa799412568.11289453.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa79b7a2fa9.37792464.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa79b7a2557.39803021.jpg\"]', '2026-06-03 04:04:31', NULL),
(152, NULL, 'Đèn thả đồng DT00868', 'DT00868', 'Đèn Thả Cổ Điển', 780000.00, 660000, 780000.00, 0, 4, '', '/uploads/products/product_6a1fa7ddc5b844.69107151.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa7e0508ec2.97611639.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa7e05089f9.82619614.jpg\",\"\\/uploads\\/products\\/gallery_6a1fa7e0508085.67376177.jpg\"]', '2026-06-03 04:05:38', NULL),
(153, NULL, 'Đèn thả đồng DT01952', 'DT01952', 'Đèn Thả Cổ Điển', 3350000.00, 2750000, 3350000.00, 0, 4, '', '/uploads/products/product_6a1fa825ac4ef5.42073161.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa827683ef3.53099064.jpg\"]', '2026-06-03 04:06:40', NULL),
(154, NULL, 'Đèn bàn đồng DB01533', 'DB01533', 'Đèn Bàn Cổ Điển', 690000.00, 650000, 690000.00, 0, 8, '', '/uploads/products/product_6a1fa8d0418a23.72146475.jpg', '[]', '2026-06-03 04:10:09', NULL),
(155, NULL, 'Đèn bàn đồng DB01532', 'DB01532', 'Đèn Bàn Cổ Điển', 450000.00, 430000, 450000.00, 0, 4, '', '/uploads/products/product_6a1fa9306c70f3.39531776.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa931d1e873.32798163.jpg\"]', '2026-06-03 04:11:15', NULL),
(156, NULL, 'Đèn bàn đồng DB01531', 'DB01531', 'Đèn Bàn Cổ Điển', 650000.00, 630000, 650000.00, 0, 8, '', '/uploads/products/product_6a1fa97742b7c2.80317011.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa979326038.45128724.jpg\"]', '2026-06-03 04:12:34', NULL),
(157, NULL, 'Đèn bàn đồng DB01530', 'DB01530', 'Đèn Bàn Cổ Điển', 780000.00, 660000, 780000.00, 0, 4, '', '/uploads/products/product_6a1fa9c15d8ee0.63447881.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fa9c391c2f1.92043128.jpg\"]', '2026-06-03 04:13:38', NULL),
(158, NULL, 'Đèn bàn đồng DB01514', 'DB01514', 'Đèn Bàn Cổ Điển', 650000.00, 350000, 650000.00, 0, 4, '', '/uploads/products/product_6a1faa10b545a7.32682794.jpg', '[\"\\/uploads\\/products\\/gallery_6a1faa12a40b69.10567234.jpg\"]', '2026-06-03 04:14:48', NULL),
(159, NULL, 'Đèn bàn đồng DB01513', 'DB01513', 'Đèn Bàn Cổ Điển', 1700000.00, 1350000, 1700000.00, 0, 4, '', '/uploads/products/product_6a1faa431d6280.45528466.jpg', '[\"\\/uploads\\/products\\/gallery_6a1faa4484cb48.73006506.jpg\"]', '2026-06-03 04:15:41', NULL),
(160, NULL, 'Đèn bàn đồng DB01512', 'DB01512', 'Đèn Bàn Cổ Điển', 1850000.00, 1275000, 1850000.00, 0, 8, '', '/uploads/products/product_6a1faa7bec3b21.92699657.jpg', '[\"\\/uploads\\/products\\/gallery_6a1faa7d6b0b82.94400070.jpg\"]', '2026-06-03 04:17:09', NULL),
(161, NULL, 'Đèn bàn đồng DB01529', 'DB01529', 'Đèn Bàn Cổ Điển', 2550000.00, 1600000, 2550000.00, 0, 4, '', '/uploads/products/product_6a1fab1ca877a8.86378833.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fab1eaca972.49537306.jpg\"]', '2026-06-03 04:19:40', NULL),
(162, NULL, 'Đèn bàn đồng DB01528', 'DB01528', 'Đèn Bàn Cổ Điển', 4225000.00, 3300000, 4225000.00, 0, 4, '', '/uploads/products/product_6a1fab647f8f66.05951176.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fab65dd7272.68410481.jpg\"]', '2026-06-03 04:20:30', NULL),
(163, NULL, 'Đèn bàn đồng DB01527', 'DB01527', 'Đèn Bàn Cổ Điển', 3650000.00, 2850000, 3650000.00, 0, 4, '', '/uploads/products/product_6a1fab98b56b14.02846346.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fab9a00d240.52215214.jpg\"]', '2026-06-03 04:21:26', NULL),
(164, NULL, 'Đèn ốp trần đồng DO00538', 'DO00538', 'Đèn Ốp Trần Cổ Điển', 690000.00, 650000, 690000.00, 0, 4, '', '/uploads/products/product_6a1fac4ba5bbe1.30912938.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fac4dbe8628.33052368.jpg\",\"\\/uploads\\/products\\/gallery_6a1fac4dc15e72.05020039.jpg\",\"\\/uploads\\/products\\/gallery_6a1fac4dbe8614.69655143.jpg\"]', '2026-06-03 04:24:43', NULL),
(165, NULL, 'Đèn ốp trần đồng DO00539', 'DO00539', 'Đèn Ốp Trần Cổ Điển', 450000.00, 430000, 450000.00, 0, 4, '', '/uploads/products/product_6a1fac9bc203f5.21753519.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fac9dc38d55.93428950.jpg\",\"\\/uploads\\/products\\/gallery_6a1fac9dc39520.64693512.jpg\"]', '2026-06-03 04:25:42', NULL),
(166, NULL, 'Đèn ốp trần đồng DO00537', 'DO00537', 'Đèn Ốp Trần Cổ Điển', 650000.00, 630000, 650000.00, 0, 4, '', '/uploads/products/product_6a1facd81f0de4.30124730.jpg', '[\"\\/uploads\\/products\\/gallery_6a1facda24f697.69429531.jpg\",\"\\/uploads\\/products\\/gallery_6a1facda281d00.71377032.jpg\"]', '2026-06-03 04:26:59', NULL),
(167, NULL, 'Đèn ốp trần đồng DO00531', 'DO00531', 'Đèn Ốp Trần Cổ Điển', 780000.00, 660000, 780000.00, 0, 4, '', '/uploads/products/product_6a1fad1dc29bd9.92041570.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fad1f330260.27229309.jpg\"]', '2026-06-03 04:27:53', NULL),
(168, NULL, 'Đèn chùm hợp kim DC04114', 'DC04114', 'Đèn Chùm Hiện Đại', 799000.00, 599000, 0.00, 0, 8, '', '/uploads/products/product_6a1fae654821b9.86818272.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fae66eb0790.76833024.jpg\"]', '2026-06-03 04:34:00', NULL),
(169, NULL, 'Đèn chùm hợp kim DC04128', 'DC04128', 'Đèn Chùm Hiện Đại', 699000.00, 599000, 0.00, 0, 8, '', '/uploads/products/product_6a1faec543ad00.39525528.jpg', '[\"\\/uploads\\/products\\/gallery_6a1faec6bcc6f8.14555390.jpg\"]', '2026-06-03 04:35:17', NULL),
(170, NULL, 'Đèn chùm hợp kim DC04104', 'DC04104', 'Đèn Chùm Hiện Đại', 799000.00, 699000, 0.00, 0, 8, '', '/uploads/products/product_6a1faf10783903.22703779.jpg', '[\"\\/uploads\\/products\\/gallery_6a1faf121d4485.51702536.jpg\"]', '2026-06-03 04:36:52', NULL),
(171, NULL, 'Đèn chùm hợp kim DC04109', 'DC04109', 'Đèn Chùm Hiện Đại', 799000.00, 699000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb069738e47.85109456.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb06e3b46a4.94228701.jpg\"]', '2026-06-03 04:38:27', NULL),
(172, NULL, 'Đèn chùm hợp kim DC04144', 'DC04144', 'Đèn Chùm Hiện Đại', 899000.00, 799000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb0e58f0d19.64983378.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb0e8aafd54.98149298.jpg\"]', '2026-06-03 04:40:06', NULL),
(173, NULL, 'Đèn chùm hợp kim DC03968', 'DC03968', 'Đèn Chùm Hiện Đại', 3500000.00, 3200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb13b35a072.96766563.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb13d3784b1.95262202.jpg\"]', '2026-06-03 04:45:51', NULL),
(174, NULL, 'Đèn chùm hợp kim DC03962', 'DC03962', 'Đèn Chùm Hiện Đại', 5500000.00, 5000000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb1d0aa0032.19443609.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb1d2464d33.62214329.jpg\"]', '2026-06-03 04:48:25', NULL),
(175, NULL, 'Đèn chùm hợp kim DC03894', 'DC03894', 'Đèn Chùm Hiện Đại', 4500000.00, 4000000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb23b848558.55748514.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb2404ad4f5.17487471.jpg\"]', '2026-06-03 04:49:57', NULL),
(176, NULL, '', 'SP1780462270459', '', 8000000.00, 7500000, 8000000.00, 0, 8, '', '/uploads/products/product_6a1fb28a7e61a5.43326234.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb28bdda430.85630229.jpg\"]', '2026-06-03 04:51:09', NULL),
(177, NULL, 'Đèn chùm hợp kim DC03970', 'DC03970', 'Đèn Chùm Hiện Đại', 8000000.00, 7500000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb2e0771713.41731256.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb2e1e10be2.31961403.jpg\"]', '2026-06-03 04:52:46', NULL),
(178, NULL, 'Đèn chùm hợp kim DC03948', 'DC03948', 'Đèn Chùm Hiện Đại', 4500000.00, 4000000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb33a5522f2.52847222.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb35589f885.61240948.jpg\"]', '2026-06-03 04:54:45', NULL),
(179, NULL, 'Đèn thả đồng DT03131', 'DT03131', 'Đèn Thả Hiện Đại', 1220000.00, 920000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb54b22fd29.42233427.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb54d013131.65499161.jpg\",\"\\/uploads\\/products\\/gallery_6a1fb54d014138.38743967.jpg\"]', '2026-06-03 05:03:33', NULL),
(180, NULL, 'Đèn thả đồng DT02722', 'DT02722', 'Đèn Thả Hiện Đại', 1120000.00, 820000, 0.00, 0, 16, '', '/uploads/products/product_6a1fb603ba8478.33785682.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb607a24053.02037255.jpg\"]', '2026-06-03 05:06:28', NULL),
(181, NULL, 'Đèn thả đồng DT02643', 'DT02643', 'Đèn Thả Hiện Đại', 1280000.00, 950000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb6e439ae45.79555360.jpg', '[]', '2026-06-03 05:10:03', NULL),
(182, NULL, 'Đèn thả đồng DT02587', 'DT02587', 'Đèn Thả Hiện Đại', 1150000.00, 880000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb7646ffd64.58072577.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb765e94f83.93337865.jpg\"]', '2026-06-03 05:12:26', NULL),
(183, NULL, 'Đèn thả đồng DT02581', 'DT02581', 'Đèn Thả Hiện Đại', 5500000.00, 4200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb7c2da3b04.98226910.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb7c4635e11.71751100.jpg\"]', '2026-06-03 05:13:55', NULL),
(184, NULL, 'Đèn thả đồng DT02572', 'DT02572', 'Đèn Thả Hiện Đại', 8500000.00, 7200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb8343b4349.40209364.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb8364c6263.77737551.jpg\"]', '2026-06-03 05:15:35', NULL),
(185, NULL, 'Đèn thả đồng DT02570', 'DT02570', 'Đèn Thả Hiện Đại', 3800000.00, 2900000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb890b76eb8.50702293.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb892320e21.35418506.jpg\"]', '2026-06-03 05:17:01', NULL),
(186, NULL, 'Đèn thả đồng DT02568', 'DT02568', 'Đèn Thả Hiện Đại', 9900000.00, 8800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb8d71701a2.99940459.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb8d8887cb1.45047994.jpg\"]', '2026-06-03 05:18:14', NULL),
(187, NULL, 'Đèn thả đồng DT02494', 'DT02494', 'Đèn Thả Hiện Đại', 6800000.00, 5500000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb926445267.01202851.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb927bebb99.31428086.jpg\"]', '2026-06-03 05:19:28', NULL),
(188, NULL, 'Đèn thả hợp kim DT03308', 'DT03308', 'Đèn Thả Hiện Đại', 950000.00, 650000, 0.00, 0, 8, '', '/uploads/products/product_6a1fb97ef03cd7.05597923.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fb980ba7d01.84216720.jpg\"]', '2026-06-03 05:21:17', NULL),
(189, NULL, 'Đèn bàn đồng DB02228', 'DB02228', 'Đèn Bàn Hiện Đại', 1150000.00, 820000, 0.00, 0, 8, '', '/uploads/products/product_6a1fba19c06cc7.78457418.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fba1b7a5bc3.96226161.jpg\"]', '2026-06-03 05:23:42', NULL),
(190, NULL, 'Đèn bàn đồng DB02222', 'DB02222', 'Đèn Bàn Hiện Đại', 1220000.00, 950000, 0.00, 0, 8, '', '/uploads/products/product_6a1fba7e30cb69.10503152.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fba7fd884b6.02835981.jpg\"]', '2026-06-03 05:25:09', NULL),
(191, NULL, 'Đèn bàn đồng DB02232', 'DB02232', 'Đèn Bàn Hiện Đại', 1050000.00, 750000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbaccef16c0.52997225.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbace6e2271.13857850.jpg\"]', '2026-06-03 05:26:22', NULL),
(192, NULL, 'Đèn bàn đồng DB02206', 'DB02206', 'Đèn Bàn Hiện Đại', 1280000.00, 920000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbb123c84a0.89017166.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbb13c088f6.90022156.jpg\"]', '2026-06-03 05:27:33', NULL),
(193, NULL, 'Đèn bàn đồng DB02204', 'DB02204', 'Đèn Bàn Hiện Đại', 1190000.00, 880000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbb56bc2424.02653375.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbb5b7be447.32817294.jpg\"]', '2026-06-03 05:29:09', NULL),
(194, NULL, 'Đèn bàn đồng DB02203', 'DB02203', 'Đèn Bàn Hiện Đại', 4800000.00, 3900000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbbac9660d4.27353079.jpg', '[]', '2026-06-03 05:30:28', NULL),
(195, NULL, 'Đèn bàn đồng DB02202', 'DB02202', 'Đèn Bàn Hiện Đại', 6500000.00, 5200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbbfcc75b18.92230106.jpg', '[]', '2026-06-03 05:31:51', NULL),
(196, NULL, 'Đèn bàn đồng DB02112', 'DB02112', 'Đèn Bàn Hiện Đại', 3500000.00, 2800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbc51ea4874.67445014.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbc535f9c19.89214125.jpg\"]', '2026-06-03 05:33:16', NULL),
(197, NULL, 'Đèn bàn đồng DB02176', 'DB02176', 'Đèn Bàn Hiện Đại', 9200000.00, 7800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbcaad722a7.13230486.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbcac4379b5.23845332.jpg\"]', '2026-06-03 05:34:35', NULL),
(198, NULL, 'Đèn bàn đồng DB02153', 'DB02153', 'Đèn Bàn Hiện Đại', 5800000.00, 4500000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbcf46821c6.72415554.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbcf5be2634.40236249.jpg\"]', '2026-06-03 05:35:47', NULL),
(199, NULL, 'Đèn chùm đồng DC03726', 'DC03726', 'Đèn Chùm Tân Cổ Điển', 990000.00, 850000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbdd48f05d3.11481570.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbdd641fc13.43781231.jpg\",\"\\/uploads\\/products\\/gallery_6a1fbdd641f382.97939237.jpg\"]', '2026-06-03 05:39:37', NULL),
(200, NULL, 'Đèn chùm đồng DC03699', 'DC03699', 'Đèn Chùm Tân Cổ Điển', 1500000.00, 989000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbe46f220f0.56786975.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbe489631f6.07742641.jpg\",\"\\/uploads\\/products\\/gallery_6a1fbe48963db5.55571198.jpg\"]', '2026-06-03 05:41:31', NULL),
(201, NULL, 'Đèn chùm đồng DC03698', 'DC03698', 'Đèn Chùm Tân Cổ Điển', 1250000.00, 890000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbe9ce0ddb3.25712406.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbe9e643ec6.15160725.jpg\"]', '2026-06-03 05:42:59', NULL),
(202, NULL, 'Đèn chùm đồng DC03878', 'DC03878', 'Đèn Chùm Tân Cổ Điển', 3500000.00, 3200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbef369a6d5.79608170.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbef5253155.72730596.jpg\",\"\\/uploads\\/products\\/gallery_6a1fbef5256fb5.28300650.jpg\"]', '2026-06-03 05:44:12', NULL),
(203, NULL, 'Đèn chùm đồng DC03902', 'DC03902', 'Đèn Chùm Tân Cổ Điển', 4500000.00, 4200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbf43b76020.78469906.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbf45383352.01255234.jpg\",\"\\/uploads\\/products\\/gallery_6a1fbf45384292.25079235.jpg\"]', '2026-06-03 05:45:44', NULL),
(204, NULL, 'Đèn chùm đồng DC03524', 'DC03524', 'Đèn Chùm Tân Cổ Điển', 5500000.00, 5200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fbfbe3fb375.92447872.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fbfbfa97ce4.53208837.jpg\",\"\\/uploads\\/products\\/gallery_6a1fbfbfa98fa8.79048678.jpg\"]', '2026-06-03 05:47:37', NULL),
(205, NULL, 'Đèn chùm đồng DC04283', 'DC04283', 'Đèn Chùm Tân Cổ Điển', 7500000.00, 7200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc002ccc907.50528526.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc00481d7b6.73815474.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc00481ec88.91953746.jpg\"]', '2026-06-03 05:49:09', NULL),
(206, NULL, 'Đèn ốp trần DO00639', 'DO00639', 'Đèn Ốp Trần Tân Cổ Điển', 4500000.00, 4250000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc20dc18091.04189634.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc20f686b05.77274851.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc20f687769.69277781.jpg\"]', '2026-06-03 05:57:48', NULL),
(207, NULL, 'Đèn ốp trần DO00638', 'DO00638', 'Đèn Ốp Trần Tân Cổ Điển', 4500000.00, 4200000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc26aede4a9.10681760.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc26c6f3565.40525724.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc26c73eab4.77739754.jpg\"]', '2026-06-03 05:59:17', NULL),
(208, NULL, 'Đèn ốp trầnDO00637', 'DO00637', 'Đèn Ốp Trần Tân Cổ Điển', 4400000.00, 4100000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc2c82ab048.08957436.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc2c99e37c4.08719517.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc2c99e3ed0.21800630.jpg\"]', '2026-06-03 06:00:31', NULL),
(209, NULL, 'Đèn ốp trầnDO00348', 'DO00348', 'Đèn Ốp Trần Tân Cổ Điển', 12500000.00, 12000000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc314ed47f7.61771033.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc3166abef0.55911271.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc3166ab617.30923718.jpg\"]', '2026-06-03 06:01:54', NULL),
(210, NULL, 'Đèn ốp trần DO00369', 'DO00369', 'Đèn Ốp Trần Tân Cổ Điển', 13000000.00, 12750000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc35cd31cf7.58955136.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc35e372b63.94821883.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc35e3722e4.89266108.jpg\"]', '2026-06-03 06:03:15', NULL),
(211, NULL, 'Đèn quạt hợp kim DQ00465', 'DQ00465', 'Đèn Quạt Tân Cổ Điển', 15000000.00, 13500000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc3dfc22700.99928803.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc3e1234574.52928678.jpg\"]', '2026-06-03 06:05:35', NULL),
(212, NULL, 'Đèn quạt hợp kim DQ00379', 'DQ00379', 'Đèn Quạt Tân Cổ Điển', 10800000.00, 10050000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc4442dba15.26102757.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc4458abaf9.41727613.jpg\"]', '2026-06-03 06:07:37', NULL),
(213, NULL, 'Đèn quạt hợp kim DQ00058', 'DQ00058', 'Đèn Quạt Tân Cổ Điển', 21000000.00, 18900000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc4b3091a52.77195769.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc4ba3ba9e6.76342940.jpg\"]', '2026-06-03 06:09:01', NULL),
(214, NULL, 'Đèn quạt hợp kim DQ00126', 'DQ00126', 'Đèn Quạt Tân Cổ Điển', 14000000.00, 11800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc506d5e587.95846039.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc5087faa55.77557343.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc5087fb683.67473641.jpg\"]', '2026-06-03 06:10:21', NULL),
(215, NULL, '', 'SP1780467089491', '', 12500000.00, 10800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc554a20328.60710693.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc5560a4578.58270086.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc5560a4d30.80685645.jpg\"]', '2026-06-03 06:11:29', NULL),
(216, NULL, 'Đèn quạt hợp kim DQ00115', 'DQ00115', 'Đèn Quạt Tân Cổ Điển', 12500000.00, 10800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc5a874a8e5.13524667.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc5aa58d8e5.37567362.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc5aa58c8c8.92120773.jpg\"]', '2026-06-03 06:12:50', NULL),
(217, NULL, 'Đèn bàn hợp kim DB02029', 'DB02029', 'Đèn Bàn Tân Cổ Điển', 6200000.00, 5100000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc68d620261.55953899.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc68ed6b745.51540438.jpg\"]', '2026-06-03 06:17:00', NULL),
(218, NULL, 'Đèn bàn hợp kim DB00474', 'DB00474', 'Đèn Bàn Tân Cổ Điển', 12500000.00, 10500000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc6ff28a116.14297897.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc700973889.43893077.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc7020e6944.86012477.jpg\"]', '2026-06-03 06:18:52', NULL),
(219, NULL, 'Đèn bàn hợp kim DB01038', 'DB01038', 'Đèn Bàn Tân Cổ Điển', 14000000.00, 11800000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc7841427c5.52569062.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc7866910c4.30861572.jpg\",\"\\/uploads\\/products\\/gallery_6a1fc786690eb7.46762961.jpg\"]', '2026-06-03 06:21:00', NULL),
(220, NULL, 'Đèn bàn hợp kim DB02288', 'DB02288', 'Đèn Bàn Tân Cổ Điển', 850000.00, 590000, 0.00, 0, 8, '', '/uploads/products/product_6a1fc7df2e0873.03157955.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc7e0c84743.53436672.jpg\"]', '2026-06-03 06:22:33', NULL),
(221, NULL, 'Đèn bàn hợp kim DB02287', 'DB02287', 'Đèn Bàn Tân Cổ Điển', 900000.00, 680000, 950000.00, 1, 8, '', '/uploads/products/product_6a1fc8340d4bb8.37733723.jpg', '[\"\\/uploads\\/products\\/gallery_6a1fc83607a528.06215769.jpg\"]', '2026-06-03 06:23:50', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_images`
--

CREATE TABLE `product_images` (
  `id` int NOT NULL,
  `product_id` int NOT NULL,
  `image_url` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_main` tinyint(1) DEFAULT '0',
  `sort_order` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_images`
--

INSERT INTO `product_images` (`id`, `product_id`, `image_url`, `is_main`, `sort_order`, `created_at`) VALUES
(39, 102, '/uploads/products/gallery_69d7a79890e113.01302241.jpg', 1, 1, '2026-04-22 15:35:13'),
(40, 102, '/uploads/products/gallery_69d7a79887ee74.94337730.jpg', 0, 2, '2026-04-22 15:35:13'),
(41, 102, '/uploads/products/gallery_69d7a79887e6c2.43579748.jpg', 0, 3, '2026-04-22 15:35:13'),
(42, 103, '/uploads/products/gallery_69d7a81a3f7542.91943895.jpg', 1, 1, '2026-04-22 15:35:13'),
(43, 103, '/uploads/products/gallery_69d7a81a35ee60.00215874.jpg', 0, 2, '2026-04-22 15:35:13'),
(44, 104, '/uploads/products/gallery_69d7a96cb5c248.73402564.jpg', 1, 1, '2026-04-22 15:35:13'),
(45, 105, '/uploads/products/gallery_69d7a9d37203f3.84309175.jpg', 1, 1, '2026-04-22 15:35:13'),
(46, 105, '/uploads/products/gallery_69d7a9d367e745.29795517.jpg', 0, 2, '2026-04-22 15:35:13'),
(47, 106, '/uploads/products/gallery_69d7aa10a734d0.16824513.jpg', 1, 1, '2026-04-22 15:35:13'),
(51, 112, '/uploads/products/gallery_69d7ad5cc235c8.85656072.jpg', 1, 1, '2026-04-22 15:35:13'),
(52, 113, '/uploads/products/gallery_69d7adbc03af55.18784849.jpg', 1, 1, '2026-04-22 15:35:13'),
(53, 113, '/uploads/products/gallery_69d7adbbee2671.92799294.jpg', 0, 2, '2026-04-22 15:35:13'),
(54, 114, '/uploads/products/gallery_69d7ae49c39417.49766475.jpg', 1, 1, '2026-04-22 15:35:13'),
(55, 115, '/uploads/products/gallery_69d7aec1786b43.19726884.jpg', 1, 1, '2026-04-22 15:35:13'),
(56, 115, '/uploads/products/gallery_69d7aec16f2576.73448004.jpg', 0, 2, '2026-04-22 15:35:13'),
(57, 120, '/uploads/products/gallery_69d7b2e825d040.11235542.jpg', 1, 1, '2026-04-22 15:35:13'),
(58, 121, '/uploads/products/gallery_69d7cc04e60ab1.96969647.jpg', 1, 1, '2026-04-22 15:35:13'),
(59, 121, '/uploads/products/gallery_69d7cc06e606e4.38165142.jpg', 0, 2, '2026-04-22 15:35:13'),
(60, 122, '/uploads/products/gallery_69df6a985baf01.24928883.jpg', 1, 1, '2026-04-22 15:35:13'),
(61, 122, '/uploads/products/gallery_69df6a985bb416.39151012.jpg', 0, 2, '2026-04-22 15:35:13'),
(62, 123, '/uploads/products/gallery_69df6b1ca1c1e1.64687563.jpg', 1, 1, '2026-04-22 15:35:13'),
(63, 124, '/uploads/products/gallery_69df6b79405597.90935187.jpg', 1, 1, '2026-04-22 15:35:13'),
(64, 125, '/uploads/products/gallery_69df6bd086d6b5.16714122.jpg', 1, 1, '2026-04-22 15:35:13'),
(65, 125, '/uploads/products/gallery_69df6bd07cb031.32017001.jpg', 0, 2, '2026-04-22 15:35:13'),
(66, 126, '/uploads/products/gallery_69df6caa754771.62870968.jpg', 1, 1, '2026-04-22 15:35:13'),
(67, 126, '/uploads/products/gallery_69df6caa6af858.06682242.jpg', 0, 2, '2026-04-22 15:35:13'),
(68, 132, '/uploads/products/gallery_69df6f219a8cd3.02274615.jpg', 1, 1, '2026-04-22 15:35:13'),
(69, 132, '/uploads/products/gallery_69df6f219a9250.72864206.jpg', 0, 2, '2026-04-22 15:35:13'),
(70, 133, '/uploads/products/gallery_69df703f85b576.87842549.jpg', 1, 1, '2026-04-22 15:35:13'),
(71, 133, '/uploads/products/gallery_69df703f7ba2b1.32113295.jpg', 0, 2, '2026-04-22 15:35:13'),
(72, 134, '/uploads/products/gallery_69df70a4e22685.34309194.jpg', 1, 1, '2026-04-22 15:35:13'),
(73, 135, '/uploads/products/gallery_69df71498061d1.81623285.jpg', 1, 1, '2026-04-22 15:35:13'),
(74, 136, '/uploads/products/gallery_69df71a0a90109.67402435.jpg', 1, 1, '2026-04-22 15:35:13'),
(84, 76, '/uploads/products/gallery_69d71c3581fb23.57905349.jpg', 1, 1, '2026-05-27 14:38:12'),
(85, 76, '/uploads/products/gallery_69d71c35778205.90595727.jpg', 0, 2, '2026-05-27 14:38:12'),
(88, 138, '/uploads/products/gallery_6a156b39e09df3.48885774.jpg', 1, 1, '2026-05-27 15:01:16'),
(89, 137, '/uploads/products/gallery_69df71fb3affe9.14640701.jpg', 1, 1, '2026-05-27 15:16:00'),
(92, 77, '/uploads/products/gallery_69d7207a48d139.69865229.jpg', 1, 1, '2026-06-03 03:36:05'),
(93, 77, '/uploads/products/gallery_69d7207a48d6d4.38182450.jpg', 0, 2, '2026-06-03 03:36:05'),
(94, 78, '/uploads/products/gallery_69d720da2e0731.51530153.jpg', 1, 1, '2026-06-03 03:36:08'),
(95, 79, '/uploads/products/gallery_69d722aea9a4f3.19936120.jpg', 1, 1, '2026-06-03 03:36:35'),
(96, 80, '/uploads/products/gallery_69d788339040a1.16281735.jpg', 1, 1, '2026-06-03 03:37:01'),
(97, 139, '/uploads/products/gallery_6a1fa195c59bf3.84355748.jpg', 1, 1, '2026-06-03 03:39:16'),
(98, 140, '/uploads/products/gallery_6a1fa1f2cd6840.44951128.jpg', 1, 1, '2026-06-03 03:40:54'),
(100, 142, '/uploads/products/gallery_6a1fa2aaed7698.98366744.jpg', 1, 1, '2026-06-03 03:43:28'),
(101, 141, '/uploads/products/gallery_6a1fa31518cbb3.09766780.jpg', 1, 1, '2026-06-03 03:44:32'),
(102, 143, '/uploads/products/gallery_6a1fa33865c869.99187786.jpg', 1, 1, '2026-06-03 03:45:46'),
(103, 144, '/uploads/products/gallery_6a1fa48d03a416.47078762.jpg', 1, 1, '2026-06-03 03:52:04'),
(104, 145, '/uploads/products/gallery_6a1fa4f23f0b84.10938642.jpg', 1, 1, '2026-06-03 03:53:09'),
(105, 147, '/uploads/products/gallery_6a1fa5c5b63471.75758417.jpg', 1, 1, '2026-06-03 03:56:48'),
(106, 148, '/uploads/products/gallery_6a1fa61371a777.72862559.jpg', 1, 1, '2026-06-03 03:57:48'),
(107, 91, '/uploads/products/gallery_69d78fab5c2fd6.48744760.jpg', 1, 1, '2026-06-03 03:59:36'),
(108, 91, '/uploads/products/gallery_69d78fab518ca1.61908250.jpg', 0, 2, '2026-06-03 03:59:36'),
(109, 92, '/uploads/products/gallery_69d7900998e803.93927355.jpg', 1, 1, '2026-06-03 03:59:48'),
(110, 93, '/uploads/products/gallery_69d7905259afa9.93375519.jpg', 1, 1, '2026-06-03 04:00:00'),
(111, 93, '/uploads/products/gallery_69d790524f54b6.99049591.jpg', 0, 2, '2026-06-03 04:00:00'),
(112, 94, '/uploads/products/gallery_69d790df7610e3.52046612.jpg', 1, 1, '2026-06-03 04:00:16'),
(113, 94, '/uploads/products/gallery_69d790df6d1b73.74697123.jpg', 0, 2, '2026-06-03 04:00:16'),
(114, 95, '/uploads/products/gallery_69d79133248c57.00259426.jpg', 1, 1, '2026-06-03 04:00:24'),
(115, 95, '/uploads/products/gallery_69d791331c44c5.58744768.jpg', 0, 2, '2026-06-03 04:00:24'),
(116, 95, '/uploads/products/gallery_69d791331ab1b5.49230867.jpg', 0, 3, '2026-06-03 04:00:24'),
(120, 149, '/uploads/products/gallery_6a1fa6efed78c7.81503937.jpg', 1, 1, '2026-06-03 04:02:12'),
(121, 149, '/uploads/products/gallery_6a1fa6efed7654.77179908.jpg', 0, 2, '2026-06-03 04:02:12'),
(122, 149, '/uploads/products/gallery_6a1fa6eff08cb6.37370471.jpg', 0, 3, '2026-06-03 04:02:12'),
(123, 150, '/uploads/products/gallery_6a1fa755e07d71.36971561.jpg', 1, 1, '2026-06-03 04:03:15'),
(124, 150, '/uploads/products/gallery_6a1fa755dd8747.03036247.jpg', 0, 2, '2026-06-03 04:03:15'),
(125, 150, '/uploads/products/gallery_6a1fa755dd9cd5.98948817.jpg', 0, 3, '2026-06-03 04:03:15'),
(126, 151, '/uploads/products/gallery_6a1fa79b7a2fa9.37792464.jpg', 1, 1, '2026-06-03 04:04:31'),
(127, 151, '/uploads/products/gallery_6a1fa79b7a2557.39803021.jpg', 0, 2, '2026-06-03 04:04:31'),
(128, 152, '/uploads/products/gallery_6a1fa7e0508ec2.97611639.jpg', 1, 1, '2026-06-03 04:05:38'),
(129, 152, '/uploads/products/gallery_6a1fa7e05089f9.82619614.jpg', 0, 2, '2026-06-03 04:05:38'),
(130, 152, '/uploads/products/gallery_6a1fa7e0508085.67376177.jpg', 0, 3, '2026-06-03 04:05:38'),
(131, 153, '/uploads/products/gallery_6a1fa827683ef3.53099064.jpg', 1, 1, '2026-06-03 04:06:40'),
(132, 155, '/uploads/products/gallery_6a1fa931d1e873.32798163.jpg', 1, 1, '2026-06-03 04:11:15'),
(133, 156, '/uploads/products/gallery_6a1fa979326038.45128724.jpg', 1, 1, '2026-06-03 04:12:34'),
(134, 157, '/uploads/products/gallery_6a1fa9c391c2f1.92043128.jpg', 1, 1, '2026-06-03 04:13:38'),
(135, 158, '/uploads/products/gallery_6a1faa12a40b69.10567234.jpg', 1, 1, '2026-06-03 04:14:48'),
(136, 159, '/uploads/products/gallery_6a1faa4484cb48.73006506.jpg', 1, 1, '2026-06-03 04:15:41'),
(137, 160, '/uploads/products/gallery_6a1faa7d6b0b82.94400070.jpg', 1, 1, '2026-06-03 04:17:09'),
(138, 161, '/uploads/products/gallery_6a1fab1eaca972.49537306.jpg', 1, 1, '2026-06-03 04:19:40'),
(139, 162, '/uploads/products/gallery_6a1fab65dd7272.68410481.jpg', 1, 1, '2026-06-03 04:20:30'),
(140, 163, '/uploads/products/gallery_6a1fab9a00d240.52215214.jpg', 1, 1, '2026-06-03 04:21:26'),
(141, 164, '/uploads/products/gallery_6a1fac4dbe8628.33052368.jpg', 1, 1, '2026-06-03 04:24:43'),
(142, 164, '/uploads/products/gallery_6a1fac4dc15e72.05020039.jpg', 0, 2, '2026-06-03 04:24:43'),
(143, 164, '/uploads/products/gallery_6a1fac4dbe8614.69655143.jpg', 0, 3, '2026-06-03 04:24:43'),
(144, 165, '/uploads/products/gallery_6a1fac9dc38d55.93428950.jpg', 1, 1, '2026-06-03 04:25:42'),
(145, 165, '/uploads/products/gallery_6a1fac9dc39520.64693512.jpg', 0, 2, '2026-06-03 04:25:42'),
(146, 166, '/uploads/products/gallery_6a1facda24f697.69429531.jpg', 1, 1, '2026-06-03 04:26:59'),
(147, 166, '/uploads/products/gallery_6a1facda281d00.71377032.jpg', 0, 2, '2026-06-03 04:26:59'),
(148, 167, '/uploads/products/gallery_6a1fad1f330260.27229309.jpg', 1, 1, '2026-06-03 04:27:53'),
(153, 82, '/uploads/products/gallery_69d78a4bee8618.83088258.jpg', 1, 1, '2026-06-03 04:31:32'),
(154, 82, '/uploads/products/gallery_69d78a4be48d15.88816358.jpg', 0, 2, '2026-06-03 04:31:32'),
(155, 83, '/uploads/products/gallery_69d78aeabc7a57.83793796.jpg', 1, 1, '2026-06-03 04:31:43'),
(156, 83, '/uploads/products/gallery_69d78aeab310c6.07049535.jpg', 0, 2, '2026-06-03 04:31:43'),
(157, 84, '/uploads/products/gallery_69d78b8d8fa4b8.79090630.jpg', 1, 1, '2026-06-03 04:31:58'),
(158, 85, '/uploads/products/gallery_69d78c17664421.60404299.jpg', 1, 1, '2026-06-03 04:32:07'),
(166, 171, '/uploads/products/gallery_6a1fb06e3b46a4.94228701.jpg', 1, 1, '2026-06-03 04:42:17'),
(167, 168, '/uploads/products/gallery_6a1fae66eb0790.76833024.jpg', 1, 1, '2026-06-03 04:42:42'),
(168, 169, '/uploads/products/gallery_6a1faec6bcc6f8.14555390.jpg', 1, 1, '2026-06-03 04:42:48'),
(169, 170, '/uploads/products/gallery_6a1faf121d4485.51702536.jpg', 1, 1, '2026-06-03 04:42:52'),
(170, 172, '/uploads/products/gallery_6a1fb0e8aafd54.98149298.jpg', 1, 1, '2026-06-03 04:44:29'),
(172, 173, '/uploads/products/gallery_6a1fb13d3784b1.95262202.jpg', 1, 1, '2026-06-03 04:45:56'),
(174, 174, '/uploads/products/gallery_6a1fb1d2464d33.62214329.jpg', 1, 1, '2026-06-03 04:48:31'),
(176, 175, '/uploads/products/gallery_6a1fb2404ad4f5.17487471.jpg', 1, 1, '2026-06-03 04:50:00'),
(177, 176, '/uploads/products/gallery_6a1fb28bdda430.85630229.jpg', 1, 1, '2026-06-03 04:51:09'),
(179, 177, '/uploads/products/gallery_6a1fb2e1e10be2.31961403.jpg', 1, 1, '2026-06-03 04:52:52'),
(181, 178, '/uploads/products/gallery_6a1fb35589f885.61240948.jpg', 1, 1, '2026-06-03 04:54:49'),
(201, 96, '/uploads/products/gallery_69d794db39bec6.13468292.jpg', 1, 1, '2026-06-03 05:10:10'),
(202, 96, '/uploads/products/gallery_69d794db3065a9.29469814.jpg', 0, 2, '2026-06-03 05:10:10'),
(203, 97, '/uploads/products/gallery_69d79557795d32.40006096.jpg', 1, 1, '2026-06-03 05:10:13'),
(204, 98, '/uploads/products/gallery_69d79600b40789.70300699.jpg', 1, 1, '2026-06-03 05:10:16'),
(205, 99, '/uploads/products/gallery_69d796729bab22.84731919.jpg', 1, 1, '2026-06-03 05:10:19'),
(207, 100, '/uploads/products/gallery_69d796dab3d7d6.61624110.jpg', 1, 1, '2026-06-03 05:10:24'),
(208, 179, '/uploads/products/gallery_6a1fb54d013131.65499161.jpg', 1, 1, '2026-06-03 05:10:29'),
(209, 179, '/uploads/products/gallery_6a1fb54d014138.38743967.jpg', 0, 2, '2026-06-03 05:10:29'),
(210, 180, '/uploads/products/gallery_6a1fb607a24053.02037255.jpg', 1, 1, '2026-06-03 05:10:36'),
(211, 182, '/uploads/products/gallery_6a1fb765e94f83.93337865.jpg', 1, 1, '2026-06-03 05:12:26'),
(212, 183, '/uploads/products/gallery_6a1fb7c4635e11.71751100.jpg', 1, 1, '2026-06-03 05:13:55'),
(213, 184, '/uploads/products/gallery_6a1fb8364c6263.77737551.jpg', 1, 1, '2026-06-03 05:15:35'),
(214, 185, '/uploads/products/gallery_6a1fb892320e21.35418506.jpg', 1, 1, '2026-06-03 05:17:01'),
(215, 186, '/uploads/products/gallery_6a1fb8d8887cb1.45047994.jpg', 1, 1, '2026-06-03 05:18:14'),
(216, 187, '/uploads/products/gallery_6a1fb927bebb99.31428086.jpg', 1, 1, '2026-06-03 05:19:28'),
(217, 188, '/uploads/products/gallery_6a1fb980ba7d01.84216720.jpg', 1, 1, '2026-06-03 05:21:17'),
(218, 107, '/uploads/products/gallery_69d7aa9d0f65d3.16220317.jpg', 1, 1, '2026-06-03 05:21:58'),
(219, 109, '/uploads/products/gallery_69d7abd769a3f6.60671050.jpg', 1, 1, '2026-06-03 05:22:07'),
(220, 111, '/uploads/products/gallery_69d7ac9db4f3c6.95923441.jpg', 1, 1, '2026-06-03 05:22:16'),
(221, 189, '/uploads/products/gallery_6a1fba1b7a5bc3.96226161.jpg', 1, 1, '2026-06-03 05:23:42'),
(222, 190, '/uploads/products/gallery_6a1fba7fd884b6.02835981.jpg', 1, 1, '2026-06-03 05:25:09'),
(223, 191, '/uploads/products/gallery_6a1fbace6e2271.13857850.jpg', 1, 1, '2026-06-03 05:26:22'),
(224, 192, '/uploads/products/gallery_6a1fbb13c088f6.90022156.jpg', 1, 1, '2026-06-03 05:27:33'),
(225, 193, '/uploads/products/gallery_6a1fbb5b7be447.32817294.jpg', 1, 1, '2026-06-03 05:29:09'),
(226, 196, '/uploads/products/gallery_6a1fbc535f9c19.89214125.jpg', 1, 1, '2026-06-03 05:33:16'),
(227, 197, '/uploads/products/gallery_6a1fbcac4379b5.23845332.jpg', 1, 1, '2026-06-03 05:34:35'),
(228, 198, '/uploads/products/gallery_6a1fbcf5be2634.40236249.jpg', 1, 1, '2026-06-03 05:35:47'),
(229, 86, '/uploads/products/gallery_69d78cb5960f30.01158316.jpg', 1, 1, '2026-06-03 05:37:49'),
(230, 86, '/uploads/products/gallery_69d78cb58ca5b4.38915139.jpg', 0, 2, '2026-06-03 05:37:49'),
(231, 87, '/uploads/products/gallery_69d78d586f36e4.34037836.jpg', 1, 1, '2026-06-03 05:37:57'),
(232, 87, '/uploads/products/gallery_69d78d586227c7.79929363.jpg', 0, 2, '2026-06-03 05:37:57'),
(233, 88, '/uploads/products/gallery_69d78dbf9ef104.21693810.jpg', 1, 1, '2026-06-03 05:38:01'),
(234, 89, '/uploads/products/gallery_69d78e411f01d5.63001302.jpg', 1, 1, '2026-06-03 05:38:06'),
(235, 89, '/uploads/products/gallery_69d78e4115b6e6.72190854.jpg', 0, 2, '2026-06-03 05:38:06'),
(236, 90, '/uploads/products/gallery_69d78ebabaf885.36423087.jpg', 1, 1, '2026-06-03 05:38:11'),
(237, 90, '/uploads/products/gallery_69d78ebab13c86.03455424.jpg', 0, 2, '2026-06-03 05:38:11'),
(238, 199, '/uploads/products/gallery_6a1fbdd641fc13.43781231.jpg', 1, 1, '2026-06-03 05:39:37'),
(239, 199, '/uploads/products/gallery_6a1fbdd641f382.97939237.jpg', 0, 2, '2026-06-03 05:39:37'),
(240, 200, '/uploads/products/gallery_6a1fbe489631f6.07742641.jpg', 1, 1, '2026-06-03 05:41:31'),
(241, 200, '/uploads/products/gallery_6a1fbe48963db5.55571198.jpg', 0, 2, '2026-06-03 05:41:31'),
(242, 201, '/uploads/products/gallery_6a1fbe9e643ec6.15160725.jpg', 1, 1, '2026-06-03 05:42:59'),
(243, 202, '/uploads/products/gallery_6a1fbef5253155.72730596.jpg', 1, 1, '2026-06-03 05:44:12'),
(244, 202, '/uploads/products/gallery_6a1fbef5256fb5.28300650.jpg', 0, 2, '2026-06-03 05:44:12'),
(245, 203, '/uploads/products/gallery_6a1fbf45383352.01255234.jpg', 1, 1, '2026-06-03 05:45:44'),
(246, 203, '/uploads/products/gallery_6a1fbf45384292.25079235.jpg', 0, 2, '2026-06-03 05:45:44'),
(247, 204, '/uploads/products/gallery_6a1fbfbfa97ce4.53208837.jpg', 1, 1, '2026-06-03 05:47:37'),
(248, 204, '/uploads/products/gallery_6a1fbfbfa98fa8.79048678.jpg', 0, 2, '2026-06-03 05:47:37'),
(249, 205, '/uploads/products/gallery_6a1fc00481d7b6.73815474.jpg', 1, 1, '2026-06-03 05:49:09'),
(250, 205, '/uploads/products/gallery_6a1fc00481ec88.91953746.jpg', 0, 2, '2026-06-03 05:49:09'),
(251, 206, '/uploads/products/gallery_6a1fc20f686b05.77274851.jpg', 1, 1, '2026-06-03 05:57:48'),
(252, 206, '/uploads/products/gallery_6a1fc20f687769.69277781.jpg', 0, 2, '2026-06-03 05:57:48'),
(253, 207, '/uploads/products/gallery_6a1fc26c6f3565.40525724.jpg', 1, 1, '2026-06-03 05:59:17'),
(254, 207, '/uploads/products/gallery_6a1fc26c73eab4.77739754.jpg', 0, 2, '2026-06-03 05:59:17'),
(255, 208, '/uploads/products/gallery_6a1fc2c99e37c4.08719517.jpg', 1, 1, '2026-06-03 06:00:31'),
(256, 208, '/uploads/products/gallery_6a1fc2c99e3ed0.21800630.jpg', 0, 2, '2026-06-03 06:00:31'),
(257, 209, '/uploads/products/gallery_6a1fc3166abef0.55911271.jpg', 1, 1, '2026-06-03 06:01:54'),
(258, 209, '/uploads/products/gallery_6a1fc3166ab617.30923718.jpg', 0, 2, '2026-06-03 06:01:54'),
(259, 210, '/uploads/products/gallery_6a1fc35e372b63.94821883.jpg', 1, 1, '2026-06-03 06:03:15'),
(260, 210, '/uploads/products/gallery_6a1fc35e3722e4.89266108.jpg', 0, 2, '2026-06-03 06:03:15'),
(261, 211, '/uploads/products/gallery_6a1fc3e1234574.52928678.jpg', 1, 1, '2026-06-03 06:05:35'),
(262, 212, '/uploads/products/gallery_6a1fc4458abaf9.41727613.jpg', 1, 1, '2026-06-03 06:07:37'),
(263, 213, '/uploads/products/gallery_6a1fc4ba3ba9e6.76342940.jpg', 1, 1, '2026-06-03 06:09:01'),
(264, 214, '/uploads/products/gallery_6a1fc5087faa55.77557343.jpg', 1, 1, '2026-06-03 06:10:21'),
(265, 214, '/uploads/products/gallery_6a1fc5087fb683.67473641.jpg', 0, 2, '2026-06-03 06:10:21'),
(266, 215, '/uploads/products/gallery_6a1fc5560a4578.58270086.jpg', 1, 1, '2026-06-03 06:11:29'),
(267, 215, '/uploads/products/gallery_6a1fc5560a4d30.80685645.jpg', 0, 2, '2026-06-03 06:11:29'),
(268, 216, '/uploads/products/gallery_6a1fc5aa58d8e5.37567362.jpg', 1, 1, '2026-06-03 06:12:50'),
(269, 216, '/uploads/products/gallery_6a1fc5aa58c8c8.92120773.jpg', 0, 2, '2026-06-03 06:12:50'),
(270, 217, '/uploads/products/gallery_6a1fc68ed6b745.51540438.jpg', 1, 1, '2026-06-03 06:17:00'),
(271, 218, '/uploads/products/gallery_6a1fc700973889.43893077.jpg', 1, 1, '2026-06-03 06:18:52'),
(272, 218, '/uploads/products/gallery_6a1fc7020e6944.86012477.jpg', 0, 2, '2026-06-03 06:18:52'),
(273, 219, '/uploads/products/gallery_6a1fc7866910c4.30861572.jpg', 1, 1, '2026-06-03 06:21:00'),
(274, 219, '/uploads/products/gallery_6a1fc786690eb7.46762961.jpg', 0, 2, '2026-06-03 06:21:00'),
(275, 220, '/uploads/products/gallery_6a1fc7e0c84743.53436672.jpg', 1, 1, '2026-06-03 06:22:33'),
(276, 221, '/uploads/products/gallery_6a1fc83607a528.06215769.jpg', 1, 1, '2026-06-03 06:23:50');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_specs`
--

CREATE TABLE `product_specs` (
  `product_id` int NOT NULL,
  `phong_cach` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `khong_gian_lap_dat` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bong_den` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dien_ap` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `chat_lieu` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tinh_trang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tuoi_tho` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kich_thuoc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_specs`
--

INSERT INTO `product_specs` (`product_id`, `phong_cach`, `khong_gian_lap_dat`, `bong_den`, `dien_ap`, `chat_lieu`, `tinh_trang`, `tuoi_tho`, `kich_thuoc`) VALUES
(76, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '120 x 150'),
(77, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '100 x 145'),
(78, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '70 x 100'),
(79, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 80'),
(80, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 75'),
(81, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim', 'Mới 100%', '50000', '30 x 70'),
(82, 'Hiện Đại', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Hợp Kim, Acrylic', 'Mới 100%', '50000', '40 x 90'),
(83, 'Hiện Đại', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '35 x 80'),
(84, 'Hiện Đại', 'Phòng ngủ, Phòng ăn', 'LED', '220v', 'Hợp Kim, Chao vải', 'Mới 100%', '50000', '50 x 70'),
(85, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '70 x 80'),
(86, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '30 x 70'),
(87, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '40 x 60'),
(88, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '30x70'),
(89, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Chao vải, Đá cẩm thạch', 'Mới 100%', '50000', '45x90'),
(90, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '40x60'),
(91, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng, Đá cẩm thạch', 'Mới 100%', '50000', '30 x 70'),
(92, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '45 x 70'),
(93, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '30 x 50'),
(94, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 80'),
(95, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 75'),
(96, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '30 x 40'),
(97, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '35 x 45'),
(98, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Acrylic', 'Mới 100%', '50000', '25 x 35'),
(99, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '32 x 42'),
(100, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 40'),
(101, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 70'),
(102, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng, Pha Lê, Chao vải', 'Mới 100%', '50000', '30 x 70'),
(103, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '45 x 70'),
(104, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '30 x 50'),
(105, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Gốm', 'Mới 100%', '50000', '50 x 80'),
(106, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 75'),
(107, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '12x25'),
(108, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '15x32'),
(109, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '18x35'),
(110, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '14x28'),
(111, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '20x40'),
(112, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '15x35'),
(113, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '18x38'),
(114, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '20x40'),
(115, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Gốm, Chao vải', 'Mới 100%', '50000', '15x30'),
(120, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê, Chao vải', 'Mới 100%', '50000', '35x60'),
(121, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 70'),
(122, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '45 x 70'),
(123, 'Cổ Điển', 'Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 50'),
(124, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 80'),
(125, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 75'),
(126, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 70'),
(127, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '70x120'),
(128, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '70x120'),
(130, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '100x125'),
(132, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '75x125'),
(133, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh, Nhựa ABS', 'Mới 100%', '50000', '100x40'),
(134, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '107x45'),
(135, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '100x40'),
(136, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '110x45'),
(137, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '107x45'),
(138, 'Cổ Điển', 'Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '60 x 100'),
(139, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 80'),
(140, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 80'),
(141, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '50 x 90'),
(142, 'Cổ Điển', 'Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 75'),
(143, 'Cổ Điển', 'Phòng ngủ, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 75'),
(144, 'Cổ Điển', 'Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '45 x 60'),
(145, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 70'),
(146, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '45 x 65'),
(147, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 75'),
(148, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '45 x 65'),
(149, 'Cổ Điển', 'Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 50'),
(150, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 80'),
(151, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 80'),
(152, 'Cổ Điển', 'Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 75'),
(153, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '60 x 90'),
(154, 'Cổ Điển', 'Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 50'),
(155, 'Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 80'),
(156, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 80'),
(157, 'Cổ Điển', 'Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '50 x 75'),
(158, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 90'),
(159, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '45 x 70'),
(160, 'Cổ Điển', 'Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '40 x 50'),
(161, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '40 x 50'),
(162, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 60'),
(163, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '35 x 80'),
(164, 'Cổ Điển', 'Phòng khách', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 50'),
(165, 'Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 80'),
(166, 'Cổ Điển', 'Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 80'),
(167, 'Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '50 x 75'),
(168, 'Hiện Đại', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '40 x100'),
(169, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '70 x 70'),
(170, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '65 x 55'),
(171, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '65 x 55'),
(172, 'Hiện Đại', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '60 x 80 '),
(173, 'Hiện Đại', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '40 x 80'),
(174, 'Hiện Đại', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '60 x 40'),
(175, 'Hiện Đại', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '30 x 80'),
(176, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '60 x 60'),
(177, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '60 x 60'),
(178, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim', 'Mới 100%', '50000', '65 x 55'),
(179, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '28 x 38'),
(180, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '25 x 40'),
(181, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '30 x 45'),
(182, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '32 x 40'),
(183, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải, Thủy tinh', 'Mới 100%', '50000', '50 x 70'),
(184, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '60 x 80'),
(185, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '45 x 65'),
(186, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '70 x 100'),
(187, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '55 x 75'),
(188, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Tre', 'Mới 100%', '50000', '30 x 40'),
(189, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '16 x 30'),
(190, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '15 x 35'),
(191, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '13 x 27'),
(192, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '19 x 38'),
(193, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '17 x 33'),
(194, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '25 x 45'),
(195, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Chao vải', 'Mới 100%', '50000', '30 x 55'),
(196, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Gốm, Chao vải', 'Mới 100%', '50000', '22 x 40'),
(197, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '35 x 65'),
(198, 'Hiện Đại', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '28 x 50'),
(199, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '45 x 90'),
(200, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '35 x 75'),
(201, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Thủy tinh', 'Mới 100%', '50000', '45 x 90'),
(202, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn', 'LED', '220v', 'Đồng', 'Mới 100%', '50000', '60 x 90'),
(203, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '65 x 90'),
(204, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '55 x 90'),
(205, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Đồng, Pha Lê', 'Mới 100%', '50000', '45 x 90'),
(206, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '110 x 145'),
(207, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '110 x 145'),
(208, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Thủy tinh', 'Mới 100%', '50000', '110 x 145'),
(209, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Acrylic', 'Mới 100%', '50000', '150 x 200'),
(210, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Vải', 'Mới 100%', '50000', '145 x 225'),
(211, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê, Nhựa ABS', 'Mới 100%', '50000', '142 x 70'),
(212, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Gỗ', 'Mới 100%', '50000', '132 x 60'),
(213, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Vải', 'Mới 100%', '50000', '152 x 75'),
(214, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Nhựa ABS', 'Mới 100%', '50000', '142 x 65'),
(215, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '132 x 60'),
(216, 'Tân Cổ Điển', 'Phòng khách, Phòng ăn, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '132 x 60'),
(217, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Vải', 'Mới 100%', '50000', '35 x 60'),
(218, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê, Vải', 'Mới 100%', '50000', '45 x 85'),
(219, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Pha Lê', 'Mới 100%', '50000', '50 x 90'),
(220, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Đá cẩm thạch', 'Mới 100%', '50000', '15 x 30'),
(221, 'Tân Cổ Điển', 'Phòng khách, Phòng ngủ', 'LED', '220v', 'Hợp Kim, Acrylic', 'Mới 100%', '50000', '18 x 35');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `product_variants`
--

CREATE TABLE `product_variants` (
  `id` int NOT NULL,
  `product_id` int NOT NULL,
  `kich_thuoc` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `anh_sang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cost_price` decimal(15,2) DEFAULT '0.00',
  `price` decimal(15,2) NOT NULL,
  `stock` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `product_variants`
--

INSERT INTO `product_variants` (`id`, `product_id`, `kich_thuoc`, `anh_sang`, `cost_price`, `price`, `stock`, `created_at`) VALUES
(101, 101, '30 x 70', 'Vàng Trắng', 800000.00, 1500000.00, 2, '2026-04-09 12:13:38'),
(102, 101, '30 x 70', '3 Màu', 800000.00, 1500000.00, 2, '2026-04-09 12:13:38'),
(103, 101, '50 x 120', 'Vàng Trắng', 999999.00, 1600000.00, 2, '2026-04-09 12:13:38'),
(104, 101, '50 x 120', '3 Màu', 999999.00, 1600000.00, 2, '2026-04-09 12:13:38'),
(105, 102, '30 x 70', 'Vàng Trắng', 550000.00, 1000000.00, 2, '2026-04-09 13:20:43'),
(106, 102, '30 x 70', '3 Màu', 550000.00, 1000000.00, 2, '2026-04-09 13:20:43'),
(107, 103, '45 x 70', 'Vàng Trắng', 450000.00, 960000.00, 2, '2026-04-09 13:22:57'),
(108, 104, '30 x 50', 'Vàng Trắng', 530000.00, 860000.00, 2, '2026-04-09 13:28:15'),
(109, 104, '30 x 50', '3 Màu', 530000.00, 860000.00, 2, '2026-04-09 13:28:15'),
(110, 104, '40 x 60', 'Vàng Trắng', 600000.00, 1000000.00, 2, '2026-04-09 13:28:15'),
(111, 104, '40 x 60', '3 Màu', 600000.00, 1000000.00, 2, '2026-04-09 13:28:15'),
(112, 105, '50 x 80', 'Vàng Trắng', 780000.00, 960000.00, 2, '2026-04-09 13:29:58'),
(113, 105, '50 x 80', '3 Màu', 780000.00, 960000.00, 2, '2026-04-09 13:29:58'),
(114, 105, '60 x 90', 'Vàng Trắng', 930000.00, 1150000.00, 2, '2026-04-09 13:29:58'),
(115, 105, '60 x 90', 'Vàng Trắng', 930000.00, 1150000.00, 2, '2026-04-09 13:29:58'),
(116, 106, '60 x 75', 'Vàng Trắng', 970000.00, 1200000.00, 2, '2026-04-09 13:30:59'),
(141, 113, '18x38', 'Vàng Trắng', 890000.00, 1150000.00, 2, '2026-04-09 13:46:38'),
(142, 113, '18x38', '3 Màu', 890000.00, 1150000.00, 2, '2026-04-09 13:46:38'),
(143, 113, '22x45', 'Vàng Trắng', 990000.00, 1250000.00, 2, '2026-04-09 13:46:38'),
(144, 113, '22x45', '3 Màu', 990000.00, 1250000.00, 2, '2026-04-09 13:46:38'),
(145, 112, '15x35', 'Vàng trắng ', 850000.00, 1200000.00, 2, '2026-04-09 13:46:52'),
(146, 112, '15x35', '3 Màu', 850000.00, 1200000.00, 2, '2026-04-09 13:46:52'),
(147, 112, '20x40', 'Vàng trắng ', 950000.00, 1350000.00, 2, '2026-04-09 13:46:52'),
(148, 112, '20x40', '3 Màu', 950000.00, 1350000.00, 2, '2026-04-09 13:46:52'),
(149, 114, '20x40', 'Vàng Trắng', 920000.00, 1250000.00, 2, '2026-04-09 13:49:03'),
(150, 114, '20x40', '3 Màu', 920000.00, 1250000.00, 2, '2026-04-09 13:49:03'),
(151, 114, '25x50', 'Vàng Trắng', 999000.00, 1400000.00, 2, '2026-04-09 13:49:03'),
(152, 114, '25x50', '3 Màu', 999000.00, 1400000.00, 2, '2026-04-09 13:49:03'),
(153, 115, '15x30', 'Vàng Trắng', 790000.00, 1100000.00, 2, '2026-04-09 13:51:03'),
(154, 115, '15x30', '3 Màu', 790000.00, 1100000.00, 2, '2026-04-09 13:51:03'),
(155, 115, '18x35', 'Vàng Trắng', 880000.00, 1200000.00, 2, '2026-04-09 13:51:03'),
(156, 115, '18x35', '3 Màu', 880000.00, 1200000.00, 2, '2026-04-09 13:51:03'),
(157, 120, '35x60', 'Vàng Trắng', 5500000.00, 6800000.00, 2, '2026-04-09 14:08:41'),
(158, 120, '35x60', '3 Màu', 5500000.00, 6800000.00, 2, '2026-04-09 14:08:41'),
(159, 120, '40x70', 'Vàng Trắng', 6200000.00, 7500000.00, 2, '2026-04-09 14:08:41'),
(160, 120, '40x70', '3 Màu', 6200000.00, 7500000.00, 2, '2026-04-09 14:08:41'),
(163, 121, '30 x 70', 'Vàng Trắng', 550000.00, 1000000.00, 1, '2026-04-09 15:56:34'),
(164, 121, '30 x 70', '3 Màu', 550000.00, 1000000.00, 2, '2026-04-09 15:56:34'),
(165, 122, '45 x 70', 'Vàng Trắng', 450000.00, 960000.00, 2, '2026-04-15 10:39:53'),
(166, 122, '45 x 70', '3 Màu', 450000.00, 960000.00, 2, '2026-04-15 10:39:53'),
(167, 123, '30 x 50', 'Vàng Trắng', 530000.00, 860000.00, 2, '2026-04-15 10:41:41'),
(168, 123, '30 x 50', '3 Màu', 530000.00, 860000.00, 2, '2026-04-15 10:41:41'),
(169, 124, '50 x 80', 'Vàng Trắng', 780000.00, 960000.00, 2, '2026-04-15 10:43:04'),
(170, 125, '60 x 75', 'Vàng Trắng', 970000.00, 1200000.00, 2, '2026-04-15 10:44:10'),
(171, 125, '60 x 75', '3 Màu', 970000.00, 1200000.00, 2, '2026-04-15 10:44:10'),
(172, 126, '50 x 70', 'Vàng Trắng', 899000.00, 1200000.00, 2, '2026-04-15 10:48:30'),
(173, 126, '50 x 70', '3 Màu', 899000.00, 1200000.00, 2, '2026-04-15 10:48:30'),
(174, 126, '90 x 120', 'Vàng Trắng', 999000.00, 1400000.00, 2, '2026-04-15 10:48:30'),
(175, 126, '90 x 120', '3 Màu', 999000.00, 1400000.00, 2, '2026-04-15 10:48:30'),
(176, 127, '70x120', 'Vàng Trắng', 4500000.00, 5500000.00, 2, '2026-04-15 10:49:55'),
(177, 127, '70x120', '3 Màu', 4500000.00, 5500000.00, 2, '2026-04-15 10:49:55'),
(178, 127, '90x150', 'Vàng Trắng', 5700000.00, 6000000.00, 2, '2026-04-15 10:49:55'),
(179, 127, '90x150', '3 Màu', 5700000.00, 6000000.00, 2, '2026-04-15 10:49:55'),
(180, 128, '70x120', 'Vàng Trắng', 4600000.00, 5500000.00, 2, '2026-04-15 10:51:24'),
(181, 128, '70x120', '3 Màu', 4600000.00, 5500000.00, 2, '2026-04-15 10:51:24'),
(182, 128, '90x150', 'Vàng Trắng', 5300000.00, 5900000.00, 2, '2026-04-15 10:51:24'),
(183, 128, '90x150', '3 Màu', 5300000.00, 5900000.00, 2, '2026-04-15 10:51:24'),
(186, 130, '100x125', 'Vàng Trắng', 11500000.00, 12000000.00, 2, '2026-04-15 10:54:44'),
(187, 130, '100x125', '3 Màu', 11500000.00, 12000000.00, 2, '2026-04-15 10:54:44'),
(188, 130, '110x150', 'Vàng Trắng', 13000000.00, 13500000.00, 2, '2026-04-15 10:54:44'),
(189, 130, '110x150', '3 Màu', 13000000.00, 13500000.00, 2, '2026-04-15 10:54:44'),
(192, 132, '75x125', 'Vàng Trắng', 6000000.00, 6500000.00, 2, '2026-04-15 10:58:13'),
(193, 132, '85x135', 'Vàng Trắng', 6000000.00, 6500000.00, 2, '2026-04-15 10:58:13'),
(198, 134, '107x45', 'Vàng Trắng', 750000.00, 950000.00, 2, '2026-04-15 11:05:03'),
(199, 134, '107x45', '3 Màu', 750000.00, 950000.00, 2, '2026-04-15 11:05:03'),
(200, 134, '122x55', 'Vàng Trắng', 850000.00, 1100000.00, 2, '2026-04-15 11:05:03'),
(201, 134, '122x55', '3 Màu', 850000.00, 1100000.00, 2, '2026-04-15 11:05:03'),
(202, 133, '100x40', 'Vàng Trắng', 890000.00, 1200000.00, 1, '2026-04-15 11:05:26'),
(203, 133, '100x40', '3 Màu', 890000.00, 1200000.00, 2, '2026-04-15 11:05:26'),
(204, 133, '115x50', 'Vàng Trắng', 950000.00, 1300000.00, 2, '2026-04-15 11:05:26'),
(205, 133, '115x50', '3 Màu', 950000.00, 1300000.00, 2, '2026-04-15 11:05:26'),
(206, 135, '100x40', 'Vàng Trắng', 680000.00, 850000.00, 2, '2026-04-15 11:06:51'),
(207, 135, '100x40', '3 Màu', 680000.00, 850000.00, 2, '2026-04-15 11:06:51'),
(208, 135, '110x50', 'Vàng Trắng', 790000.00, 950000.00, 2, '2026-04-15 11:06:51'),
(209, 135, '110x50', '3 Màu', 790000.00, 950000.00, 2, '2026-04-15 11:06:51'),
(210, 136, '110x45', 'Vàng Trắng', 820000.00, 990000.00, 2, '2026-04-15 11:08:18'),
(211, 136, '110x45', '3 Màu', 820000.00, 990000.00, 2, '2026-04-15 11:08:18'),
(212, 136, '122x55', 'Vàng Trắng', 950000.00, 1150000.00, 2, '2026-04-15 11:08:18'),
(213, 136, '122x55', '3 Màu', 950000.00, 1150000.00, 2, '2026-04-15 11:08:18'),
(230, 76, '120 x 150', 'Trắng', 7999000.00, 10000000.00, 15, '2026-05-27 14:38:12'),
(231, 76, '150 x 170', 'Vàng', 8500000.00, 13000000.00, 15, '2026-05-27 14:38:12'),
(232, 138, '60 x 100', 'Vàng Trắng', 5750000.00, 6500000.00, 2, '2026-05-27 15:01:16'),
(233, 138, '60 x 100', '3 Màu', 5750000.00, 6500000.00, 2, '2026-05-27 15:01:16'),
(234, 137, '107x45', 'Vàng Trắng', 699000.00, 890000.00, 0, '2026-05-27 15:16:00'),
(235, 137, '107x45', '3 Màu', 699000.00, 890000.00, 2, '2026-05-27 15:16:00'),
(236, 137, '122x55', 'Vàng Trắng', 820000.00, 990000.00, 2, '2026-05-27 15:16:00'),
(237, 137, '122x55', '3 Màu', 820000.00, 990000.00, 2, '2026-05-27 15:16:00'),
(246, 77, '100 x 145', 'Vàng Trắng', 6800000.00, 9000000.00, 2, '2026-06-03 03:36:05'),
(247, 77, '100 x 145', '3 Màu', 6800000.00, 9000000.00, 2, '2026-06-03 03:36:05'),
(248, 78, '70 x 100', 'Vàng Trắng', 4500000.00, 6000000.00, 2, '2026-06-03 03:36:08'),
(249, 78, '70 x 100', '3 Màu', 4500000.00, 6000000.00, 2, '2026-06-03 03:36:08'),
(250, 78, '100 x 130', 'Vàng Trắng', 5500000.00, 8000000.00, 2, '2026-06-03 03:36:08'),
(251, 78, '100 x 130', '3 Màu', 5500000.00, 8000000.00, 2, '2026-06-03 03:36:08'),
(252, 79, '50 x 80', 'Vàng Trắng', 4500000.00, 5000000.00, 2, '2026-06-03 03:36:35'),
(253, 79, '50 x 80', '3 Màu', 4500000.00, 5000000.00, 2, '2026-06-03 03:36:35'),
(254, 80, '60 x 75', 'Vàng Trắng', 4800000.00, 5000000.00, 2, '2026-06-03 03:37:01'),
(255, 80, '60 x 75', '3 Màu', 4800000.00, 5000000.00, 2, '2026-06-03 03:37:01'),
(256, 139, '60 x 80', 'Vàng Trắng', 4500000.00, 6000000.00, 2, '2026-06-03 03:39:16'),
(257, 139, '60 x 80', '3 Màu', 4500000.00, 6000000.00, 2, '2026-06-03 03:39:16'),
(258, 140, '60 x 80', 'Vàng Trắng', 7500000.00, 8000000.00, 2, '2026-06-03 03:40:54'),
(259, 140, '60 x 80', '3 Màu', 7500000.00, 8000000.00, 2, '2026-06-03 03:40:54'),
(260, 140, '90 x 130', 'Vàng Trắng', 9500000.00, 11000000.00, 2, '2026-06-03 03:40:54'),
(261, 140, '90 x 130', '3 Màu', 9500000.00, 11000000.00, 2, '2026-06-03 03:40:54'),
(264, 142, '50 x 75', 'Vàng Trắng', 4500000.00, 5000000.00, 2, '2026-06-03 03:43:28'),
(265, 142, '50 x 75', '3 Màu', 4500000.00, 5000000.00, 2, '2026-06-03 03:43:28'),
(266, 141, '50 x 90', 'Vàng Trắng', 6999000.00, 8000000.00, 2, '2026-06-03 03:44:32'),
(267, 141, '50 x 90', '3 Màu', 6999000.00, 8000000.00, 2, '2026-06-03 03:44:32'),
(268, 143, '50 x 75', 'Vàng Trắng', 4500000.00, 5000000.00, 2, '2026-06-03 03:45:46'),
(269, 143, '50 x 75', '3 Màu', 4500000.00, 5000000.00, 2, '2026-06-03 03:45:46'),
(270, 144, '45 x 60', 'Vàng Trắng', 599000.00, 1000000.00, 2, '2026-06-03 03:52:04'),
(271, 144, '45 x 60', '3 Màu', 599000.00, 1000000.00, 2, '2026-06-03 03:52:04'),
(272, 144, '60 x 75', 'Vàng Trắng', 799000.00, 1200000.00, 2, '2026-06-03 03:52:04'),
(273, 144, '60 x 75', '3 Màu', 799000.00, 1200000.00, 2, '2026-06-03 03:52:04'),
(274, 145, '50 x 70', 'Vàng Trắng', 780000.00, 900000.00, 2, '2026-06-03 03:53:09'),
(275, 145, '50 x 70', '3 Màu', 780000.00, 900000.00, 2, '2026-06-03 03:53:09'),
(276, 146, '45 x 65', 'Vàng Trắng', 950000.00, 1300000.00, 2, '2026-06-03 03:55:01'),
(277, 146, '45 x 65', '3 Màu', 950000.00, 1300000.00, 2, '2026-06-03 03:55:01'),
(278, 147, '50 x 75', '', 650000.00, 980000.00, 2, '2026-06-03 03:56:48'),
(279, 147, '50 x 75', '', 650000.00, 980000.00, 2, '2026-06-03 03:56:48'),
(280, 147, '60 x 80', '', 890000.00, 1350000.00, 2, '2026-06-03 03:56:48'),
(281, 147, '60 x 80', '', 890000.00, 1350000.00, 2, '2026-06-03 03:56:48'),
(282, 148, '45 x 65', 'Vàng Trắng', 660000.00, 750000.00, 2, '2026-06-03 03:57:48'),
(283, 148, '45 x 65', '3 Màu', 660000.00, 750000.00, 2, '2026-06-03 03:57:48'),
(284, 91, '30 x 70', 'Vàng Trắng', 550000.00, 1000000.00, 2, '2026-06-03 03:59:36'),
(285, 91, '30 x 70', '3 Màu', 550000.00, 1000000.00, 2, '2026-06-03 03:59:36'),
(286, 92, '45 x 70', 'Vàng Trắng', 450000.00, 960000.00, 2, '2026-06-03 03:59:48'),
(287, 92, '45 x 70', '3 Màu', 450000.00, 960000.00, 2, '2026-06-03 03:59:48'),
(288, 93, '30 x 50', 'Vàng Trắng', 530000.00, 860000.00, 2, '2026-06-03 04:00:00'),
(289, 93, '30 x 50', '3 Màu', 530000.00, 860000.00, 2, '2026-06-03 04:00:00'),
(290, 93, '40 x 60', 'Vàng Trắng', 600000.00, 1000000.00, 2, '2026-06-03 04:00:00'),
(291, 93, '40 x 60', '3 Màu', 600000.00, 1000000.00, 2, '2026-06-03 04:00:00'),
(292, 94, '50 x 80', 'Vàng Trắng', 780000.00, 960000.00, 2, '2026-06-03 04:00:16'),
(293, 94, '50 x 80', '3 Màu', 780000.00, 960000.00, 2, '2026-06-03 04:00:16'),
(294, 94, '60 x 90', 'Vàng Trắng', 930000.00, 1150000.00, 2, '2026-06-03 04:00:16'),
(295, 94, '60 x 90', 'Vàng Trắng', 930000.00, 1150000.00, 2, '2026-06-03 04:00:16'),
(296, 95, '60 x 75', 'Vàng Trắng', 970000.00, 1200000.00, 2, '2026-06-03 04:00:24'),
(297, 95, '60 x 75', '3 Màu', 970000.00, 1200000.00, 2, '2026-06-03 04:00:24'),
(302, 149, '30 x 50', 'Vàng Trắng', 650000.00, 690000.00, 2, '2026-06-03 04:02:12'),
(303, 149, '30 x 50', '3 Màu', 650000.00, 690000.00, 2, '2026-06-03 04:02:12'),
(304, 149, '45 x 75', 'Vàng Trắng', 820000.00, 960000.00, 2, '2026-06-03 04:02:12'),
(305, 149, '45 x 75', '3 Màu', 820000.00, 960000.00, 2, '2026-06-03 04:02:12'),
(306, 150, '60 x 80', 'Vàng Trắng', 430000.00, 450000.00, 2, '2026-06-03 04:03:15'),
(307, 150, '60 x 80', '3 Màu', 430000.00, 450000.00, 2, '2026-06-03 04:03:15'),
(308, 151, '60 x 80', '', 630000.00, 650000.00, 2, '2026-06-03 04:04:31'),
(309, 151, '60 x 80', '', 630000.00, 650000.00, 2, '2026-06-03 04:04:31'),
(310, 151, '70 x 90', '', 720000.00, 750000.00, 2, '2026-06-03 04:04:31'),
(311, 151, '70 x 90', '', 720000.00, 750000.00, 2, '2026-06-03 04:04:31'),
(312, 152, '50 x 75', 'Vàng Trắng', 660000.00, 780000.00, 2, '2026-06-03 04:05:38'),
(313, 152, '50 x 75', '3 Màu', 660000.00, 780000.00, 2, '2026-06-03 04:05:38'),
(314, 153, '60 x 90', 'Vàng Trắng', 2750000.00, 3350000.00, 2, '2026-06-03 04:06:40'),
(315, 153, '60 x 90', '3 Màu', 2750000.00, 3350000.00, 2, '2026-06-03 04:06:40'),
(316, 154, '30 x 50', 'Vàng Trắng', 650000.00, 690000.00, 2, '2026-06-03 04:10:09'),
(317, 154, '30 x 50', '3 Màu', 650000.00, 690000.00, 2, '2026-06-03 04:10:09'),
(318, 154, '45 x 75', 'Vàng Trắng', 820000.00, 960000.00, 2, '2026-06-03 04:10:09'),
(319, 154, '45 x 75', '3 Màu', 820000.00, 960000.00, 2, '2026-06-03 04:10:09'),
(320, 155, '60 x 80', 'Vàng Trắng', 430000.00, 450000.00, 2, '2026-06-03 04:11:15'),
(321, 155, '60 x 80', ' 3 Màu', 430000.00, 450000.00, 2, '2026-06-03 04:11:15'),
(322, 156, '60 x 80', 'Vàng Trắng', 630000.00, 650000.00, 2, '2026-06-03 04:12:34'),
(323, 156, '60 x 80', '3 Màu', 630000.00, 650000.00, 2, '2026-06-03 04:12:34'),
(324, 156, '70 x 90', 'Vàng Trắng', 720000.00, 750000.00, 2, '2026-06-03 04:12:34'),
(325, 156, '70 x 90', '3 Màu', 720000.00, 750000.00, 2, '2026-06-03 04:12:34'),
(326, 157, '50 x 75', 'Vàng Trắng', 660000.00, 780000.00, 2, '2026-06-03 04:13:38'),
(327, 157, '50 x 75', '3 Màu', 660000.00, 780000.00, 2, '2026-06-03 04:13:38'),
(328, 158, '60 x 90', 'Vàng Trắng', 350000.00, 650000.00, 2, '2026-06-03 04:14:48'),
(329, 158, '60 x 90', ' 3 Màu', 350000.00, 650000.00, 2, '2026-06-03 04:14:48'),
(330, 159, '45 x 70', 'Vàng Trắng', 1350000.00, 1700000.00, 2, '2026-06-03 04:15:41'),
(331, 159, '45 x 70', '3 Màu', 1350000.00, 1700000.00, 2, '2026-06-03 04:15:41'),
(332, 160, '40 x 50', 'Vàng Trắng', 1275000.00, 1850000.00, 2, '2026-06-03 04:17:09'),
(333, 160, '40 x 50', ' 3 Màu', 1275000.00, 1850000.00, 2, '2026-06-03 04:17:09'),
(334, 160, '50 x 60', 'Vàng Trắng', 1275000.00, 2100000.00, 2, '2026-06-03 04:17:09'),
(335, 160, '50 x 60', ' 3 Màu', 1275000.00, 1750000.00, 2, '2026-06-03 04:17:09'),
(336, 161, '40 x 50', 'Vàng Trắng', 1600000.00, 2550000.00, 2, '2026-06-03 04:19:40'),
(337, 161, '40 x 50', '3 Màu', 1600000.00, 2550000.00, 2, '2026-06-03 04:19:40'),
(338, 162, '60 x 60', 'Vàng Trắng', 3300000.00, 4225000.00, 2, '2026-06-03 04:20:30'),
(339, 162, '60 x 60', ' 3 Màu', 3300000.00, 4225000.00, 2, '2026-06-03 04:20:30'),
(340, 163, '35 x 80', 'Vàng Trắng', 2850000.00, 3650000.00, 2, '2026-06-03 04:21:26'),
(341, 163, '35 x 80', '3 Màu', 2850000.00, 3650000.00, 2, '2026-06-03 04:21:26'),
(342, 164, '30 x 50', 'Vàng Trắng', 650000.00, 690000.00, 2, '2026-06-03 04:24:43'),
(343, 164, '30 x 50', '3 Màu', 650000.00, 690000.00, 2, '2026-06-03 04:24:43'),
(344, 165, '60 x 80', 'Vàng Trắng', 430000.00, 450000.00, 2, '2026-06-03 04:25:42'),
(345, 165, '60 x 80', ' 3 Màu', 430000.00, 450000.00, 2, '2026-06-03 04:25:42'),
(346, 166, '60 x 80', 'Vàng Trắng', 630000.00, 650000.00, 2, '2026-06-03 04:26:59'),
(347, 166, '60 x 80', '3 Màu', 630000.00, 650000.00, 2, '2026-06-03 04:26:59'),
(348, 167, '50 x 75', 'Vàng Trắng', 660000.00, 780000.00, 2, '2026-06-03 04:27:53'),
(349, 167, '50 x 75', '3 Màu', 660000.00, 780000.00, 2, '2026-06-03 04:27:53'),
(362, 81, '30 x 70', 'Vàng', 699000.00, 899000.00, 2, '2026-06-03 04:31:08'),
(363, 81, '30 x 70', 'Trắng', 699000.00, 899000.00, 2, '2026-06-03 04:31:08'),
(364, 81, '45 x 120', 'Vàng', 799000.00, 999000.00, 2, '2026-06-03 04:31:08'),
(365, 81, '45 x 120', 'Trắng', 799000.00, 999000.00, 2, '2026-06-03 04:31:08'),
(366, 82, '40 x 90', 'Trắng', 699000.00, 799000.00, 2, '2026-06-03 04:31:32'),
(367, 82, '40 x 90', 'Vàng', 699000.00, 799000.00, 2, '2026-06-03 04:31:32'),
(368, 82, '50 x 120', 'Trắng', 799000.00, 899000.00, 2, '2026-06-03 04:31:32'),
(369, 82, '50 x 120', 'Vàng', 799000.00, 899000.00, 2, '2026-06-03 04:31:32'),
(370, 83, '35 x 80', 'Trắng', 799000.00, 899000.00, 0, '2026-06-03 04:31:43'),
(371, 83, '35 x 80', 'Vàng', 799000.00, 899000.00, 2, '2026-06-03 04:31:43'),
(372, 83, '45 x 120 ', 'Trắng', 899000.00, 999000.00, 2, '2026-06-03 04:31:43'),
(373, 83, '45 x 120 ', 'Vàng', 899000.00, 999000.00, 2, '2026-06-03 04:31:43'),
(374, 84, '50 x 70', 'Trắng', 599000.00, 699000.00, 2, '2026-06-03 04:31:58'),
(375, 84, '50 x 70', 'Vàng', 599000.00, 699000.00, 2, '2026-06-03 04:31:58'),
(376, 84, '80 x 110', 'Trắng', 699000.00, 899000.00, 2, '2026-06-03 04:31:58'),
(377, 84, '80 x 110', 'Vàng', 699000.00, 899000.00, 2, '2026-06-03 04:31:58'),
(378, 85, '70 x 80', 'Vàng', 799000.00, 899000.00, 2, '2026-06-03 04:32:07'),
(379, 85, '70 x 80', '3 Màu', 799000.00, 899000.00, 2, '2026-06-03 04:32:07'),
(380, 85, '90 x 100', 'Vàng', 899000.00, 999000.00, 2, '2026-06-03 04:32:07'),
(381, 85, '90 x 100', '3 Màu', 899000.00, 999000.00, 2, '2026-06-03 04:32:07'),
(406, 171, '65 x 55', 'Vàng Trắng', 799000.00, 899000.00, 2, '2026-06-03 04:42:17'),
(407, 171, '65 x 55', '3 Màu', 799000.00, 899000.00, 2, '2026-06-03 04:42:17'),
(408, 171, '85 x 60', 'Vàng Trắng', 799000.00, 899000.00, 2, '2026-06-03 04:42:17'),
(409, 171, '85 x 60', '3 Màu', 799000.00, 899000.00, 2, '2026-06-03 04:42:17'),
(410, 168, '40 x 100', 'Vàng Trắng', 599000.00, 799000.00, 2, '2026-06-03 04:42:42'),
(411, 168, '40 x 100', '3 Màu', 599000.00, 799000.00, 2, '2026-06-03 04:42:42'),
(412, 168, '30 x 150 ', 'Vàng Trắng', 699000.00, 899000.00, 2, '2026-06-03 04:42:42'),
(413, 168, '30 x 150 ', '3 Màu', 699000.00, 899000.00, 2, '2026-06-03 04:42:42'),
(414, 169, '70 x 70', '', 599000.00, 699000.00, 2, '2026-06-03 04:42:48'),
(415, 169, '70 x 70', '', 599000.00, 699000.00, 2, '2026-06-03 04:42:48'),
(416, 169, '100 x 100', '', 699000.00, 899000.00, 2, '2026-06-03 04:42:48'),
(417, 169, '100 x 100', '', 699000.00, 899000.00, 2, '2026-06-03 04:42:48'),
(418, 170, '65 x 55', 'Vàng Trắng', 699000.00, 799000.00, 2, '2026-06-03 04:42:52'),
(419, 170, '65 x 55', '3 Màu', 699000.00, 799000.00, 2, '2026-06-03 04:42:52'),
(420, 170, '85 x 60', 'Vàng Trắng', 799000.00, 899000.00, 2, '2026-06-03 04:42:52'),
(421, 170, '85 x 60', '3 Màu', 799000.00, 899000.00, 2, '2026-06-03 04:42:52'),
(422, 172, '60 x 80 ', 'Vàng Trắng', 799000.00, 899000.00, 2, '2026-06-03 04:44:29'),
(423, 172, '60 x 80 ', '3 Màu', 799000.00, 899000.00, 2, '2026-06-03 04:44:29'),
(424, 172, '80 x 80', 'Vàng Trắng', 899000.00, 999000.00, 2, '2026-06-03 04:44:29'),
(425, 172, '80 x 80', '3 Màu', 899000.00, 999000.00, 2, '2026-06-03 04:44:29'),
(430, 173, '40 x 80', 'Vàng Trắng', 3200000.00, 3500000.00, 2, '2026-06-03 04:45:56'),
(431, 173, '40 x 80', '3 Màu', 3200000.00, 3500000.00, 2, '2026-06-03 04:45:56'),
(432, 173, '45 x 120 ', 'Vàng Trắng', 6700000.00, 7000000.00, 2, '2026-06-03 04:45:56'),
(433, 173, '45 x 120 ', '3 Màu', 6700000.00, 7000000.00, 2, '2026-06-03 04:45:56'),
(438, 174, '60 x 40', 'Vàng Trắng', 5000000.00, 5500000.00, 2, '2026-06-03 04:48:31'),
(439, 174, '60 x 40', '3 Màu', 5000000.00, 5500000.00, 2, '2026-06-03 04:48:31'),
(440, 174, '80 x 60', 'Vàng Trắng', 7900000.00, 8500000.00, 2, '2026-06-03 04:48:31'),
(441, 174, '80 x 60', '3 Màu', 7900000.00, 8500000.00, 2, '2026-06-03 04:48:31'),
(446, 175, '30 x 80', 'Vàng Trắng', 4000000.00, 4500000.00, 2, '2026-06-03 04:50:00'),
(447, 175, '30 x 80', '3 Màu', 4000000.00, 4500000.00, 2, '2026-06-03 04:50:00'),
(448, 175, '35 x 100', 'Vàng Trắng', 7000000.00, 7500000.00, 2, '2026-06-03 04:50:00'),
(449, 175, '35 x 100', '3 Màu', 7000000.00, 7500000.00, 2, '2026-06-03 04:50:00'),
(450, 176, '60 x 60', 'Vàng Trắng', 7500000.00, 8000000.00, 2, '2026-06-03 04:51:09'),
(451, 176, '60 x 60', '3 Màu', 7500000.00, 8000000.00, 2, '2026-06-03 04:51:09'),
(452, 176, '100 x 80', 'Vàng Trắng', 9000000.00, 9500000.00, 2, '2026-06-03 04:51:09'),
(453, 176, '100 x 80', '3 Màu', 9000000.00, 9500000.00, 2, '2026-06-03 04:51:09'),
(458, 177, '60 x 60', 'Vàng Trắng', 7500000.00, 8000000.00, 2, '2026-06-03 04:52:52'),
(459, 177, '60 x 60', '3 Màu', 7500000.00, 8000000.00, 2, '2026-06-03 04:52:52'),
(460, 177, '100 x 80', 'Vàng Trắng', 9000000.00, 9500000.00, 2, '2026-06-03 04:52:52'),
(461, 177, '100 x 80', '3 Màu', 9000000.00, 9500000.00, 2, '2026-06-03 04:52:52'),
(466, 178, '65 x 55', 'Vàng Trắng', 4000000.00, 4500000.00, 2, '2026-06-03 04:54:49'),
(467, 178, '65 x 55', '3 Màu', 4000000.00, 4500000.00, 2, '2026-06-03 04:54:49'),
(468, 178, '85 x 60', 'Vàng Trắng', 7000000.00, 7500000.00, 2, '2026-06-03 04:54:49'),
(469, 178, '85 x 60', '3 Màu', 7000000.00, 7500000.00, 2, '2026-06-03 04:54:49'),
(534, 96, '30 x 40', 'Vàng Trắng', 850000.00, 1250000.00, 2, '2026-06-03 05:10:10'),
(535, 96, '30 x 40', '3 Màu', 850000.00, 1250000.00, 2, '2026-06-03 05:10:10'),
(536, 96, '40 x 50', 'Vàng Trắng', 950000.00, 1350000.00, 2, '2026-06-03 05:10:10'),
(537, 96, '40 x 50', '3 Màu', 950000.00, 1350000.00, 2, '2026-06-03 05:10:10'),
(538, 97, '35 x 45', 'Vàng Trắng', 890000.00, 1180000.00, 2, '2026-06-03 05:10:13'),
(539, 97, '35 x 45', '3 Màu', 890000.00, 1180000.00, 2, '2026-06-03 05:10:13'),
(540, 97, '45 x 60', 'Vàng Trắng', 990000.00, 1280000.00, 2, '2026-06-03 05:10:13'),
(541, 97, '45 x 60', '3 Màu', 990000.00, 1280000.00, 2, '2026-06-03 05:10:13'),
(542, 98, '25 x 35', 'Vàng Trắng ', 750000.00, 1100000.00, 1, '2026-06-03 05:10:16'),
(543, 98, '25 x 35', '3 Màu', 750000.00, 1100000.00, 2, '2026-06-03 05:10:16'),
(544, 98, '30 x 45', 'Vàng Trắng ', 850000.00, 1200000.00, 2, '2026-06-03 05:10:16'),
(545, 98, '30 x 45', '3 Màu', 850000.00, 1200000.00, 2, '2026-06-03 05:10:16'),
(546, 99, '32 x 42', 'Vàng Trắng', 980000.00, 1300000.00, 2, '2026-06-03 05:10:19'),
(547, 99, '32 x 42', '3 Màu', 980000.00, 1300000.00, 2, '2026-06-03 05:10:19'),
(548, 99, '42 x 55', 'Vàng Trắng', 1050000.00, 1450000.00, 2, '2026-06-03 05:10:19'),
(549, 99, '42 x 55', '3 Màu', 1050000.00, 1450000.00, 2, '2026-06-03 05:10:19'),
(554, 100, '30 x 40', 'Vàng Trắng', 790000.00, 1050000.00, 1, '2026-06-03 05:10:24'),
(555, 100, '30 x 40', '3 Màu', 790000.00, 1050000.00, 2, '2026-06-03 05:10:24'),
(556, 100, '40 x 50', 'Vàng Trắng', 880000.00, 1150000.00, 2, '2026-06-03 05:10:24'),
(557, 100, '40 x 50', '3 Màu', 880000.00, 1150000.00, 2, '2026-06-03 05:10:24'),
(558, 179, '28 x 38', 'Vàng Trắng', 920000.00, 1220000.00, 2, '2026-06-03 05:10:29'),
(559, 179, '28 x 38', '3 Màu', 920000.00, 1220000.00, 2, '2026-06-03 05:10:29'),
(560, 179, '35 x 50', 'Vàng Trắng', 999000.00, 1320000.00, 2, '2026-06-03 05:10:29'),
(561, 179, '35 x 50', '3 Màu', 999000.00, 1320000.00, 2, '2026-06-03 05:10:29'),
(562, 180, '25 x 40', 'Vàng Trắng', 820000.00, 1120000.00, 2, '2026-06-03 05:10:36'),
(563, 180, '25 x 40', '3 Màu', 820000.00, 1120000.00, 2, '2026-06-03 05:10:36'),
(564, 180, '35 x 55', 'Vàng Trắng', 820000.00, 1120000.00, 4, '2026-06-03 05:10:36'),
(565, 180, '35 x 55', '3 Màu', 820000.00, 1120000.00, 8, '2026-06-03 05:10:36'),
(566, 181, '30 x 45', '', 950000.00, 1280000.00, 2, '2026-06-03 05:10:38'),
(567, 181, '30 x 45', '', 950000.00, 1280000.00, 2, '2026-06-03 05:10:38'),
(568, 181, '40 x 60', '', 1080000.00, 1380000.00, 2, '2026-06-03 05:10:38'),
(569, 181, '40 x 60', '', 1080000.00, 1380000.00, 2, '2026-06-03 05:10:38'),
(570, 182, '32 x 40', 'Vàng Trắng', 880000.00, 1150000.00, 2, '2026-06-03 05:12:26'),
(571, 182, '32 x 40', '3 Màu', 880000.00, 1150000.00, 2, '2026-06-03 05:12:26'),
(572, 182, '42 x 50', 'Vàng Trắng', 980000.00, 1250000.00, 2, '2026-06-03 05:12:26'),
(573, 182, '42 x 50', '3 Màu', 980000.00, 1250000.00, 2, '2026-06-03 05:12:26'),
(574, 183, '50 x 70', 'Vàng Trắng', 4200000.00, 5500000.00, 2, '2026-06-03 05:13:55'),
(575, 183, '50 x 70', '3 Màu', 4200000.00, 5500000.00, 2, '2026-06-03 05:13:55'),
(576, 183, '60 x 90', 'Vàng Trắng', 4900000.00, 6200000.00, 2, '2026-06-03 05:13:55'),
(577, 183, '60 x 90', '3 Màu', 4900000.00, 6200000.00, 2, '2026-06-03 05:13:55'),
(578, 184, '60 x 80', 'Vàng Trắng', 7200000.00, 8500000.00, 2, '2026-06-03 05:15:35'),
(579, 184, '60 x 80', '3 Màu', 7200000.00, 8500000.00, 2, '2026-06-03 05:15:35'),
(580, 184, '70 x 100', 'Vàng Trắng', 8200000.00, 9500000.00, 2, '2026-06-03 05:15:35'),
(581, 184, '70 x 100', '3 Màu', 8200000.00, 9500000.00, 2, '2026-06-03 05:15:35'),
(582, 185, '45 x 65', 'Vàng Trắng', 2900000.00, 3800000.00, 2, '2026-06-03 05:17:01'),
(583, 185, '45 x 65', '3 Màu', 2900000.00, 3800000.00, 2, '2026-06-03 05:17:01'),
(584, 185, '55 x 85', 'Vàng Trắng', 3500000.00, 4500000.00, 2, '2026-06-03 05:17:01'),
(585, 185, '55 x 85', '3 Màu', 3500000.00, 4500000.00, 2, '2026-06-03 05:17:01'),
(586, 186, '70 x 100', '', 8800000.00, 9900000.00, 2, '2026-06-03 05:18:14'),
(587, 186, '70 x 100', '', 8800000.00, 9900000.00, 2, '2026-06-03 05:18:14'),
(588, 186, '80x130', '', 9800000.00, 11500000.00, 2, '2026-06-03 05:18:14'),
(589, 186, '80x130', '', 9800000.00, 11500000.00, 2, '2026-06-03 05:18:14'),
(590, 187, '55 x 75', 'Vàng Trắng', 5500000.00, 6800000.00, 2, '2026-06-03 05:19:28'),
(591, 187, '55 x 75', '3 Màu', 5500000.00, 6800000.00, 2, '2026-06-03 05:19:28'),
(592, 187, '65 x 95', 'Vàng Trắng', 6200000.00, 7500000.00, 2, '2026-06-03 05:19:28'),
(593, 187, '65 x 95', '3 Màu', 6200000.00, 7500000.00, 2, '2026-06-03 05:19:28'),
(594, 188, '30 x 40', 'Vàng Trắng', 650000.00, 950000.00, 2, '2026-06-03 05:21:17'),
(595, 188, '30 x 40', '3 Màu', 650000.00, 950000.00, 2, '2026-06-03 05:21:17'),
(596, 188, '40 x 50', 'Vàng Trắng', 750000.00, 1100000.00, 2, '2026-06-03 05:21:17'),
(597, 188, '40 x 50', '3 Màu', 750000.00, 1100000.00, 2, '2026-06-03 05:21:17'),
(598, 107, '12x25', 'Vàng Trắng', 880000.00, 1250000.00, 2, '2026-06-03 05:21:58'),
(599, 107, '12x25', '3 Màu', 880000.00, 1250000.00, 2, '2026-06-03 05:21:58'),
(600, 107, '15x30', 'Vàng Trắng', 950000.00, 1350000.00, 2, '2026-06-03 05:21:58'),
(601, 107, '15x30', '3 Màu', 950000.00, 1350000.00, 2, '2026-06-03 05:21:58'),
(602, 108, '15x32', 'Vàng Trắng', 850000.00, 1180000.00, 2, '2026-06-03 05:22:03'),
(603, 108, '15x32', '3 Màu', 850000.00, 1180000.00, 2, '2026-06-03 05:22:03'),
(604, 108, '18x38', 'Vàng Trắng', 920000.00, 1280000.00, 2, '2026-06-03 05:22:03'),
(605, 108, '18x38', '3 Màu', 920000.00, 1280000.00, 2, '2026-06-03 05:22:03'),
(606, 109, '18x35', 'Vàng Trắng', 990000.00, 1300000.00, 2, '2026-06-03 05:22:07'),
(607, 109, '18x35', '3 Màu', 990000.00, 1300000.00, 2, '2026-06-03 05:22:07'),
(608, 109, '22x42', 'Vàng Trắng', 1050000.00, 1450000.00, 2, '2026-06-03 05:22:07'),
(609, 109, '22x42', '3 Màu', 1050000.00, 1450000.00, 2, '2026-06-03 05:22:07'),
(610, 110, '14x28', 'Vàng Trắng', 799000.00, 1100000.00, 2, '2026-06-03 05:22:11'),
(611, 110, '14x28', '3 Màu', 799000.00, 1100000.00, 2, '2026-06-03 05:22:11'),
(612, 110, '17x35', 'Vàng Trắng', 890000.00, 1200000.00, 2, '2026-06-03 05:22:11'),
(613, 110, '17x35', '3 Màu', 890000.00, 1200000.00, 2, '2026-06-03 05:22:11'),
(614, 111, '20x40', 'Vàng Trắng', 999000.00, 1350000.00, 2, '2026-06-03 05:22:16'),
(615, 111, '20x40', '3 Màu', 999000.00, 1350000.00, 2, '2026-06-03 05:22:16'),
(616, 111, '25x50', 'Vàng Trắng', 1150000.00, 1550000.00, 2, '2026-06-03 05:22:16'),
(617, 111, '25x50', '3 Màu', 1150000.00, 1550000.00, 2, '2026-06-03 05:22:16'),
(618, 189, '16 x 30', 'Vàng Trắng', 820000.00, 1150000.00, 2, '2026-06-03 05:23:42'),
(619, 189, '16 x 30', '3 Màu', 820000.00, 1150000.00, 2, '2026-06-03 05:23:42'),
(620, 189, '19 x 35', 'Vàng Trắng', 900000.00, 1250000.00, 2, '2026-06-03 05:23:42'),
(621, 189, '19 x 35', '3 Màu', 900000.00, 1250000.00, 2, '2026-06-03 05:23:42'),
(622, 190, '15 x 35', 'Vàng Trắng', 950000.00, 1220000.00, 2, '2026-06-03 05:25:09'),
(623, 190, '15 x 35', '3 Màu', 950000.00, 1220000.00, 2, '2026-06-03 05:25:09'),
(624, 190, '20 x 45', 'Vàng Trắng', 990000.00, 1380000.00, 2, '2026-06-03 05:25:09'),
(625, 190, '20 x 45', '3 Màu', 990000.00, 1380000.00, 2, '2026-06-03 05:25:09'),
(626, 191, '13 x 27', 'Vàng Trắng', 750000.00, 1050000.00, 2, '2026-06-03 05:26:22'),
(627, 191, '13 x 27', '3 Màu', 750000.00, 1050000.00, 2, '2026-06-03 05:26:22'),
(628, 191, '16 x 32', 'Vàng Trắng', 750000.00, 1050000.00, 2, '2026-06-03 05:26:22'),
(629, 191, '16 x 32', '3 Màu', 750000.00, 1050000.00, 2, '2026-06-03 05:26:22'),
(630, 192, '19 x 38', 'Vàng Trắng', 920000.00, 1280000.00, 2, '2026-06-03 05:27:33'),
(631, 192, '19 x 38', '3 Màu', 920000.00, 1280000.00, 2, '2026-06-03 05:27:33'),
(632, 192, '23 x 45', 'Vàng Trắng', 920000.00, 1280000.00, 2, '2026-06-03 05:27:33'),
(633, 192, '23 x 45', '3 Màu', 920000.00, 1280000.00, 2, '2026-06-03 05:27:33'),
(634, 193, '17 x 33', 'Vàng Trắng', 880000.00, 1190000.00, 2, '2026-06-03 05:29:09'),
(635, 193, '17 x 33', '3 Màu', 880000.00, 1190000.00, 2, '2026-06-03 05:29:09'),
(636, 193, '20 x 40', 'Vàng Trắng', 960000.00, 1290000.00, 2, '2026-06-03 05:29:09'),
(637, 193, '20 x 40', '3 Màu', 960000.00, 1290000.00, 2, '2026-06-03 05:29:09'),
(638, 194, '25 x 45', 'Vàng Trắng', 3900000.00, 4800000.00, 2, '2026-06-03 05:30:28'),
(639, 194, '25 x 45', '3 Màu', 3900000.00, 4800000.00, 2, '2026-06-03 05:30:28'),
(640, 194, '30 x 55', 'Vàng Trắng', 4500000.00, 5500000.00, 2, '2026-06-03 05:30:28'),
(641, 194, '30 x 55', '3 Màu', 4500000.00, 5500000.00, 2, '2026-06-03 05:30:28'),
(642, 195, '30 x 55', 'Vàng Trắng', 5200000.00, 6500000.00, 2, '2026-06-03 05:31:51'),
(643, 195, '30 x 55', '3 Màu', 5200000.00, 6500000.00, 2, '2026-06-03 05:31:51'),
(644, 195, '35 x 65', 'Vàng Trắng', 6100000.00, 7500000.00, 2, '2026-06-03 05:31:51'),
(645, 195, '35 x 65', '3 Màu', 6100000.00, 7500000.00, 2, '2026-06-03 05:31:51'),
(646, 196, '22 x 40', 'Vàng Trắng', 2800000.00, 3500000.00, 2, '2026-06-03 05:33:16'),
(647, 196, '22 x 40', '3 Màu', 2800000.00, 3500000.00, 2, '2026-06-03 05:33:16'),
(648, 196, '28 x 50', 'Vàng Trắng', 3300000.00, 4200000.00, 2, '2026-06-03 05:33:16'),
(649, 196, '28 x 50', '3 Màu', 3300000.00, 4200000.00, 2, '2026-06-03 05:33:16'),
(650, 197, '35 x 65', 'Vàng Trắng', 7800000.00, 9200000.00, 2, '2026-06-03 05:34:35'),
(651, 197, '35 x 65', '3 Màu', 7800000.00, 9200000.00, 2, '2026-06-03 05:34:35'),
(652, 197, '40 x 75', 'Vàng Trắng', 8900000.00, 10500000.00, 2, '2026-06-03 05:34:35'),
(653, 197, '40 x 75', '3 Màu', 8900000.00, 10500000.00, 2, '2026-06-03 05:34:35'),
(654, 198, '28 x 50', 'Vàng Trắng', 4500000.00, 5800000.00, 2, '2026-06-03 05:35:47'),
(655, 198, '28 x 50', '3 Màu', 4500000.00, 5800000.00, 2, '2026-06-03 05:35:47'),
(656, 198, '32 x 60', 'Vàng Trắng', 5200000.00, 6500000.00, 2, '2026-06-03 05:35:47'),
(657, 198, '32 x 60', '3 Màu', 5200000.00, 6500000.00, 2, '2026-06-03 05:35:47'),
(658, 86, '30 x 70', 'Vàng Trắng', 989000.00, 1500000.00, 2, '2026-06-03 05:37:49'),
(659, 86, '30 x 70', '3 Màu', 989000.00, 1500000.00, 2, '2026-06-03 05:37:49'),
(660, 86, '50 x 120', 'Vàng Trắng', 999000.00, 1600000.00, 2, '2026-06-03 05:37:49'),
(661, 86, '50 x 120', '3 Màu', 999000.00, 1600000.00, 2, '2026-06-03 05:37:49'),
(662, 87, '40 x 60', 'Vàng Trắng', 899000.00, 1200000.00, 1, '2026-06-03 05:37:57'),
(663, 87, '40 x 60', '3 Màu', 899000.00, 1200000.00, 2, '2026-06-03 05:37:57'),
(664, 87, '45x110', 'Vàng Trắng', 900000.00, 1350000.00, 2, '2026-06-03 05:37:57'),
(665, 87, '45x110', '3 Màu', 900000.00, 1350000.00, 2, '2026-06-03 05:37:57'),
(666, 88, '30x70', 'Vàng Trắng', 855000.00, 900000.00, 2, '2026-06-03 05:38:01'),
(667, 88, '30x70', '3 Màu', 855000.00, 900000.00, 2, '2026-06-03 05:38:01'),
(668, 88, '60x90', 'Vàng Trắng', 945000.00, 990000.00, 2, '2026-06-03 05:38:01'),
(669, 88, '60x90', '3 Màu', 945000.00, 990000.00, 2, '2026-06-03 05:38:01'),
(670, 89, '45x90', 'Vàng Trắng', 950000.00, 1100000.00, 2, '2026-06-03 05:38:06'),
(671, 89, '45x90', '3 Màu', 950000.00, 1100000.00, 2, '2026-06-03 05:38:06'),
(672, 89, '65x110', 'Vàng Trắng', 1000000.00, 1250000.00, 2, '2026-06-03 05:38:06'),
(673, 89, '65x110', '3 Màu', 1000000.00, 1250000.00, 2, '2026-06-03 05:38:06'),
(674, 90, '40x60', 'Vàng Trắng', 890000.00, 1200000.00, 1, '2026-06-03 05:38:11'),
(675, 90, '40x60', '3 Màu', 890000.00, 1200000.00, 2, '2026-06-03 05:38:11'),
(676, 90, '60x90', 'Vàng Trắng', 940000.00, 1250000.00, 2, '2026-06-03 05:38:11'),
(677, 90, '60x90', '3 Màu', 940000.00, 1250000.00, 2, '2026-06-03 05:38:11'),
(678, 199, '45 x 90', 'Vàng Trắng', 850000.00, 990000.00, 2, '2026-06-03 05:39:37'),
(679, 199, '45 x 90', '3 Màu', 850000.00, 990000.00, 2, '2026-06-03 05:39:37'),
(680, 199, '55 x 75', 'Vàng Trắng', 915000.00, 1150000.00, 2, '2026-06-03 05:39:37'),
(681, 199, '55 x 75', '3 Màu', 915000.00, 1150000.00, 2, '2026-06-03 05:39:37'),
(682, 200, '35 x 75', 'Vàng Trắng', 989000.00, 1500000.00, 2, '2026-06-03 05:41:31'),
(683, 200, '35 x 75', '3 Màu', 989000.00, 1500000.00, 2, '2026-06-03 05:41:31'),
(684, 200, '55 x 125', 'Vàng Trắng', 999999.00, 1600000.00, 2, '2026-06-03 05:41:31'),
(685, 200, '55 x 125', '3 Màu', 999999.00, 1600000.00, 2, '2026-06-03 05:41:31'),
(686, 201, '45 x 90', 'Vàng Trắng', 890000.00, 1250000.00, 2, '2026-06-03 05:42:59'),
(687, 201, '45 x 90', '3 Màu', 890000.00, 1250000.00, 2, '2026-06-03 05:42:59'),
(688, 201, '60 x 90', 'Vàng Trắng', 900000.00, 1300000.00, 2, '2026-06-03 05:42:59'),
(689, 201, '60 x 90', '3 Màu', 900000.00, 1300000.00, 2, '2026-06-03 05:42:59'),
(690, 202, '60 x 90', 'Vàng Trắng', 3200000.00, 3500000.00, 2, '2026-06-03 05:44:12'),
(691, 202, '60 x 90', '3 Màu', 3200000.00, 3500000.00, 2, '2026-06-03 05:44:12'),
(692, 202, '75 x 125', 'Vàng Trắng', 3500000.00, 3900000.00, 2, '2026-06-03 05:44:12'),
(693, 202, '75 x 125', '3 Màu', 3500000.00, 3900000.00, 2, '2026-06-03 05:44:12'),
(694, 203, '65 x 90', 'Vàng Trắng', 4200000.00, 4500000.00, 2, '2026-06-03 05:45:44'),
(695, 203, '65 x 90', '3 Màu', 4200000.00, 4500000.00, 2, '2026-06-03 05:45:44'),
(696, 203, '70 x 110', 'Vàng Trắng', 4500000.00, 4900000.00, 2, '2026-06-03 05:45:44'),
(697, 203, '70 x 110', '3 Màu', 4500000.00, 4900000.00, 2, '2026-06-03 05:45:44'),
(698, 204, '55 x 90', 'Vàng Trắng', 5200000.00, 5500000.00, 2, '2026-06-03 05:47:37'),
(699, 204, '55 x 90', '3 Màu', 5200000.00, 5500000.00, 2, '2026-06-03 05:47:37'),
(700, 204, '65 x 120', 'Vàng Trắng', 5500000.00, 5900000.00, 2, '2026-06-03 05:47:37'),
(701, 204, '65 x 120', '3 Màu', 5500000.00, 5900000.00, 2, '2026-06-03 05:47:37'),
(702, 205, '45 x 90', 'Vàng Trắng', 7200000.00, 7500000.00, 2, '2026-06-03 05:49:09'),
(703, 205, '45 x 90', '3 Màu', 7200000.00, 7500000.00, 2, '2026-06-03 05:49:09'),
(704, 205, '65 x 110', 'Vàng Trắng', 7500000.00, 7900000.00, 2, '2026-06-03 05:49:09'),
(705, 205, '65 x 110', '3 Màu', 7500000.00, 7900000.00, 2, '2026-06-03 05:49:09'),
(706, 206, '110 x 145', 'Vàng Trắng', 4250000.00, 4500000.00, 2, '2026-06-03 05:57:48'),
(707, 206, '110 x 145', '3 Màu', 4250000.00, 4500000.00, 2, '2026-06-03 05:57:48'),
(708, 206, '120 x 175', 'Vàng Trắng', 4700000.00, 5500000.00, 2, '2026-06-03 05:57:48'),
(709, 206, '120 x 175', '3 Màu', 4700000.00, 5500000.00, 2, '2026-06-03 05:57:48'),
(710, 207, '110 x 145', 'Vàng Trắng', 4200000.00, 4500000.00, 2, '2026-06-03 05:59:17'),
(711, 207, '110 x 145', '3 Màu', 4200000.00, 4500000.00, 2, '2026-06-03 05:59:17'),
(712, 207, '120 x 175', 'Vàng Trắng', 4700000.00, 5000000.00, 2, '2026-06-03 05:59:17'),
(713, 207, '120 x 175', '3 Màu', 4700000.00, 5000000.00, 2, '2026-06-03 05:59:17'),
(714, 208, '110 x 145', 'Vàng Trắng', 4100000.00, 4400000.00, 2, '2026-06-03 06:00:31'),
(715, 208, '110 x 145', '3 Màu', 4100000.00, 4400000.00, 2, '2026-06-03 06:00:31'),
(716, 208, '120 x 175', 'Vàng Trắng', 4300000.00, 4500000.00, 2, '2026-06-03 06:00:31'),
(717, 208, '120 x 175', '3 Màu', 4300000.00, 4500000.00, 2, '2026-06-03 06:00:31'),
(718, 209, '150 x 200', 'Vàng Trắng', 12000000.00, 12500000.00, 2, '2026-06-03 06:01:54'),
(719, 209, '150 x 200', '3 Màu', 12000000.00, 12500000.00, 2, '2026-06-03 06:01:54'),
(720, 209, '175 x 225', 'Vàng Trắng', 12750000.00, 13000000.00, 2, '2026-06-03 06:01:54'),
(721, 209, '175 x 225', '3 Màu', 12750000.00, 13000000.00, 2, '2026-06-03 06:01:54'),
(722, 210, '145 x 225', 'Vàng Trắng', 12750000.00, 13000000.00, 2, '2026-06-03 06:03:15'),
(723, 210, '145 x 225', '3 Màu', 12750000.00, 13000000.00, 2, '2026-06-03 06:03:15'),
(724, 210, '155 x 255', 'Vàng Trắng', 13250000.00, 13500000.00, 2, '2026-06-03 06:03:15'),
(725, 210, '155 x 255', '3 Màu', 13250000.00, 13500000.00, 2, '2026-06-03 06:03:15'),
(726, 211, '142 x 70', 'Vàng Trắng', 13500000.00, 15000000.00, 2, '2026-06-03 06:05:35'),
(727, 211, '142 x 70', '3 Màu', 13500000.00, 15000000.00, 2, '2026-06-03 06:05:35'),
(728, 211, '162 x 85', 'Vàng Trắng', 15200000.00, 17500000.00, 2, '2026-06-03 06:05:35'),
(729, 211, '162 x 85', '3 Màu', 15200000.00, 17500000.00, 2, '2026-06-03 06:05:35'),
(730, 212, '132 x 60', 'Vàng Trắng', 10050000.00, 10800000.00, 2, '2026-06-03 06:07:37'),
(731, 212, '132 x 60', '3 Màu', 10050000.00, 10800000.00, 2, '2026-06-03 06:07:37'),
(732, 212, '142 x 70', 'Vàng Trắng', 10800000.00, 12000000.00, 2, '2026-06-03 06:07:37'),
(733, 212, '142 x 70', '3 Màu', 10800000.00, 12000000.00, 2, '2026-06-03 06:07:37'),
(734, 213, '152 x 75', 'Vàng Trắng', 18900000.00, 21000000.00, 2, '2026-06-03 06:09:01'),
(735, 213, '152 x 75', '3 Màu', 18900000.00, 21000000.00, 2, '2026-06-03 06:09:01'),
(736, 213, '180 x 90', 'Vàng Trắng', 21500000.00, 25000000.00, 2, '2026-06-03 06:09:01'),
(737, 213, '180 x 90', '3 Màu', 21500000.00, 25000000.00, 2, '2026-06-03 06:09:01'),
(738, 214, '142 x 65', 'Vàng Trắng', 11800000.00, 14000000.00, 2, '2026-06-03 06:10:21'),
(739, 214, '142 x 65', '3 Màu', 11800000.00, 14000000.00, 2, '2026-06-03 06:10:21'),
(740, 214, '152 x 75', 'Vàng Trắng', 13500000.00, 16500000.00, 2, '2026-06-03 06:10:21'),
(741, 214, '152 x 75', '3 Màu', 13500000.00, 16500000.00, 2, '2026-06-03 06:10:21'),
(742, 215, '132 x 60', 'Vàng Trắng', 10800000.00, 12500000.00, 2, '2026-06-03 06:11:29'),
(743, 215, '132 x 60', '3 Màu', 10800000.00, 12500000.00, 2, '2026-06-03 06:11:29'),
(744, 215, '152 x 70', 'Vàng Trắng', 10800000.00, 12500000.00, 2, '2026-06-03 06:11:29'),
(745, 215, '152 x 70', '3 Màu', 10800000.00, 12500000.00, 2, '2026-06-03 06:11:29'),
(746, 216, '132 x 60', 'Vàng Trắng', 10800000.00, 12500000.00, 2, '2026-06-03 06:12:50'),
(747, 216, '132 x 60', '3 Màu', 10800000.00, 12500000.00, 2, '2026-06-03 06:12:50'),
(748, 216, '152 x 70', 'Vàng Trắng', 12500000.00, 14800000.00, 2, '2026-06-03 06:12:50'),
(749, 216, '152 x 70', '3 Màu', 12500000.00, 14800000.00, 2, '2026-06-03 06:12:50'),
(750, 217, '35 x 60', 'Vàng Trắng', 5100000.00, 6200000.00, 2, '2026-06-03 06:17:00'),
(751, 217, '35 x 60', '3 Màu', 5100000.00, 6200000.00, 2, '2026-06-03 06:17:00'),
(752, 217, '40 x 70', 'Vàng Trắng', 5900000.00, 7200000.00, 2, '2026-06-03 06:17:00'),
(753, 217, '40 x 70', '3 Màu', 5900000.00, 7200000.00, 2, '2026-06-03 06:17:00'),
(754, 218, '45 x 85', 'Vàng Trắng', 10500000.00, 12500000.00, 2, '2026-06-03 06:18:52'),
(755, 218, '45 x 85', '3 Màu', 10500000.00, 12500000.00, 2, '2026-06-03 06:18:52'),
(756, 218, '50 x 95', 'Vàng Trắng', 11800000.00, 14500000.00, 2, '2026-06-03 06:18:52'),
(757, 218, '50 x 95', '3 Màu', 11800000.00, 14500000.00, 2, '2026-06-03 06:18:52'),
(758, 219, '50 x 90', 'Vàng Trắng', 11800000.00, 14000000.00, 2, '2026-06-03 06:21:00'),
(759, 219, '50 x 90', '3 Màu', 11800000.00, 14000000.00, 2, '2026-06-03 06:21:00'),
(760, 219, '55 x 105', 'Vàng Trắng', 13500000.00, 16500000.00, 2, '2026-06-03 06:21:00'),
(761, 219, '55 x 105', '3 Màu', 13500000.00, 16500000.00, 2, '2026-06-03 06:21:00'),
(762, 220, '15 x 30', 'Vàng Trắng', 590000.00, 850000.00, 2, '2026-06-03 06:22:33'),
(763, 220, '15 x 30', '3 Màu', 590000.00, 850000.00, 2, '2026-06-03 06:22:33'),
(764, 220, '18 x 35', 'Vàng Trắng', 690000.00, 950000.00, 2, '2026-06-03 06:22:33'),
(765, 220, '18 x 35', '3 Màu', 690000.00, 950000.00, 2, '2026-06-03 06:22:33'),
(766, 221, '18 x 35', 'Vàng Trắng', 680000.00, 900000.00, 2, '2026-06-03 06:23:50'),
(767, 221, '18 x 35', '3 Màu', 680000.00, 900000.00, 2, '2026-06-03 06:23:50'),
(768, 221, '20 x 40', 'Vàng Trắng', 780000.00, 1000000.00, 2, '2026-06-03 06:23:50'),
(769, 221, '20 x 40', '3 Màu', 780000.00, 1000000.00, 2, '2026-06-03 06:23:50');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `reviews`
--

CREATE TABLE `reviews` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rating` int DEFAULT '5',
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_approved` tinyint(1) DEFAULT '0',
  `reply` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `reviews`
--

INSERT INTO `reviews` (`id`, `product_id`, `user_id`, `user_name`, `rating`, `comment`, `is_approved`, `reply`, `created_at`, `deleted_at`) VALUES
(1, 121, NULL, 'Đỗ Tiến Thắng', 5, 'Okok', 1, 'Cảm ơn bạn đã mua hàng', '2026-04-09 15:58:23', NULL),
(3, 90, NULL, 'Đỗ Tiến Thắng', 5, 'Sản phấm rất chất lượng', 1, 'Cảm ơn bạn đã mua hàng', '2026-04-19 06:42:11', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `settings`
--

CREATE TABLE `settings` (
  `setting_key` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `settings`
--

INSERT INTO `settings` (`setting_key`, `setting_value`) VALUES
('address', '905 Nguyễn Văn Linh, An Biên, Hải Phòng'),
('ads_bottom_link', ''),
('ads_bottom_url', '/uploads/banners/banner_6a17c82ce90a96.75163419.jpg'),
('ads_left_link', '/category?type=Đèn thả'),
('ads_left_url', '/uploads/banners/banner_6a16608b91b227.27013876.jpg'),
('ads_right_link', '/'),
('ads_right_url', '/uploads/banners/banner_6a1673b0c12589.68700693.jpg'),
('bank_account_name', ''),
('bank_account_no', ''),
('bank_name', ''),
('bank_qr', '/uploads/logo/bank_qr_69d7bf9dbe0559.09934583.png'),
('banner_right', '/uploads/banners/banner_69d7151e262b93.91979867.png'),
('banner_url', ''),
('banner_urls', '[\"/uploads/banners/banner_6a17c96475ec41.01735396.jpg\",\"/uploads/banners/banner_6a17c9680af757.90817658.jpg\",\"/uploads/banners/banner_6a17c96a8d0b16.97279815.jpg\",\"/uploads/banners/banner_6a17c96f071819.17026858.jpg\"]'),
('email', 'hieu.it@denhoamy.com'),
('hotline', '0978897579 - 02256533618'),
('logo_url', '/uploads/logo/logo_69d715d1a65537.34672868.jpg'),
('policy_bao_hanh', '<h3>📄 CHÍNH SÁCH BẢO HÀNH (ĐÈN TRANG TRÍ &amp; NỘI THẤT)</h3><p><strong>1. Thời gian bảo hành</strong></p><ul><li>Sản phẩm được bảo hành từ <strong>6 – 24 tháng</strong> tùy từng loại:</li><li class=\"ql-indent-1\">Đèn LED, driver: <strong>6 – 12 tháng</strong></li><li class=\"ql-indent-1\">Đèn chùm, đèn thả cao cấp: <strong>12 – 24 tháng</strong></li><li>Thời gian tính từ ngày nhận hàng hoặc ngày trên hóa đơn.</li></ul><p><strong>2. Điều kiện bảo hành</strong></p><p> Sản phẩm được bảo hành miễn phí khi:</p><ul><li>Còn trong thời gian bảo hành.</li><li>Lỗi kỹ thuật từ nhà sản xuất (không sáng, chập chờn, lỗi nguồn, hỏng driver…).</li><li>Có thông tin đơn hàng hoặc hóa đơn hợp lệ.</li></ul><p><strong>3. Trường hợp được bảo hành</strong></p><ul><li>Đèn không hoạt động hoặc hoạt động không ổn định.</li><li>Lỗi linh kiện điện (driver, chip LED…).</li><li>Lỗi kết cấu do sản xuất (lỏng khớp, lỗi khung đèn…).</li></ul><p><strong>4. Trường hợp không bảo hành</strong></p><ul><li>Sản phẩm đã bị <strong>lắp đặt sai kỹ thuật</strong> hoặc sử dụng sai nguồn điện.</li><li>Hư hỏng do rơi vỡ, va đập, vào nước.</li><li>Tự ý sửa chữa, thay đổi kết cấu sản phẩm.</li><li>Hao mòn tự nhiên (ố màu, trầy xước nhẹ theo thời gian).</li><li>Sản phẩm <strong>đặt theo yêu cầu riêng (custom)</strong>.</li></ul><p><strong>5. Hình thức bảo hành</strong></p><ul><li><strong>Sửa chữa miễn phí</strong> đối với lỗi nhẹ.</li><li><strong>Thay thế linh kiện</strong> nếu cần thiết.</li><li><strong>Đổi mới sản phẩm</strong> nếu lỗi nghiêm trọng không thể sửa.</li></ul><p><strong>6. Thời gian xử lý</strong></p><ul><li>Thời gian bảo hành: <strong>3 – 7 ngày làm việc</strong> (không tính vận chuyển).</li><li>Với sản phẩm phức tạp (đèn chùm lớn): có thể lâu hơn và sẽ được thông báo trước.</li></ul><p><strong>7. Chi phí bảo hành</strong></p><ul><li>Miễn phí 100% nếu lỗi từ nhà sản xuất.</li><li>Khách hàng chịu chi phí vận chuyển nếu không thuộc lỗi bảo hành.</li></ul><p><strong>8. Lưu ý quan trọng</strong></p><ul><li>Nên kiểm tra sản phẩm trước khi lắp đặt.</li><li>Sử dụng đúng điện áp và hướng dẫn kỹ thuật.</li><li>Với đèn chùm/đèn thả: nên lắp bởi kỹ thuật viên để đảm bảo an toàn.</li></ul><p><strong>9. Quy trình bảo hành</strong></p><ul><li>Liên hệ shop qua hotline/email/zalo.</li><li>Cung cấp hình ảnh/video lỗi.</li><li>Shop xác nhận → hướng dẫn gửi hàng hoặc hỗ trợ tại chỗ.</li><li>Tiến hành bảo hành và thông báo khi hoàn tất.</li></ul>'),
('policy_doi_tra', '<h3>🔄 CHÍNH SÁCH ĐỔI TRẢ (ĐÈN TRANG TRÍ &amp; NỘI THẤT)</h3><p><strong>1. Thời gian áp dụng</strong></p><ul><li>Hỗ trợ đổi/trả trong vòng <strong>3 – 7 ngày</strong> kể từ khi nhận hàng.</li></ul><p><strong>2. Điều kiện đổi/trả</strong></p><p> Sản phẩm được chấp nhận đổi/trả khi:</p><ul><li>Chưa lắp đặt hoặc sử dụng.</li><li>Còn nguyên vẹn, đầy đủ hộp, phụ kiện, tem nhãn.</li><li>Có hóa đơn hoặc thông tin đơn hàng.</li></ul><p><strong>3. Trường hợp được đổi/trả</strong></p><ul><li>Sản phẩm bị lỗi kỹ thuật (không sáng, chập điện, lỗi driver…).</li><li>Bị vỡ, móp, trầy xước do vận chuyển.</li><li>Giao sai mẫu (ví dụ: đèn chùm / đèn thả / đèn ốp trần / đèn bàn / đèn quạt…).</li><li>Sai màu sắc, kiểu dáng (cổ điển, hiện đại, tân cổ điển).</li></ul><p><strong>4. Trường hợp không áp dụng đổi/trả</strong></p><ul><li>Sản phẩm đã lắp đặt hoặc sử dụng.</li><li>Hư hỏng do lắp sai kỹ thuật, nguồn điện không phù hợp.</li><li>Khách tự ý sửa chữa, thay đổi kết cấu.</li><li>Sản phẩm đặt theo yêu cầu riêng (custom theo kích thước/thiết kế).</li></ul><p><strong>5. Hình thức xử lý</strong></p><ul><li><strong>Đổi mới 1–1</strong> nếu lỗi do nhà sản xuất.</li><li><strong>Hoàn tiền</strong> nếu không còn sản phẩm thay thế.</li><li>Có thể hỗ trợ <strong>đổi sang mẫu khác</strong> (bù/trừ giá trị).</li></ul><p><strong>6. Chi phí đổi/trả</strong></p><ul><li>Shop chịu 100% chi phí nếu lỗi do sản phẩm hoặc vận chuyển.</li><li>Khách hàng chịu phí nếu đổi vì lý do cá nhân (không thích, đổi mẫu…).</li></ul><p><strong>7. Lưu ý quan trọng</strong></p><ul><li>Khuyến khích khách <strong>quay video khi mở hộp</strong> để làm bằng chứng nếu có lỗi/vỡ.</li><li>Kiểm tra kỹ sản phẩm trước khi lắp đặt.</li><li>Với sản phẩm lớn (đèn chùm, đèn thả), nên có kỹ thuật lắp đặt đúng chuẩn.</li></ul><p><strong>8. Quy trình đổi/trả</strong></p><ul><li>Liên hệ shop qua hotline/email/zalo.</li><li>Gửi hình ảnh/video sản phẩm lỗi.</li><li>Shop xác nhận → hướng dẫn gửi hàng → xử lý trong <strong>2 – 5 ngày</strong>.</li></ul>'),
('policy_huong_dan', '<h3>💳 CHÍNH SÁCH THANH TOÁN</h3><p><strong>1. Phương thức thanh toán</strong></p><p> Shop hỗ trợ 2 hình thức thanh toán chính:</p><ul><li>Thanh toán khi nhận hàng (<strong>COD</strong>)</li><li>Thanh toán chuyển khoản qua <strong>QR Code</strong></li></ul><p><strong>2. Thanh toán khi nhận hàng (COD)</strong></p><ul><li>Khách hàng thanh toán trực tiếp cho nhân viên giao hàng khi nhận sản phẩm.</li><li>Áp dụng toàn quốc.</li></ul><p><strong>Lưu ý:</strong></p><ul><li>Vui lòng kiểm tra hàng trước khi thanh toán.</li><li>Chuẩn bị sẵn tiền mặt để quá trình giao nhận nhanh chóng.</li><li>Với đơn hàng giá trị cao hoặc hàng cồng kềnh (đèn chùm, đèn lớn), shop có thể yêu cầu <strong>đặt cọc trước</strong>.</li></ul><p><strong>3. Thanh toán qua QR Code (chuyển khoản)</strong></p><ul><li>Khách hàng quét mã QR để thanh toán qua ngân hàng hoặc ví điện tử.</li><li>Thông tin thanh toán sẽ được cung cấp sau khi xác nhận đơn hàng.</li></ul><p><strong>Lưu ý:</strong></p><ul><li>Nội dung chuyển khoản ghi rõ: <strong>[Tên + SĐT + Mã đơn]</strong></li><li>Đơn hàng sẽ được xử lý sau khi shop xác nhận đã nhận thanh toán.</li></ul><p><strong>4. Xác nhận thanh toán</strong></p><ul><li>Sau khi thanh toán thành công, shop sẽ liên hệ xác nhận và tiến hành giao hàng.</li><li>Với thanh toán QR, thời gian xác nhận thường trong <strong>5 – 30 phút</strong> (giờ hành chính).</li></ul><p><strong>5. Chính sách đặt cọc (nếu có)</strong></p><ul><li>Áp dụng với:</li><li class=\"ql-indent-1\">Đơn hàng giá trị cao</li><li class=\"ql-indent-1\">Sản phẩm đặt theo yêu cầu (custom)</li><li>Mức đặt cọc: <strong>[10% – 50% giá trị đơn hàng]</strong></li><li>Phần còn lại thanh toán khi nhận hàng.</li></ul><p><strong>6. Thông tin hỗ trợ</strong></p><ul><li>Hotline: [SĐT]</li><li>Email: [Email]</li><li>Địa chỉ: [Cửa hàng / Showroom]</li></ul>'),
('policy_van_chuyen', '<h3>🚚 CHÍNH SÁCH VẬN CHUYỂN</h3><p><strong>1. Phạm vi áp dụng</strong></p><ul><li>Giao hàng toàn quốc.</li><li>Hỗ trợ giao nhanh tại nội thành và các khu vực lân cận.</li></ul><p><strong>2. Thời gian giao hàng</strong></p><ul><li>Nội thành: <strong>1 – 3 ngày làm việc</strong></li><li>Ngoại tỉnh: <strong>3 – 7 ngày làm việc</strong></li><li>Sản phẩm đặt riêng (custom): <strong>5 – 10 ngày</strong> hoặc theo thỏa thuận</li></ul><p>(<em>Thời gian có thể thay đổi tùy khu vực và đơn vị vận chuyển</em>)</p><p><strong>3. Chi phí vận chuyển</strong></p><ul><li><strong>Miễn phí vận chuyển</strong> với đơn hàng từ <strong>[X VNĐ]</strong> trở lên (nội thành).</li><li>Đơn hàng dưới mức miễn phí: tính phí theo khoảng cách/kích thước.</li><li>Hàng cồng kềnh (đèn chùm, đèn thả lớn…): tính phí riêng.</li></ul><p><strong>4. Quy trình giao hàng</strong></p><ul><li>Xác nhận đơn hàng qua điện thoại/email/zalo.</li><li>Đóng gói sản phẩm (đặc biệt với hàng dễ vỡ).</li><li>Bàn giao cho đơn vị vận chuyển hoặc giao trực tiếp.</li><li>Thông báo mã vận đơn để khách theo dõi.</li></ul><p><strong>5. Kiểm tra khi nhận hàng</strong></p><ul><li>Khách hàng <strong>được kiểm tra hàng trước khi thanh toán</strong> (nếu có COD).</li><li>Quay video khi mở hàng để đảm bảo quyền lợi.</li><li>Nếu phát hiện lỗi/vỡ: từ chối nhận hoặc liên hệ ngay với shop.</li></ul><p><strong>6. Trách nhiệm vận chuyển</strong></p><ul><li>Shop chịu trách nhiệm nếu hàng bị <strong>hư hỏng, vỡ do vận chuyển</strong>.</li><li>Đảm bảo đóng gói an toàn (bọt xốp, thùng carton, khung bảo vệ…).</li></ul><p><strong>7. Trường hợp giao hàng không thành công</strong></p><ul><li>Không liên lạc được với khách hàng.</li><li>Sai thông tin địa chỉ.</li><li>Khách từ chối nhận hàng không có lý do chính đáng.</li></ul><p>→ Shop sẽ liên hệ lại tối đa <strong>2 – 3 lần</strong> trước khi hủy đơn.</p><p><strong>8. Lưu ý đặc biệt (đèn &amp; nội thất)</strong></p><ul><li>Với đèn chùm/đèn lớn: có thể <strong>giao nhiều kiện</strong>.</li><li>Một số sản phẩm cần <strong>lắp đặt sau khi giao</strong> (không bao gồm trong phí ship nếu chưa đăng ký).</li><li>Khuyến khích khách kiểm tra kỹ trước khi ký nhận.</li></ul><p><strong>9. Thông tin hỗ trợ</strong></p><ul><li>Hotline: [SĐT]</li><li>Email: [Email]</li><li>Địa chỉ: [Showroom/Cửa hàng]</li></ul>'),
('shop_name', 'ĐÈN HOA MỸ');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `is_locked` tinyint(1) DEFAULT '0' COMMENT 'TRUE = tài khoản bị khoá',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `name`, `phone`, `email`, `address`, `is_locked`, `created_at`, `deleted_at`) VALUES
(1, '0987452316', '$2y$10$nZjnuHPxlk5.ZkofpYk1b.ZFfQRPW.rU90uzJJEfQlmEWswCvV4nS', 'Đỗ Tiến Thắng', '0987452316', 'user_Thang983@yahoo.com', NULL, 0, '2026-04-09 04:29:32', NULL),
(2, '0866830716', '$2y$10$n5pwzwl0.2apYl0kpcV1w.vDYtusuXUyJ3fWJdYtGwUEpH8/Ui4b2', 'Trần Minh Hiếu', '0866830716', 'minhhieutran0609@gmail.com', NULL, 0, '2026-05-25 01:21:55', NULL);

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `user_coupons`
--

CREATE TABLE `user_coupons` (
  `id` int NOT NULL,
  `user_id` int NOT NULL COMMENT 'Khach hang so huu voucher',
  `coupon_id` int NOT NULL COMMENT 'Ma giam gia duoc luu',
  `status` enum('unused','used','expired') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'unused' COMMENT 'unused = chua dung, used = da dung, expired = het han',
  `claimed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Thoi diem khach hang luu ma',
  `used_at` timestamp NULL DEFAULT NULL COMMENT 'Thoi diem ma duoc su dung trong don hang',
  `order_id` int DEFAULT NULL COMMENT 'Don hang da ap dung voucher nay (neu da dung)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `wishlists`
--

CREATE TABLE `wishlists` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Chỉ mục cho bảng `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Chỉ mục cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cart_id` (`cart_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `variant_id` (`variant_id`);

--
-- Chỉ mục cho bảng `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cat_parent` (`parent_id`);

--
-- Chỉ mục cho bảng `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_session_id` (`session_id`);

--
-- Chỉ mục cho bảng `chat_sessions`
--
ALTER TABLE `chat_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_session_token` (`session_token`);

--
-- Chỉ mục cho bảng `coupons`
--
ALTER TABLE `coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Chỉ mục cho bảng `inventory_history`
--
ALTER TABLE `inventory_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `admin_id` (`admin_id`),
  ADD KEY `fk_inventory_history_variant` (`variant_id`);

--
-- Chỉ mục cho bảng `news`
--
ALTER TABLE `news`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `author_id` (`author_id`);

--
-- Chỉ mục cho bảng `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `coupon_id` (`coupon_id`),
  ADD KEY `processed_by` (`processed_by`),
  ADD KEY `idx_order_status` (`status`),
  ADD KEY `idx_order_user` (`user_id`);

--
-- Chỉ mục cho bảng `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Chỉ mục cho bảng `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_token_hash` (`token_hash`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Chỉ mục cho bảng `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_id` (`order_id`);

--
-- Chỉ mục cho bảng `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ma_san_pham` (`ma_san_pham`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `idx_ten_san_pham` (`ten_san_pham`),
  ADD KEY `idx_ma_san_pham` (`ma_san_pham`),
  ADD KEY `idx_loai_den` (`loai_den`),
  ADD KEY `idx_price` (`price`),
  ADD KEY `idx_hot_deal` (`is_hot_deal`);

--
-- Chỉ mục cho bảng `product_images`
--
ALTER TABLE `product_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Chỉ mục cho bảng `product_specs`
--
ALTER TABLE `product_specs`
  ADD PRIMARY KEY (`product_id`);

--
-- Chỉ mục cho bảng `product_variants`
--
ALTER TABLE `product_variants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Chỉ mục cho bảng `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_review_product` (`product_id`);

--
-- Chỉ mục cho bảng `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_user_phone` (`phone`);

--
-- Chỉ mục cho bảng `user_coupons`
--
ALTER TABLE `user_coupons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_coupon` (`user_id`,`coupon_id`),
  ADD KEY `coupon_id` (`coupon_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Chỉ mục cho bảng `wishlists`
--
ALTER TABLE `wishlists`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_product` (`user_id`,`product_id`),
  ADD KEY `product_id` (`product_id`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `admins`
--
ALTER TABLE `admins`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT cho bảng `carts`
--
ALTER TABLE `carts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT cho bảng `chat_messages`
--
ALTER TABLE `chat_messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `chat_sessions`
--
ALTER TABLE `chat_sessions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `coupons`
--
ALTER TABLE `coupons`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT cho bảng `inventory_history`
--
ALTER TABLE `inventory_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `news`
--
ALTER TABLE `news`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT cho bảng `orders`
--
ALTER TABLE `orders`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT cho bảng `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT cho bảng `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT cho bảng `products`
--
ALTER TABLE `products`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=222;

--
-- AUTO_INCREMENT cho bảng `product_images`
--
ALTER TABLE `product_images`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=277;

--
-- AUTO_INCREMENT cho bảng `product_variants`
--
ALTER TABLE `product_variants`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=770;

--
-- AUTO_INCREMENT cho bảng `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT cho bảng `user_coupons`
--
ALTER TABLE `user_coupons`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT cho bảng `wishlists`
--
ALTER TABLE `wishlists`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Ràng buộc đối với các bảng kết xuất
--

--
-- Ràng buộc cho bảng `carts`
--
ALTER TABLE `carts`
  ADD CONSTRAINT `carts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `chat_sessions`
--
ALTER TABLE `chat_sessions`
  ADD CONSTRAINT `chat_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `inventory_history`
--
ALTER TABLE `inventory_history`
  ADD CONSTRAINT `fk_inventory_history_variant` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `inventory_history_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventory_history_ibfk_2` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `news`
--
ALTER TABLE `news`
  ADD CONSTRAINT `news_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`processed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `product_images`
--
ALTER TABLE `product_images`
  ADD CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `product_specs`
--
ALTER TABLE `product_specs`
  ADD CONSTRAINT `product_specs_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `product_variants`
--
ALTER TABLE `product_variants`
  ADD CONSTRAINT `product_variants_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Ràng buộc cho bảng `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `user_coupons`
--
ALTER TABLE `user_coupons`
  ADD CONSTRAINT `user_coupons_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_coupons_ibfk_2` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_coupons_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL;

--
-- Ràng buộc cho bảng `wishlists`
--
ALTER TABLE `wishlists`
  ADD CONSTRAINT `wishlists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `wishlists_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
