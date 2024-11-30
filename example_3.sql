-- TABLES --
DROP TABLE IF EXISTS executed_tasks;

CREATE TABLE executed_tasks (
	id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	"name" text NOT NULL,
	start_at timestamp NOT NULL,
  completed_at timestamp NOT NULL
);

-- EXAMPLE DATA --

/*

start multiple instances: psql -h 127.0.0.1 example -U postgres

*/


TRUNCATE executed_tasks RESTART IDENTITY;

INSERT INTO executed_tasks ("name", start_at, completed_at) 
  VALUES('other-tasks', '2021-01-01', '2021-01-01');
INSERT INTO executed_tasks ("name", start_at, completed_at) 
  VALUES('good_morning', now() - INTERVAL '65 minutes', now() - INTERVAL '62 minutes');

SELECT * FROM executed_tasks et ;

SELECT hashtext('cronjob'), hashtext('good_morning');

SELECT 
  pg_try_advisory_xact_lock(hashtext('cronjob'), hashtext('good_morning'))::boolean as lock_taken,
  now() - COALESCE((SELECT max(completed_at) FROM	executed_tasks WHERE name = 'good_morning'), '2000-01-01') as elapsed
;

DO
$do$
DECLARE
  result RECORD;
  start_at timestamp;
BEGIN
  start_at = CLOCK_TIMESTAMP();
  SELECT 
    pg_try_advisory_xact_lock(hashtext('cronjob'),	hashtext('good_morning'))::boolean as lock_taken,
    now() - COALESCE((SELECT max(completed_at) FROM	executed_tasks WHERE name = 'good_morning'), '2000-01-01') as elapsed
    INTO result;
  RAISE NOTICE 'Result: %', result;
  IF (result.lock_taken AND result.elapsed > INTERVAL '60 minutes') THEN
    RAISE NOTICE 'Lock taken, waiting 10 sec';
    PERFORM pg_sleep(10);
    INSERT INTO executed_tasks ("name", start_at, completed_at) values('good_morning', start_at, CLOCK_TIMESTAMP());
  ELSE
    RAISE NOTICE 'Unable to execute task %', result;
  END IF;
END
$do$;

SELECT * FROM executed_tasks et ;
