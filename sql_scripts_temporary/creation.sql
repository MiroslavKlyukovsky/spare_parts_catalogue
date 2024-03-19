/*
product_code (always unique) - says brand and exact auto part purpose
serial_code (not always unique) - says from which series is the auto part (factory, subtype of exact auto part)
individual_auto_part_code (always unique) - identifies an individual auto part from all others
*/
/*
-- problems can be not enough or too much constrains, difference between constraints, bad references

-- email must be varchar(100) CHECK (LENGTH(email) >= 3); (primary key)
-- name must be varchar(100) NOT NULL CHECK (name <> '');
-- surname must be varchar(100) CHECK (surname <> '');
-- password must be varchar(50) NOT NULL CHECK (LENGTH(password) >= 5); LENGTH 10 for admin
-- is_admin must be boolean NOT NULL; (regular user = 0, admin = 1)
-- phone number must be varchar(20) NOT NULL CHECK (LENGTH(phone_number) >= 5)
-- address must be varchar(250) CHECK (LENGTH(address) >= 10)

-- nulls!!!
-- check all reference stuff (types, not needed constraints)
-- Make triggers when one element is added to the archive, parent entities are added with a certain amount
*/
CREATE TABLE auto_part (
    product_code VARCHAR(100) PRIMARY KEY CHECK (LENGTH(product_code) >= 5),
    name VARCHAR(250) NOT NULL CHECK (LENGTH(product_code) >= 2),
    price_uah MONEY CHECK (price_uah <= 1000000),
    warranty_term INTERVAL DAY NOT NULL CHECK (warranty_term >= INTERVAL '0 days' AND warranty_term <= INTERVAL '9000 days')
);

CREATE TABLE consignment (
    deal_code VARCHAR(12) PRIMARY KEY CHECK (deal_code ~ '^\d+$'),
    supplier_id INTEGER NOT NULL CHECK (supplier_id >= 0),                           -- ?? one supplier for one consignment
    quantity SMALLINT NOT NULL CHECK (quantity > 0),
    price_uah MONEY CHECK (price_uah < 3000000),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE),
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory ~ '^[a-zA-Z0-9\s\-"''()\[\]]+$'),
    product_code VARCHAR(100) REFERENCES auto_part(product_code) ON DELETE RESTRICT, -- one product_code for one consignment
    serial_code VARCHAR(100) NOT NULL CHECK (LENGTH(serial_code) >= 5)
);

CREATE TABLE individual_auto_part (
    individual_auto_part_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(individual_auto_part_code) < 5),
    production_date DATE NOT NULL CHECK (production_date >= '1950-01-01' AND production_date <= CURRENT_DATE),
    deal_code VARCHAR(50) REFERENCES consignment(deal_code) ON DELETE RESTRICT CHECK (TRUE) -- one one consignment for one individual auto part
);

/*
--auto_part_archive and consignment_archive will be added without time but individual_auto_part_archive will be added with time
--ooh yeah and order will reference and archive segment (individual_auto_part_archive) (each order will reference all bought items from archive segment)
*/

CREATE TABLE auto_part_archive (
    product_code VARCHAR(100) PRIMARY KEY CHECK (product_code <> ''),
    name VARCHAR(250) NOT NULL CHECK (name <> ''),
    warranty_term INTERVAL DAY NOT NULL CHECK (warranty_term >= INTERVAL '0 days' AND warranty_term <= INTERVAL '9000 days')
);

CREATE TABLE consignment_archive (
    deal_code VARCHAR(50) PRIMARY KEY CHECK (deal_code <> ''),
    supplier_id INTEGER NOT NULL CHECK (supplier_id >= 0),                                   -- one supplier for one consignment
    quantity SMALLINT NOT NULL CHECK (quantity >= 0),
    price_uah DECIMAL(8, 2) CHECK (price_uah >= 0),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE), -- can be not today so bad check
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory <> ''),
    product_code VARCHAR(100) REFERENCES auto_part_archive(product_code) ON DELETE RESTRICT, -- one product_code for one consignment
    serial_code VARCHAR(100) NOT NULL CHECK (serial_code <> '')
);

CREATE TABLE individual_auto_part_archive (
    individual_auto_part_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(individual_auto_part_code) < 5),
    purchase_code VARCHAR(50) CHECK (LENGTH(purchase_code) > 5),
    price_uah MONEY CHECK (price_uah <= 1000000),
    production_date DATE NOT NULL CHECK (production_date >= '1950-01-01' AND production_date <= CURRENT_DATE),
    deal_code VARCHAR(50) REFERENCES consignment_archive(deal_code) ON DELETE RESTRICT CHECK (TRUE) -- one one consignment for one individual auto part
);

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

ALTER TABLE consignment ADD CONSTRAINT supplier_id_fk_constraint FOREIGN KEY (supplier_id)
REFERENCES supplier (supplier_id) ON DELETE RESTRICT;

ALTER TABLE consignment_archive ADD CONSTRAINT supplier_id_fk_constraint FOREIGN KEY (supplier_id)
REFERENCES supplier (supplier_id) ON DELETE RESTRICT;


CREATE TABLE car (
    car_id SERIAL PRIMARY KEY,
    automaker VARCHAR(50) NOT NULL CHECK (automaker ~ '^[a-zA-Z0-9\s\-&]+$'),
    model VARCHAR(50) NOT NULL CHECK (model ~ '^[a-zA-Z0-9\s\-_]+$'),
    year SMALLINT NOT NULL CHECK (year > 1950 AND year < 2100),
    CONSTRAINT unique_automaker_model_year UNIQUE (automaker, model, year)
);

CREATE TABLE auto_part_compatible_car (
    product_code VARCHAR(100) NOT NULL CHECK (product_code <> ''), --Attention reference in future thus does not need check, well no but still
    car_id INTEGER REFERENCES car(car_id) ON DELETE RESTRICT,
    PRIMARY KEY (product_code, car_id)
);

CREATE TABLE admin (
    email VARCHAR(100) PRIMARY KEY CHECK (email ~ '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'),
    admin_name VARCHAR(100) NOT NULL CHECK (admin_name ~ '^[a-zA-Z ]+$'),
    admin_surname VARCHAR(100) CHECK (admin_surname ~ '^[a-zA-Z ]+$'),
    phone_number VARCHAR(21) NOT NULL CHECK (phone_number ~ '^\+?\d{5,20}$'),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 10)
);

CREATE TABLE client (
    email VARCHAR(100) PRIMARY KEY CHECK (email ~ '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'),
    client_name VARCHAR(100) NOT NULL CHECK (client_name ~ '^[a-zA-Z ]+$'),
    client_surname VARCHAR(100) CHECK (client_surname ~ '^[a-zA-Z ]+$'),
    phone_number VARCHAR(21) NOT NULL CHECK (phone_number ~ '^\+?\d{5,20}$'),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 5),
    address VARCHAR(250) CHECK (address ~ '^.{10,}$'),
    balance_uah MONEY NOT NULL CHECK (balance_uah <= 1000000)
);

CREATE TABLE purchase (
    purchase_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(purchase_code) > 5),
    email VARCHAR(100) REFERENCES client(email) ON DELETE RESTRICT,
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(purchase_time) = CURRENT_DATE),
    total_price_uah MONEY NOT NULL CHECK (total_price_uah <= 1000000)
);

ALTER TABLE individual_auto_part_archive ADD CONSTRAINT purchase_code_fk_constraint FOREIGN KEY (purchase_code)
REFERENCES purchase (purchase_code) ON DELETE RESTRICT;