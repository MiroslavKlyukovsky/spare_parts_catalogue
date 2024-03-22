/*
-- problems can be not enough or too much constrains, difference between constraints, bad references
-- Make triggers when one element is added to the archive, parent entities are added with a certain amount

-- I might add quantity to auto_part archive, also I have to add trigger on adding consignments to add to auto_part quantity

-- individual element moving in individual_auto_part_archive is not made yet, not automated
*/

CREATE TABLE supplier (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL CHECK (name ~ '^[A-Za-z0-9\s\-.''()]+$'),
    office_address VARCHAR(250) NOT NULL CHECK (office_address ~ '^.{10,}$'),
    phone_number VARCHAR(21) NOT NULL CHECK (phone_number ~ '^\+?\d{5,20}$'),
    email VARCHAR(100) NOT NULL CHECK (email ~ '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'),
    contact_person_name VARCHAR(100) NOT NULL CHECK (contact_person_name ~ '^[a-zA-Z ]+$'),
    contact_person_surname VARCHAR(100) CHECK (supplier.contact_person_surname ~ '^[a-zA-Z ]+$'),
    CONSTRAINT unique_name_office_address_phone_number_email UNIQUE (name, office_address, phone_number, email)
);

CREATE TABLE admin (
    email VARCHAR(100) PRIMARY KEY CHECK (email ~ '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'),
    admin_name VARCHAR(100) NOT NULL CHECK (admin_name ~ '^[a-zA-Z ]+$'),
    admin_surname VARCHAR(100) CHECK (admin_surname ~ '^[a-zA-Z ]+$'),
    phone_number VARCHAR(21) NOT NULL CHECK (phone_number ~ '^\+?\d{5,20}$'),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 10),
    CONSTRAINT unique_phone_number UNIQUE(phone_number)
);

CREATE TABLE client (
    email VARCHAR(100) PRIMARY KEY CHECK (email ~ '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'),
    client_name VARCHAR(100) NOT NULL CHECK (client_name ~ '^[a-zA-Z ]+$'),
    client_surname VARCHAR(100) CHECK (client_surname ~ '^[a-zA-Z ]+$'),
    phone_number VARCHAR(21) NOT NULL CHECK (phone_number ~ '^\+?\d{5,20}$'),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 5),
    address VARCHAR(250) CHECK (address ~ '^.{10,}$'),
    balance_uah MONEY NOT NULL CHECK (balance_uah <= 1000000::MONEY)
);


CREATE TABLE purchase (
    purchase_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(purchase_code) > 5),
    email VARCHAR(100) REFERENCES client(email) ON DELETE RESTRICT,
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(purchase_time) = CURRENT_DATE),
    total_price_uah MONEY NOT NULL CHECK (total_price_uah <= 1000000::MONEY),
    CONSTRAINT unique_purchase_time_email UNIQUE (purchase_time, email)
);


CREATE TABLE auto_part (
    product_code VARCHAR(100) PRIMARY KEY CHECK (LENGTH(product_code) >= 5),
    name VARCHAR(250) NOT NULL CHECK (LENGTH(name) >= 2),
    price_uah MONEY CHECK (price_uah <= 1000000::MONEY),
    quantity INTEGER NOT NULL CHECK (quantity >= 0), -- when zero has to be moved to archive
    warranty_term INTERVAL DAY NOT NULL CHECK (warranty_term >= INTERVAL '0 days' AND warranty_term <= INTERVAL '9000 days')
);

CREATE TABLE consignment (
    deal_code VARCHAR(12) PRIMARY KEY CHECK (deal_code ~ '^\d{12}$'),
    supplier_id INTEGER REFERENCES supplier(supplier_id) ON DELETE RESTRICT,
    quantity_at_start SMALLINT NOT NULL CHECK (quantity_at_start > 0),
    quantity SMALLINT NOT NULL CHECK (quantity >= 0),
    price_uah MONEY NOT NULL CHECK (price_uah < 3000000::MONEY),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE),
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory ~ '^[a-zA-Z0-9\s\-"''()\[\]]+$'),
    product_code VARCHAR(100) REFERENCES auto_part(product_code) ON DELETE RESTRICT,
    serial_code VARCHAR(100) NOT NULL CHECK (LENGTH(serial_code) >= 5),
    CONSTRAINT unique_supplier_id_deal_time UNIQUE (supplier_id, deal_time)
);

CREATE TABLE individual_auto_part (
    individual_auto_part_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(individual_auto_part_code) > 5),
    production_date DATE NOT NULL CHECK (production_date >= '1950-01-01' AND production_date <= CURRENT_DATE),
    deal_code VARCHAR(12) REFERENCES consignment(deal_code) ON DELETE RESTRICT
);


CREATE TABLE auto_part_archive (
    product_code VARCHAR(100) PRIMARY KEY CHECK (LENGTH(product_code) >= 5),
    name VARCHAR(250) NOT NULL CHECK (LENGTH(name) >= 2),
    quantity INTEGER NOT NULL CHECK (quantity >= 0), -- insert with brain usage
    warranty_term INTERVAL DAY NOT NULL CHECK (warranty_term >= INTERVAL '0 days' AND warranty_term <= INTERVAL '9000 days')
);

CREATE TABLE consignment_archive (
    deal_code VARCHAR(12) PRIMARY KEY CHECK (deal_code ~ '^\d{12}$'),
    supplier_id INTEGER REFERENCES supplier(supplier_id) ON DELETE RESTRICT,
    quantity_at_start SMALLINT NOT NULL CHECK (quantity_at_start > 0),
    quantity SMALLINT NOT NULL CHECK (quantity >= 0),
    price_uah MONEY NOT NULL CHECK (price_uah < 3000000::MONEY),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE),
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory ~ '^[a-zA-Z0-9\s\-"''()\[\]]+$'),
    product_code VARCHAR(100) REFERENCES auto_part_archive(product_code) ON DELETE RESTRICT,
    serial_code VARCHAR(100) NOT NULL CHECK (LENGTH(serial_code) >= 5),
    CONSTRAINT unique_supplier_id_deal_time_archive UNIQUE (supplier_id, deal_time)
);

CREATE TABLE individual_auto_part_archive (
    individual_auto_part_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(individual_auto_part_code) > 5),
    purchase_code VARCHAR(50) REFERENCES purchase(purchase_code) ON DELETE RESTRICT,
    price_uah MONEY NOT NULL CHECK (price_uah <= 1000000::MONEY),
    production_date DATE NOT NULL CHECK (production_date >= '1950-01-01' AND production_date <= CURRENT_DATE),
    deal_code VARCHAR(12) REFERENCES consignment_archive(deal_code) ON DELETE RESTRICT
);


CREATE TABLE car (
    car_id SERIAL PRIMARY KEY,
    automaker VARCHAR(50) NOT NULL CHECK (automaker ~ '^[a-zA-Z0-9\s\-&]+$'),
    model VARCHAR(50) NOT NULL CHECK (model ~ '^[a-zA-Z0-9\s\-_]+$'),
    year SMALLINT NOT NULL CHECK (year > 1950 AND year < 2100),
    CONSTRAINT unique_automaker_model_year UNIQUE (automaker, model, year)
);

CREATE TABLE auto_part_compatible_car (
    product_code VARCHAR(100) NOT NULL CHECK (LENGTH(product_code) >= 5),
    car_id INTEGER REFERENCES car(car_id) ON DELETE RESTRICT,
    PRIMARY KEY (product_code, car_id)
);


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



