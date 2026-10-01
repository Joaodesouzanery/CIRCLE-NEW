-- Circle — Migração 0004: extensões fora de public e agendamento das notificações
create schema if not exists extensions;
alter extension pg_trgm set schema extensions;
alter extension unaccent set schema extensions;
-- índices GIN existentes continuam válidos (dependem do OID da classe de operadores)

create extension if not exists pg_cron;
select cron.schedule('circle_gen_notifications', '0 11,15,20 * * 1-5', 'select public.fn_generate_notifications()');
