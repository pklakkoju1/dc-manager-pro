-- Run this on existing installs to update server_type options
-- docker exec dcm_postgres psql -U dcuser -d dcmanager -f /tmp/migrate-server-types.sql

UPDATE hw_fields 
SET options = 'Rack Server
Tower
Blade
Dense Server
High-Density
Virtual
VM
Type-A
Type-B
Type-C
Type-D
Type-E
Type-F
Type-S
Type-T
Type-X
Type-Y
Type-Z
Other'
WHERE field_key = 'server_type';
