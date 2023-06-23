drop table if exists results;

create table results
(
	id smallint not null,
	response text
);

-- 1. Вывести максимальное количество человек в одном бронировании

insert into results
select
	1,
	count(distinct passenger_id) as count_pas
from tickets t
group by book_ref
order by count_pas desc
limit 1;

-- 2. Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
insert into results
select
	2,
	count(*)
from (
	select
		t.book_ref,
		count(t.book_ref) as count_pas,
		avg(count(t.book_ref)) over() as avg_pas
	from tickets t
	group by t.book_ref
) as tab
where tab.count_pas > tab.avg_pas;

-- 3. Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?

with book_count as (
	select
		book_ref,
		count(passenger_id) as count_pas,
		max(count(passenger_id)) over() as max_count_pas
	from tickets
	group by book_ref
), book_info as (
	select
		*
	from tickets t
	where t.book_ref in (
		select
			book_ref
		from book_count
		where count_pas = max_count_pas
	)
)

insert into results
select
	3,
	count(distinct book1)
from (
	select
		bi1.book_ref as book1,
		bi2.book_ref as book2
	from book_info bi1, book_info bi2
	where bi1.book_ref <> bi2.book_ref
	and bi1.passenger_id = bi2.passenger_id
	group by bi1.book_ref, bi2.book_ref
	having count(*) = (
		select max_count_pas
		from book_count
		limit 1
	)
) as tab;

-- 4. Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3

insert into results
select
	4,
	tab.book_ref || tab.book_data
from (
	select
		t.book_ref,
		string_agg((' passenger id ' || t.passenger_id || ' name ' || t.passenger_name || ' data ' || t.contact_data), ', ') as book_data
	from tickets t
	where t.book_ref in (
		select
			t2.book_ref
		from tickets t2
		group by t2.book_ref
		having count(distinct t2.passenger_id) = 3
	)
	group by t.book_ref
) as tab;

-- 5. Вывести максимальное количество перелётов на бронь

insert into results
select
	5,
	count(tf.flight_id)
from tickets t
inner join ticket_flights tf on tf.ticket_no = t.ticket_no
group by t.book_ref
order by count(tf.flight_id) desc
limit 1;

-- 6. Вывести максимальное количество перелётов на пассажира в одной брони

insert into results
select
	6,
	count(tf.flight_id)
from tickets t
inner join ticket_flights tf on tf.ticket_no = t.ticket_no
group by t.book_ref, t.passenger_id
order by count(tf.flight_id) desc
limit 1;

-- 7. Вывести максимальное количество перелётов на пассажира

insert into results
select
	7,
	count(tf.flight_id)
from tickets t
inner join ticket_flights tf on tf.ticket_no = t.ticket_no
group by t.passenger_id
order by count(tf.flight_id) desc
limit 1;

-- 8. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты

insert into results
select
	8,
	concat(tab.passenger_id, ' ', tab.passenger_name, ' ', tab.contact_data, ' ', tab.sum_tic)
from (
	select
		t.passenger_id,
		t.passenger_name,
		t.contact_data,
		sum(tf.amount) as sum_tic,
		min(sum(tf.amount)) over() as min_sum_tic
	from tickets t
	inner join ticket_flights tf on tf.ticket_no = t.ticket_no
	group by t.passenger_id, t.passenger_name, t.contact_data
) as tab
where tab.sum_tic = tab.min_sum_tic;

-- 9. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах, для пассажира, который провёл максимальное время в полётах

insert into results
select
	9,
	concat(tab.passenger_id, ' ', tab.passenger_name, ' ', tab.contact_data, ' ', tab.sum_durat)
from (
	select
		t.passenger_id,
		t.passenger_name,
		t.contact_data,
		sum(fv.actual_duration) as sum_durat,
		max(sum(fv.actual_duration)) over() as max_sum_durat
	from tickets t
	inner join ticket_flights tf on t.ticket_no = tf.ticket_no
	inner join flights_v fv on tf.flight_id = fv.flight_id
	where fv.status = 'Arrived'
	group by t.passenger_id, t.passenger_name, t.contact_data
) as tab
where tab.sum_durat = tab.max_sum_durat;

-- 10. Вывести город(а) с количеством аэропортов больше одного

