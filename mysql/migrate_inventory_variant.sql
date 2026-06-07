ALTER TABLE inventory_history
ADD COLUMN variant_id INT NULL AFTER product_id;

ALTER TABLE inventory_history
ADD CONSTRAINT fk_inventory_history_variant
FOREIGN KEY (variant_id) REFERENCES product_variants(id)
ON DELETE SET NULL;
