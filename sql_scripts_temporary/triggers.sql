CREATE OR REPLACE FUNCTION add_quantity_on_new_consignment()
RETURNS TRIGGER AS $$
BEGIN
    -- Increase the quantity of the corresponding auto_part
    UPDATE auto_part
    SET quantity = quantity + NEW.quantity
    WHERE product_code = NEW.product_code;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER add_quantity_trigger
AFTER INSERT ON consignment
FOR EACH ROW
EXECUTE FUNCTION add_quantity_on_new_consignment();


/*
 If we have auto parts and so their consignments and their rows in auto_part
 This trigger finds product code for an individual auto part,
 tries to create tables auto_part_archive and consignment_archive if they do not exist,
 subtracts quantities by one from auto_part and consignment,
 adds to quantities one in auto_part_archive and consignment_archive
 deletes row from consignment if its quantity zero now
 and then deletes auto_part row if its quantity zero (it has zero active consignments)
*/


CREATE OR REPLACE FUNCTION delete_individual_auto_part_trigger()
RETURNS TRIGGER AS $$
DECLARE
    product_code_indiv VARCHAR(100);
BEGIN
    RAISE NOTICE 'Product Code Indiv: %', OLD.individual_auto_part_code;
    /*
    SELECT a.product_code INTO product_code_indiv
    FROM individual_auto_part i
    JOIN consignment c ON i.deal_code = c.deal_code
    JOIN auto_part a ON c.product_code = a.product_code
    WHERE i.individual_auto_part_code = OLD.individual_auto_part_code;*/
    -- if I delete i.individual_auto_part_code no longer exist as I delete it and trigger was actovtaed
    SELECT a.product_code INTO product_code_indiv
    FROM consignment c
    JOIN auto_part a ON c.product_code = a.product_code
    WHERE c.deal_code = OLD.deal_code;
    RAISE NOTICE 'Product Code Indiv: %', product_code_indiv;

    INSERT INTO auto_part_archive(product_code, name, quantity, warranty_term)
    SELECT product_code, name, 0 AS quantity, warranty_term
    FROM auto_part
    WHERE auto_part.product_code = product_code_indiv
      AND NOT EXISTS (
      SELECT 1
      FROM auto_part_archive
      WHERE product_code_indiv = auto_part_archive.product_code
    );

    INSERT INTO consignment_archive(deal_code, supplier_id, quantity_at_start, quantity, price_uah, deal_time, producing_factory, product_code, serial_code)
    SELECT deal_code, supplier_id, quantity_at_start, 0 AS quantity, price_uah, deal_time, producing_factory, product_code, serial_code
    FROM consignment
    WHERE deal_code = OLD.deal_code
        AND NOT EXISTS (
        SELECT 1
        FROM consignment_archive
        WHERE OLD.deal_code = consignment_archive.deal_code
    );

    UPDATE consignment
    SET quantity = quantity - 1
    WHERE deal_code = OLD.deal_code;

    UPDATE consignment_archive
    SET quantity = quantity + 1
    WHERE deal_code = OLD.deal_code;

    UPDATE auto_part
    SET quantity = quantity - 1
    WHERE product_code = product_code_indiv;

    UPDATE auto_part_archive
    SET quantity = quantity + 1
    WHERE product_code = product_code_indiv;

    IF (SELECT quantity FROM consignment WHERE deal_code = OLD.deal_code) = 0 THEN
        DELETE FROM consignment WHERE deal_code = OLD.deal_code;
    END IF;

    IF (SELECT quantity FROM auto_part WHERE auto_part.product_code = product_code_indiv) = 0 THEN
        DELETE FROM auto_part WHERE auto_part.product_code = product_code_indiv;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_individual_auto_part
AFTER DELETE ON individual_auto_part
FOR EACH ROW
EXECUTE FUNCTION delete_individual_auto_part_trigger();