insert into results
select
	10,
	city
from airports a
group by city
having count(city) > 1;

-- 11. Вывести город(а), у которого самое меньшее количество городов прямого сообщения

insert into results
select
	11,
	city
from (
	select
		departure_city as city,
		count(distinct arrival_city) as count_city,
		min(count(distinct arrival_city)) over() as min_count_city
	from routes
	group by departure_city
) as tab
where tab.count_city = tab.min_count_city;

-- 12. Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

with uniq_routes as (
	select distinct
		departure_city,
		arrival_city
	from routes
), all_city as (
	select distinct
		city
	from airports r
)

insert into results
select
	12,
	concat(ac.city, ' ', ac2.city)
from all_city ac
cross join all_city ac2
where ac.city < ac2.city
and ac2.city not in (
	select
		ur.arrival_city
	from uniq_routes ur
	where ac.city = ur.departure_city
);

-- 13. Вывести города, до которых нельзя добраться без пересадок из Москвы?

with uniq_routes as (
	select distinct
		departure_city,
		arrival_city
	from routes
)

insert into results
select distinct
	13,
	r.arrival_city
from routes r
where r.arrival_city not in (
	select
		ur.arrival_city
	from uniq_routes ur
	where ur.departure_city = 'Москва'
)
and r.arrival_city <> 'Москва';

--  14. Вывести модель самолета, который выполнил больше всего рейсов

insert into results
select
	14,
	tab.model
from (
	select
		a.model,
		count(f.flight_id) as count_fl,
		max(count(f.flight_id)) over() as max_count_fl
	from aircrafts a
	inner join flights f on a.aircraft_code = f.aircraft_code
	where f.status = 'Arrived'
	group by a.model
) as tab
where tab.count_fl = tab.max_count_fl;

-- 15. Вывести модель самолета, который перевез больше всего пассажиров

insert into results
select
	15,
	tab.model
from (
	select
		a.model,
		count(bp.boarding_no) as count_bp,
		max(count(bp.boarding_no)) over() as max_count_bp
	from aircrafts a
	inner join flights f on a.aircraft_code = f.aircraft_code
	inner join boarding_passes bp on f.flight_id = bp.flight_id
	where f.status = 'Arrived'
	group by a.model
) as tab
where tab.count_bp = tab.max_count_bp;

-- 16. Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам

insert into results
select
	16,
	EXTRACT(EPOCH from (sum(scheduled_duration)-sum(actual_duration)))/60
from flights_v fv
where fv.status = 'Arrived';

-- 17. Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13

insert into results
select distinct
	17,
	arrival_city
from flights_v
where departure_city = 'Санкт-Петербург'
and status = 'Arrived'
and date(actual_departure) = '2016-09-13';

-- 18. Вывести перелёт(ы) с максимальной стоимостью всех билетов

insert into results
select
	18,
	tab.flight_id
from (
	select
		f.flight_id,
		sum(tf.amount) as sum_amount,
		max(sum(tf.amount)) over() as max_sum_amount
	from flights f
	inner join ticket_flights tf on f.flight_id = tf.flight_id
	group by f.flight_id
) as tab
where tab.sum_amount = tab.max_sum_amount;

-- 19. Выбрать дни в которых было осуществлено минимальное количество перелётов

insert into results
select
	19,
	tab.date_depart
from (
	select
		date(actual_departure) as date_depart,
		count(*) as count_fl,
		min(count(*)) over() as min_count_fl
	from flights f
	where status = 'Departed'
	or status = 'Arrived'
	group by date(actual_departure)
	order by date(actual_departure)
) as tab
where tab.count_fl = tab.min_count_fl;

-- 20. Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года

insert into results
select
	20,
	avg(tab.count_fl)
from (
	select
		count(*) as count_fl
	from flights_v
	where (
		status = 'Departed'
		or status = 'Arrived'
	) and departure_city = 'Москва'
	and extract(month from actual_departure) = '09'
	and extract(year from actual_departure) = '2016'
	group by date(actual_departure)
) as tab;

-- 21. Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

insert into results
select
	21,
	departure_city
from flights_v
group by departure_city
having avg(actual_duration) > interval '3 hours'
order by avg(actual_duration) desc
limit 5;
