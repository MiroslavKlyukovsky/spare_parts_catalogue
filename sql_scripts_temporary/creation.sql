/*
product_code (always unique) - says brand and exact auto part purpose
serial_code (not always unique) - says from which series is the auto part (factory, subtype of exact auto part)
individual_auto_part_code (always unique) - identifies an individual auto part from all others
*/

-- email must be varchar(100) CHECK (LENGTH(email) >= 3); (primary key)
-- name must be varchar(100) NOT NULL CHECK (name <> '');
-- surname must be varchar(100) CHECK (surname <> '');
-- password must be varchar(50) NOT NULL CHECK (LENGTH(password) >= 5); LENGTH 10 for admin
-- is_admin must be boolean NOT NULL; (regular user = 0, admin = 1)
-- phone number must be varchar(20) NOT NULL CHECK (LENGTH(phone_number) >= 5)
-- address must be varchar(250) CHECK (LENGTH(address) >= 10)

--

-- Зробити тригери коли додається один елемент в архів іде додавання батьківських сутностей з певною кількістю
CREATE TABLE auto_part (
    product_code VARCHAR(100) PRIMARY KEY CHECK (product_code <> ''),
    name VARCHAR(250) NOT NULL CHECK (name <> ''),
    price DECIMAL(8, 2) CHECK (price >= 0),
    warranty_term INTERVAL DAY NOT NULL CHECK (warranty_term >= INTERVAL '0 days' AND warranty_term <= INTERVAL '9000 days')
);

CREATE TABLE consignment (
    deal_code VARCHAR(50) PRIMARY KEY CHECK (deal_code <> ''),
    supplier_id INTEGER NOT NULL CHECK (supplier_id >= 0),                           -- one supplier for one consignment
    quantity SMALLINT NOT NULL CHECK (quantity >= 0),
    price DECIMAL(8, 2) CHECK (price >= 0),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE),
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory <> ''),
    product_code VARCHAR(100) REFERENCES auto_part(product_code) ON DELETE RESTRICT, -- one product_code for one consignment
    serial_code VARCHAR(100) NOT NULL CHECK (serial_code <> '')
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
    price DECIMAL(8, 2) CHECK (price >= 0),
    deal_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(deal_time) = CURRENT_DATE),
    producing_factory VARCHAR(250) NOT NULL CHECK (producing_factory <> ''),
    product_code VARCHAR(100) REFERENCES auto_part_archive(product_code) ON DELETE RESTRICT, -- one product_code for one consignment
    serial_code VARCHAR(100) NOT NULL CHECK (serial_code <> '')
);

CREATE TABLE individual_auto_part_archive (
    individual_auto_part_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(individual_auto_part_code) < 5),
    purchase_code VARCHAR(50) CHECK (LENGTH(purchase_code) > 5),
    price DECIMAL(8, 2) CHECK (price >= 0),
    production_date DATE NOT NULL CHECK (production_date >= '1950-01-01' AND production_date <= CURRENT_DATE),
    deal_code VARCHAR(50) REFERENCES consignment_archive(deal_code) ON DELETE RESTRICT CHECK (TRUE) -- one one consignment for one individual auto part
);

CREATE TABLE supplier (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL CHECK (name <> ''),
    office_address VARCHAR(250) NOT NULL CHECK (LENGTH(office_address) >= 10),
    phone_number VARCHAR(20) NOT NULL CHECK (LENGTH(phone_number) >= 5),
    email VARCHAR(100) NOT NULL CHECK (LENGTH(email) >= 3),
    contact_person_name VARCHAR(75) NOT NULL CHECK (contact_person_name <> ''),
    contact_person_surname VARCHAR(75) CHECK (contact_person_surname <> ''),
    CONSTRAINT unique_name_office_address_phone_number_email UNIQUE (name, office_address, phone_number, email)
);

ALTER TABLE consignment ADD CONSTRAINT supplier_id_fk_constraint FOREIGN KEY (supplier_id)
REFERENCES supplier (supplier_id) ON DELETE RESTRICT;

ALTER TABLE consignment_archive ADD CONSTRAINT supplier_id_fk_constraint FOREIGN KEY (supplier_id)
REFERENCES supplier (supplier_id) ON DELETE RESTRICT;


CREATE TABLE car (
    car_id SERIAL PRIMARY KEY,
    automaker VARCHAR(50) NOT NULL CHECK (automaker <> ''),
    model VARCHAR(50) NOT NULL CHECK (model <> ''),
    year SMALLINT NOT NULL CHECK (year > 1950 AND year < 2100),
    CONSTRAINT unique_automaker_model_year UNIQUE (automaker, model, year)
);

CREATE TABLE auto_part_compatible_car (
    product_code VARCHAR(100) CHECK (product_code <> ''),
    car_id INTEGER REFERENCES car(car_id) ON DELETE RESTRICT,
    PRIMARY KEY (product_code, car_id)
);

CREATE TABLE admin (
    email VARCHAR(100) PRIMARY KEY CHECK (LENGTH(email) >= 3),
    admin_name VARCHAR(100) NOT NULL CHECK (admin_name <> ''),
    admin_surname VARCHAR(100) CHECK (admin_surname <> ''),
    phone_number VARCHAR(20) NOT NULL CHECK (LENGTH(phone_number) >= 5),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 10)
);

CREATE TABLE client (
    email VARCHAR(100) PRIMARY KEY CHECK (LENGTH(email) >= 3),
    client_name VARCHAR(100) NOT NULL CHECK (client_name <> ''),
    client_surname VARCHAR(100) CHECK (client_surname <> ''),
    phone_number VARCHAR(20) NOT NULL CHECK (LENGTH(phone_number) >= 5),
    password VARCHAR(50) NOT NULL CHECK (LENGTH(password) >= 5),
    address VARCHAR(250) CHECK (LENGTH(address) >= 10),
    balance_uah MONEY CHECK (balance_uah <= 1000000)
);

CREATE TABLE purchase (
    purchase_code VARCHAR(50) PRIMARY KEY CHECK (LENGTH(purchase_code) > 5),
    email VARCHAR(100) REFERENCES client(email) ON DELETE RESTRICT CHECK (LENGTH(email) >= 3),
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (DATE(purchase_time) = CURRENT_DATE),
    total_price DECIMAL(8, 2) CHECK (total_price >= 0)
);

ALTER TABLE individual_auto_part_archive ADD CONSTRAINT purchase_code_fk_constraint FOREIGN KEY (purchase_code)
REFERENCES purchase (purchase_code) ON DELETE RESTRICT;