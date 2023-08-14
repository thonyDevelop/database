create database apptest;

create table users(
	id serial primary key,
	email varchar(100),
	status varchar(1),
	insert_date timestamp not null default to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS')::timestamp without time zone
);

ALTER TABLE public.users ADD CONSTRAINT users_un UNIQUE (email);


create table "DamagexUsuario"(
	id serial primary key,
	user_id integer,
	observation text,
	latitude numeric(10,4),
	longitude numeric(10,4),
	constraint fk0 foreign key (user_id) references users(id)
);

create table logger(
	id serial primary key ,
	damage_id integer,
	user_id integer,
	observation text,
	latitude numeric(10,4),
	longitude numeric(10,4),
	insert_date timestamp not null default to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS')::timestamp without time zone
)


CREATE OR REPLACE FUNCTION fnc_trg_notify_damage_register()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
	SET LOCAL timezone = 'America/Bogota';
	insert into logger(damage_id, user_id, observation, latitude, longitude) 
	values(new.id, new.user_id, new.observation, new.latitude, new.longitude);
	
	return new;
end;
$function$
;

create trigger trg_notify_damage_register after
insert
    on
    "DamagexUsuario" for each row execute function fnc_trg_notify_damage_register();

   
   
create table "DamageDetail"(
	id serial primary key,
	damage_id integer,
	image text,
	status varchar(1),
	insert_date timestamp not null default to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS')::timestamp without time zone,
	constraint fk1 foreign key (damage_id) references "DamagexUsuario"(id)
);

create or replace function fnc_damage_register(data jsonb)
returns table (status int, message text)
language plpgsql
as $function$
declare 
	v_response				json;
	v_user_id 				int;
	v_observation 			text;
	v_latitude 				numeric(10,4);
	v_longitude 			numeric(10,4);
	v_images 				jsonb;
	v_id_damage 			int;
	v_item 					jsonb;
begin 
	SET LOCAL timezone = 'America/Bogota';
	
	v_user_id 		:= (data ->>'user_id')::int;
	v_observation 	:= (data ->> 'observation')::text;
	v_latitude 		:= (data ->> 'latitude')::numeric(10,4);
	v_longitude 	:= (data ->> 'longitude')::numeric(10,4);
	v_images 		:= (data -> 'images')::jsonb;

	insert into "DamagexUsuario"(user_id, observation, latitude, longitude)
	values(v_user_id, v_observation, v_latitude, v_longitude) returning id into v_id_damage;

	for v_item in select jsonb_array_elements(v_images) loop
		insert into "DamageDetail"(damage_id, image, status)
		values(v_id_damage, v_item->>'image','A');
	end loop;
	return query select 200 as status,'damage register' as message ;
end;
$function$;