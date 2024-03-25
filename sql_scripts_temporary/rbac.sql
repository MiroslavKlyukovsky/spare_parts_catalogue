CREATE ROLE client_role;
CREATE ROLE admin_role;


GRANT SELECT (email, client_name, client_surname, phone_number, password, address, balance_uah) ON client TO client_role;
GRANT UPDATE (client_name, client_surname, phone_number, password, address) ON client TO client_role;
GRANT SELECT (purchase_code, email, purchase_time, total_price_uah) ON purchase TO client_role;
GRANT SELECT (individual_auto_part_code, purchase_code, price_uah, production_date, deal_code) ON individual_auto_part_archive TO client_role;
