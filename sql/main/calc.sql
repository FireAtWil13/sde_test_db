
drop table if exists results;

create table results (
 id integer, 
 response text
)
;


--1.	Вывести максимальное количество человек в одном бронировании
INSERT INTO results
select 1 as id, count(ticket_no) as bookings from bookings.tickets b group by book_ref
order by count(ticket_no) desc limit 1
;


--2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
INSERT INTO results
select 2 as id,count(book_ref) from (
	select book_ref, bookings, avg(bookings) over () as book_avg
	from (
		select book_ref, count(ticket_no) as bookings from bookings.tickets b group by book_ref
	) t1
) t2
where bookings > book_avg
;


--3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, 
--среди бронирований с максимальным количеством людей (п.1)?
INSERT INTO results
select 3 id, count(*)
from(
	select book_ref, passenger_id, passenger_name, count(passenger_id) over (partition by book_ref) as book_count from bookings.tickets
	) b1
left join (
	select book_ref, passenger_id, passenger_name, count(passenger_id) over (partition by book_ref) as book_count from bookings.tickets
	) b2 on b1.passenger_id = b2.passenger_id
where b1.book_ref != b2.book_ref
and b1.book_count = b2.book_count
and b1.book_count = (select count(ticket_no) as bookings from bookings.tickets b group by book_ref
order by count(ticket_no) desc limit 1);


--4.	Вывести номера брони и контактную информацию по пассажирам в брони 
--(passenger_id, passenger_name, contact_data) с количеством людей в брони = 3
INSERT INTO results
select 4 id, book_ref||'|'||passenger_id||'|'||passenger_name||'|'||contact_data res 
from bookings.tickets b1 where book_ref in 
(
select book_ref from bookings.tickets b2
group by book_ref
having count(passenger_id) = 3
)
order by book_ref
;


--5.	Вывести максимальное количество перелётов на бронь
--(НЕ СЧТИАЕМ РАЗНЫХ ЛЮДЕЙ В БРОНИ ЗА РАЗНЫЕ ПЕРЕЛЕТЫ, количество уникальных flight_id на бронь)
--считаем перелеты самолетов на бронь
INSERT INTO results
select 5 id , count(distinct tf.flight_id)  
from bookings.tickets t
left join bookings.Ticket_flights tf on t.ticket_no = tf.ticket_no 
group by t.book_ref
order by count(distinct tf.flight_id) desc
limit 1
;


--6.	Вывести максимальное количество перелётов на пассажира в одной брони
INSERT INTO results
select 6 id, count(distinct tf.flight_id)  
from bookings.tickets t
left join bookings.Ticket_flights tf on t.ticket_no = tf.ticket_no 
group by t.book_ref, t.passenger_id
order by count(distinct tf.flight_id) desc
limit 1
;


--7.	Вывести максимальное количество перелётов на пассажира
INSERT INTO results
select 7 id,
count(distinct tf.flight_id)  
from bookings.tickets t
left join bookings.Ticket_flights tf on t.ticket_no = tf.ticket_no 
group by t.passenger_id
order by count(distinct tf.flight_id) desc
limit 1
;


--8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) 
--и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
with t1 as (select * from bookings.tickets t
left join bookings.Ticket_flights tf on t.ticket_no = tf.ticket_no)

INSERT INTO results
select 8 id,
passenger_id||'|'||passenger_name||'|'||contact_data||'|'||sum(amount) as res 
from t1
group by passenger_id, passenger_name, contact_data
having sum(amount) =
	(
	select sum(amount) as min_sum from t1
	group by passenger_id
	order by sum(amount)
	limit 1)
;


--9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) 
--и общее время в полётах, для пассажира, который провёл максимальное время в полётах
with t1 as (
select
passenger_id, passenger_name, contact_data,
sum(coalesce(f.actual_arrival, f.scheduled_arrival)-coalesce(f.actual_departure, f.scheduled_departure)) as flight_time 
from bookings.Ticket_flights tf
left join bookings.tickets t on t.ticket_no = tf.ticket_no
left join bookings.flights f on tf.flight_id = f.flight_id
group by passenger_id, passenger_name, contact_data
order by sum(coalesce(f.actual_arrival, f.scheduled_arrival)-coalesce(f.actual_departure, f.scheduled_departure))  desc
)

