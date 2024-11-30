-- FUNCTIONS --

CREATE OR REPLACE FUNCTION notify_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
      PERFORM pg_notify('events_notifications',to_json(new)::text);
      return new;
    END;
      $function$
;


CREATE OR REPLACE FUNCTION save_history_event()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
      pk_column VARCHAR;
      pk_val    TEXT;
    BEGIN
      pk_column := TG_ARGV[0];
      IF (TG_OP = 'DELETE') THEN 
            pk_val := row_to_json(OLD)->>pk_column;  
      ELSIF (TG_OP = 'UPDATE') then
            pk_val := row_to_json(NEW)->>pk_column;  
      ELSIF (TG_OP = 'INSERT') THEN
            pk_val := row_to_json(NEW)->>pk_column;  
      END IF;
      execute format('INSERT INTO history_events (id, table_name, action_name, external_id) values (gen_random_uuid(), %L, %L, %L)', TG_TABLE_NAME, TG_OP, pk_val);
      RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
    $function$
;

-- TYPES --

CREATE TYPE "history_events_action" AS ENUM ('INSERT', 'UPDATE', 'DELETE');

-- TABLES --

CREATE TABLE "StrangeTable1" (
  "StrangeTable1Pk" serial4 PRIMARY KEY NOT NULL,
  "value1" text NOT NULL,
  "value2" integer NOT NULL
);

CREATE TABLE "StrangeTable2" (
  "StrangeTable2Pk" serial PRIMARY KEY NOT NULL,
  "value1" integer NOT NULL,
  "value2" timestamp NOT NULL
);

CREATE TABLE history_events (
	id uuid NOT NULL,
	table_name text NOT NULL,
	action_name "history_events_action" NOT NULL,
	external_id text NOT NULL,
	created_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
	seq serial4 NOT NULL,
	CONSTRAINT history_events_pkey PRIMARY KEY (id)
);

-- TRIGGERS --

CREATE OR REPLACE TRIGGER save_history_events AFTER INSERT OR DELETE OR UPDATE
ON "StrangeTable1"
FOR EACH ROW EXECUTE FUNCTION save_history_event('StrangeTable1Pk');

CREATE OR REPLACE TRIGGER save_history_events AFTER INSERT OR DELETE OR UPDATE
ON "StrangeTable2"
FOR EACH ROW EXECUTE FUNCTION save_history_event('StrangeTable2Pk');

CREATE OR REPLACE TRIGGER trigger_notify_change AFTER
INSERT
    ON
    history_events FOR EACH ROW EXECUTE FUNCTION notify_change();

   
-- EXAMPLE DATA --

/*

start multiple instances: psql -h 127.0.0.1 example -U postgres
LISTEN events_notifications;

*/

TRUNCATE TABLE "StrangeTable1" RESTART IDENTITY;
TRUNCATE TABLE "StrangeTable2" RESTART IDENTITY;
TRUNCATE TABLE "history_events" RESTART IDENTITY;

INSERT INTO "StrangeTable1" ("value1", "value2") VALUES ('value1', 1);
INSERT INTO "StrangeTable1" ("value1", "value2") VALUES ('value2', 2);

INSERT INTO "StrangeTable2" ("value1", "value2") VALUES (101, '2001-01-01');
INSERT INTO "StrangeTable2" ("value1", "value2") VALUES (102, '2001-01-02');

SELECT * FROM "StrangeTable1";
SELECT * FROM "StrangeTable2";

SELECT * FROM history_events he ; 
 
INSERT INTO "StrangeTable1" ("value1", "value2") VALUES ('value1', 1);
INSERT INTO "StrangeTable1" ("value1", "value2") VALUES ('value2', 2);

SELECT * FROM history_events he ; 

INSERT INTO "StrangeTable2" ("value1", "value2") VALUES (101, '2001-01-01');
INSERT INTO "StrangeTable2" ("value1", "value2") VALUES (102, '2001-01-02');

SELECT * FROM history_events he ; 

UPDATE "StrangeTable1" SET "value1" = 'value1_1' WHERE "StrangeTable1Pk" = 1;
UPDATE "StrangeTable2" SET "value1" = 42  WHERE "StrangeTable2Pk" = 1;

SELECT * FROM history_events he ; 

UPDATE "StrangeTable1" SET "value2" = value2 + 1;

SELECT * FROM history_events he ; 

DELETE FROM "StrangeTable1" WHERE "StrangeTable1Pk" = 1;
DELETE FROM "StrangeTable2" WHERE "StrangeTable2Pk" = 1;

SELECT * FROM history_events he ; 

TRUNCATE TABLE "StrangeTable1" RESTART IDENTITY;
TRUNCATE TABLE "StrangeTable2" RESTART IDENTITY;

SELECT * FROM history_events he ; 

SELECT pg_notify('events_notifications', 'ciao');









