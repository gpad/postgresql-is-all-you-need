-- FUNCTIONS --

CREATE OR REPLACE FUNCTION public.notify_new_message()
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

DROP TABLE IF EXISTS public.messages;

CREATE TABLE public.messages (
	id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	seq bigserial NOT NULL,
	"type" text NOT NULL,
	"content" json NOT NULL
);

-- TRIGGERS --

CREATE or replace TRIGGER notify_new_message AFTER
INSERT
    ON
    public.messages FOR EACH ROW EXECUTE FUNCTION notify_new_message();

-- EXAMPLE DATA --