INSERT INTO results
select 9 id, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||flight_time from t1
where flight_time = (select max(flight_time) from t1)
;


--10.	Вывести город(а) с количеством аэропортов больше одного
INSERT INTO results
select 10 id, city from bookings.airports
group by city
having count(airport_code) > 1
order by city
;


--11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
INSERT INTO results
select 11 id, departure_city from (
select r.departure_city, 
rank() over (order by count(r.arrival_city)) as rk
from bookings.routes r
group by r.departure_city
order by count(r.arrival_city)
) t1
where rk = 1
;


--12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
INSERT INTO results
select 12, city1||'|'||city2 from (
select ad1.city as city1, ad2.city as city2
	from bookings.airports ad1
	inner join bookings.airports ad2 on
	ad1.city < ad2.city
except
select distinct departure_city, arrival_city from
(
select departure_city, arrival_city
 from routes
 union all
 select arrival_city, departure_city
 from routes)t2
) t1
;


--13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?
INSERT INTO results
select distinct 13 id, departure_city 
from routes r
where
departure_city not in (select arrival_city from routes where departure_city = 'Москва')
and departure_city != 'Москва'
;


--14.	Вывести модель самолета, который выполнил больше всего рейсов
INSERT INTO results
select 14 id, a.model from bookings.flights_v f
inner join bookings.aircrafts a on f.aircraft_code = a.aircraft_code 
group by f.aircraft_code, a.model
order by count(flight_id) desc
limit 1
;


--15.	Вывести модель самолета, который перевез больше всего пассажиров
INSERT INTO results
select 15 id, a.model
from  bookings.flights_v f
inner join (select flight_id, count(ticket_no) as passnegers from bookings.ticket_flights group by flight_id) tf on f.flight_id = tf.flight_id
inner join bookings.aircrafts a on f.aircraft_code = a.aircraft_code
where actual_departure is not null
group by f.aircraft_code, a.model
order by sum(passnegers) desc
limit 1
;


--16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
INSERT INTO results
select 16, EXTRACT(EPOCH FROM sum(actual_duration)-sum(scheduled_duration)::INTERVAL)/60 as diff
from  bookings.flights_v f
where actual_duration is not null
;


--17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13
INSERT INTO results
select distinct 17, arrival_city
from  bookings.flights_v f
where f.actual_departure::date = '2016-09-13'::date and 
departure_city = 'Санкт-Петербург'
;


--18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
INSERT INTO results
select 18 id, flight_id from
(
	select flight_id, sum(amount) as total_am, dense_rank() over (order by sum(amount) desc) as rk from bookings.ticket_flights group by flight_id
) t1
where rk = 1
limit 1
;


--19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
INSERT INTO results
select 19, fd
from
(
	select f.actual_departure::date as fd, count(flight_id) as cnt, dense_rank() over (order by count(flight_id)) as rk  from  bookings.flights_v f
	group by f.actual_departure::date
) t1
where rk = 1
limit 1
;


--20.	Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года (изменил на 07-2017)
INSERT INTO results
select 20, avg(fl_cnt) from 
(
	select to_char(coalesce(actual_departure_local , scheduled_departure_local), 'YYYY-MM-dd') as dt, count(flight_id) as fl_cnt from bookings.flights_v f
	where to_char(coalesce(actual_departure_local , scheduled_departure_local), 'YYYY-MM') = '2017-07'
	and departure_city = 'Москва'
	and status in ('Departed','Arrived')
	group by to_char(coalesce(actual_departure_local , scheduled_departure_local), 'YYYY-MM-dd')
) t1
;


--21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
INSERT INTO results
select 21, departure_city
from  bookings.routes r 
group by departure_city
having EXTRACT(EPOCH FROM avg(duration))/3600 < 3
order by avg(duration)
limit 5
;