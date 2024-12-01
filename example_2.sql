-- FUNCTIONS --

CREATE OR REPLACE FUNCTION notify_new_message()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  BEGIN
    PERFORM pg_notify('messages_channel',to_json(new)::text);
    return new;
  END;
  $function$
;

-- TABLES --

DROP TABLE IF EXISTS messages;

CREATE TABLE messages (
	id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	seq bigserial NOT NULL,
	"type" text NOT NULL,
	"content" json NOT NULL
);

-- TRIGGERS --

CREATE OR REPLACE TRIGGER notify_new_message AFTER
INSERT
    ON
    messages FOR EACH ROW EXECUTE FUNCTION notify_new_message();

-- EXAMPLE DATA --

/*

start multiple instances: psql -h 127.0.0.1 example -U postgres
LISTEN messages_channel;

*/

TRUNCATE messages RESTART identity;
   
INSERT INTO messages ("type", "content") VALUES('do-job-1', '{"a": 1}');
INSERT INTO messages ("type", "content") VALUES('do-job-2', '{"a": 1}');
INSERT INTO messages ("type", "content") VALUES('do-job-3', '{"a": 1}');
INSERT INTO messages ("type", "content") VALUES('do-job-4', '{"a": 1}');

SELECT * FROM messages;

BEGIN;
SELECT * FROM messages ORDER BY seq LIMIT 1 FOR UPDATE SKIP LOCKED;

-- GENERATE PDF ...

DELETE FROM messages WHERE id = '';
COMMIT;

SELECT * FROM messages;