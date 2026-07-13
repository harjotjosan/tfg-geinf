CREATE TABLE IF NOT EXISTS car_parts (
    id SERIAL PRIMARY KEY,
    part_number VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL,
    manufacturer VARCHAR(80) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    unit_price NUMERIC(10,2) NOT NULL,
    compatibility TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO car_parts (part_number, name, category, manufacturer, stock, unit_price, compatibility) VALUES
('BRK-1001', 'Front Brake Pads Set', 'Brakes', 'Brembo', 42, 59.90, 'VW Golf Mk7, Audi A3 8V'),
('OIL-2001', 'Oil Filter', 'Engine', 'Bosch', 85, 8.40, 'BMW 1 Series F20, Mini Cooper F56'),
('SUS-3001', 'Rear Shock Absorber', 'Suspension', 'KYB', 19, 74.99, 'Ford Focus III 2011-2018'),
('ELC-4001', 'Alternator 120A', 'Electrical', 'Valeo', 11, 189.00, 'Renault Megane III 1.5 dCi'),
('CLG-5001', 'Radiator Fan', 'Cooling', 'Denso', 27, 129.50, 'Toyota Corolla E150 1.6');

-- Extra scaffold dataset: 120 additional entries for richer testing/demo usage.
INSERT INTO car_parts (part_number, name, category, manufacturer, stock, unit_price, compatibility)
SELECT
    format('PT-%04s', gs::text) AS part_number,
    format('%s Component %s',
        (ARRAY['Brake','Oil','Filter','Suspension','Cooling','Electrical','Transmission','Exhaust','Steering','Fuel'])[(gs % 10) + 1],
        gs
    ) AS name,
    (ARRAY['Brakes','Engine','Suspension','Cooling','Electrical','Transmission','Exhaust','Steering','Fuel System','Body'])[(gs % 10) + 1] AS category,
    (ARRAY['Bosch','Brembo','Valeo','Denso','SKF','Mahle','NGK','Mann-Filter','Sachs','Monroe'])[(gs % 10) + 1] AS manufacturer,
    5 + ((gs * 7) % 95) AS stock,
    ROUND((12 + (gs * 1.83))::numeric, 2) AS unit_price,
    format('%s / %s / %s',
        (ARRAY['VW Golf VII','Audi A3 8V','BMW 3 Series F30','Ford Focus III','Toyota Corolla E170'])[(gs % 5) + 1],
        (ARRAY['Seat Leon 5F','Skoda Octavia III','Renault Megane IV','Peugeot 308 T9','Opel Astra K'])[(gs % 5) + 1],
        (ARRAY['2012-2016','2014-2018','2015-2019','2013-2017','2016-2020'])[(gs % 5) + 1]
    ) AS compatibility
FROM generate_series(6001, 6120) AS gs
ON CONFLICT (part_number) DO NOTHING;
