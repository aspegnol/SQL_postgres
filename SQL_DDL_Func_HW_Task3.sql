CREATE OR REPLACE FUNCTION public.insert_new_movie(IN f_name text, release_year year DEFAULT date_part('YEAR',now()), language text DEFAULT 'Klingon' )
RETURNS BIGINT
LANGUAGE plpgsql
AS
$function$
DECLARE 
	v_film_id BIGINT;
BEGIN
	INSERT INTO public."language" (name)
	SELECT ($3)
	WHERE NOT EXISTS (SELECT 1 FROM public."language" l WHERE LOWER(l."name")=LOWER($3));

	INSERT INTO public.film (title, release_year,language_id)
	SELECT ($1), ($2), language_id
	FROM public."language"  la2
	WHERE LOWER(la2."name")=LOWER($3)
	RETURNING film_id INTO v_film_id;
	RETURN v_film_id;
END;
$function$;
COMMIT;


/*
Check how it works

SELECT * from public.insert_new_movie('kitty');
SELECT * from public.insert_new_movie('hello world','2020','english');

*/
