create table if not exists item (
    id integer primary key not null,
    name text not null,
    description text,
    dt text,
    parent_id integer,
    created text not null default current_timestamp
);

insert into item (id, name, description, dt, parent_id) values
(1, 'Cars', null, null, null),
(2, 'Tools', null, null, null),
(3, '2025 Honda CB750 Hornet', null, null, 1),
(4, '2023 Royal Enfield Scram 411', null, null, 1),
(null, 'Hammer', null, null, 2),
(null, 'Screwdriver', null, null, 2),
(null, 'Oil Change', 'Miles: 4000', '2026-09-01', 3),
(null, 'Oil Change', 'Miles: 600', '2025-08-03', 3),
(null, 'Oil Change', 'Miles: 600', '2025-08-03', 4),
(null, 'New tires', 'Michelin Road 5', '2026-09-10', 3)
;
