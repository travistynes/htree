create table if not exists item (
    id integer primary key not null,
    name text not null,
    description text,
    dt text,
    parent_id integer,
    created text not null default current_timestamp,

    foreign key (parent_id)
        references item(id)
        on delete cascade
);
