# htree

A simple hierarchical tree store backed by SQLite.

## About

`htree` is a command-line tool for storing and managing arbitrary hierarchical data.

Each item can either be a top-level item or a child of another item. Items can have children to any depth, allowing you to build trees that fit your own needs.

Supported operations:

- **search** — find items by name and display their descendants
- **add** — create a new item
- **delete** — delete an item and its entire subtree
- **move** — move an item and its entire subtree to a new parent

Items can optionally have a description and a date (`dt`), and every item has a unique ID used by operations such as `move` and `delete`.

See `htree --help` for the complete list of options.

## Usage

Build the application:

```console
$ cabal build
```

Run it with:

```console
$ cabal run htree -- <arguments>
```

### View help

```console
$ cabal run htree -- --help
```

### Search

Search for items by name (case insensitive). Matching items are displayed along with their descendants.

```console
$ cabal run htree -- --search "Oil"
Cars > 2023 Royal Enfield Scram 411 > Oil Change - Miles: 600 (2025-08-03) [9]
Cars > 2026 Honda CB750 Hornet > Oil Change - Miles: 4000 (2026-09-01) [7]
...
```

Searches can match either an exact name or part of a name.

### Add an item

Create an item with just a name:

```console
$ cabal run htree -- --add "Item name"
```

Optional fields can be supplied when creating an item:

```console
$ cabal run htree -- --add "Item name" \
    --description "Item description" \
    --dt "2026-02-15" \
    --parent 3
```

`--parent` specifies the ID of the item's parent. If omitted, the item is created as a top-level item.

### Move an item

Move item `3` under item `5`. The item's entire subtree moves with it:

```console
$ cabal run htree -- --move 3 5
```

### Delete an item

Delete item `5` and its entire subtree:

```console
$ cabal run htree -- --delete 5
```

### Specify database file

The default database file is set at config/htree.env: DB_FILE

Override it on the command line. It will be created if it doesn't exist.

```console
$ cabal run htree -- --db "test.db" --add "Item name"
```
