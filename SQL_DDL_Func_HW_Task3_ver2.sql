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
	AND NOT EXISTS (SELECT 1 FROM public.film pf WHERE LOWER(pf.title)=LOWER($1) AND  pf.release_year =$2)
	RETURNING film_id INTO v_film_id;
	RETURN COALESCE(v_film_id,'-1');
END;
$function$;
COMMIT;


/*
Check how it works
drop function public.insert_new_movie(text,year,text);

SELECT * from public.insert_new_movie('kitty');
SELECT * from public.insert_new_movie('hello world','2020','english');

*/
