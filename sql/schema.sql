create table if not exists item (
    id integer primary key not null,
    name text not null,
    description text,
    dt text,
    parent_id integer,
    created text not null default current_timestamp
);

insert into item (name, description, dt, parent_id) values
('2026 Honda CB750 Hornet', null, null, null),
('Oil Change', 'Miles: 4000', '2026-09-01', 1),
('New tires', 'Michelin Road 5', '2026-09-10', 1)
;
