-- Hot Deal: snapshot giá trước khuyến mãi (khôi phục khi gỡ Hot Deal)
-- Chạy trên DB đã tồn tại sau backup.

ALTER TABLE products
  ADD COLUMN price_before_hot_deal DECIMAL(15,2) NULL DEFAULT NULL,
  ADD COLUMN old_price_before_hot_deal DECIMAL(15,2) NULL DEFAULT NULL;

ALTER TABLE product_variants
  ADD COLUMN price_before_hot_deal DECIMAL(15,2) NULL DEFAULT NULL;
