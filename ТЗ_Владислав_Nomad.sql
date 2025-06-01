-- Создание пользователя - схема для ТЗ - NOMAD
CREATE USER TASK_SCHEMA IDENTIFIED BY strong_password56567$TFGG;

GRANT CREATE SESSION TO TASK_SCHEMA;
GRANT CREATE TABLE TO TASK_SCHEMA;
GRANT CREATE SEQUENCE TO TASK_SCHEMA;
GRANT CREATE PROCEDURE TO TASK_SCHEMA;
GRANT UNLIMITED TABLESPACE TO TASK_SCHEMA;


/*
Задание выполнил: Владислав
WhatsApp: +77477730375.
GitHub:
Telegram: https://t.me/welstem.
Gmail: vladislavchap20@gmail.com

Кодировка базы данных в UTF-8

=== Задание №1
*/

create table department(
  department_id integer,
  name varchar2(256 char),
  constraint pk_department primary key(department_id)
);
comment on table department is 'Отделы компании';

create table employee(
  employee_id integer,
  department_id integer not null,
  chief_id integer not null,
  name varchar2(256 char),
  salary number,
  constraint pk_employee primary key(employee_id)
);

comment on table employee is 'Сотрудники компании';
comment on column employee.chief_id is 'Начальник';
comment on column employee.salary is 'Зарплата';

alter table employee add constraint fk_employee_department foreign key (department_id) references department(department_id);
alter table employee add constraint fk_employee_self foreign key (chief_id) references employee(employee_id);

-- Можно создать последовательности для вставки id, но для наглядности я использовал явные значения

insert into department(department_id, name) values (1, 'Разработка');
insert into department(department_id, name) values (2, 'Бухгалтерия');
insert into department(department_id, name) values (3, 'Продажи');
insert into department(department_id, name) values (4, 'ДИТ');
insert into department(department_id, name) values (5, 'ДАУП');
commit;

/* Глава компании, без начальника.
   Ссылается сам на себя, это реализация рекурсивной связи один ко многим, внутри одной таблицы. */
insert into employee(employee_id, department_id, chief_id, name, salary)
values (1, 4, 1, 'Иванов Иван', 500000);
commit;

-- Руководители департаментов
insert into employee(employee_id, department_id, chief_id, name, salary)
values (2, 1, 1, 'Петров Пётр', 450000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (3, 2, 1, 'Сидорова Мария', 470000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (4, 3, 1, 'Попов Андрей', 480000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (5, 5, 1, 'Кузнецова Анна', 460000);
commit;

-- Подчинённые
insert into employee(employee_id, department_id, chief_id, name, salary)
values (6, 1, 2, 'Алексеев Алексей', 470000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (7, 1, 2, 'Михайлов Михаил', 430000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (8, 2, 3, 'Смирнова Ольга', 450000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (9, 2, 3, 'Федоров Фёдор', 480000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (10, 2, 3, 'Семенова Юлия', 300000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (11, 3, 4, 'Орлова Елена', 350000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (12, 3, 4, 'Николаев Николай', 520000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (13, 3, 4, 'Васильев Василий', 490000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (14, 5, 5, 'Зайцева Зоя', 470000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (15, 5, 5, 'Григорьев Григорий', 400000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (16, 5, 5, 'Мартынов Артём', 380000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (17, 5, 5, 'Денисова Ирина', 370000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (18, 1, 2, 'Тимофеев Тимур', 460000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (20, 1, 2, 'Калинина Кира', 500000);
insert into employee(employee_id, department_id, chief_id, name, salary)
values (21, 1, 4, 'Лапучи Гоф', 511000);
commit;

-- 1. списка сотрудников, зарплата которых выше, чем зарплата их непосредственного руководителя (Выполнил за ~15 мин);
select e.employee_id "ID сотрудника",
  e.name as "ФИО сотрудника",
  to_char(e.salary, 'FM999G999G999') || ' ₸' as "ЗП Сотрудника",
  e2.name as "ФИО начальника",
  to_char(e2.salary, 'FM999G999G999') || ' ₸' as "ЗП Начальника",
  to_char(e.salary - e2.salary, 'FM999G999G999') || ' ₸' as "Разница ЗП"
from employee e
join employee e2 ON e.chief_id = e2.employee_id
where e.salary > e2.salary;

-- 2. списка сотрудников, которые получают максимальную зарплату в своем отделе (Выполнил за ~20 мин);
select e.employee_id "ID сотрудника",
  e.name as "ФИО сотрудника",
  to_char(e.salary, 'FM999G999G999') || ' ₸' as "ЗП Сотрудника",
  d.name as "Департамент"
from employee e
join department d on d.department_id = e.department_id -- Для вывода названия департамента
where e.salary = (
  select max(e2.salary)
  from employee e2
  where e2.department_id = e.department_id
)
order by e.salary desc;

-- При использовании аналитической функции исполняется на 0.011 секунд быстрее
select employee_id as "ID сотрудника",
 name as "ФИО сотрудника",
 to_char(salary, 'FM999G999G999') || ' ₸' as "ЗП Сотрудника",
 dname as "Департамент"
from (
  select e.employee_id,
         e.name,
         e.salary,
         d.name as dname,
         rank() over (partition by e.department_id order by e.salary desc) as rnk
  from employee e
  join department d on d.department_id = e.department_id
)
where rnk = 1
order by salary desc;

-- 3. списка отделов, в которых работает более 3 человек с зарплатой выше среднего по всей компании (Выполнил за ~20 мин);

select d.name as "Департамент",
count(e.employee_id) as "Количество сотрудников"
from department d
join employee e on e.department_id = d.department_id
where e.salary > (select avg(salary) from employee)
group by d.name
having count(e.employee_id) > 3;

/* Если использовать временную таблицу, то достаточно один раз агрегировать среднюю ЗП
и не нужно постоянно обращаться к большой таблице employee.
Более шустрый вариант при большом кол-во записей в employee. */
with avg_salary as (
  select avg(salary) as avg_sal from employee
)
select d.name as "Департамент",
       count(e.employee_id) as "Количество сотрудников",
       to_char(sl.avg_sal, 'FM999G999G999') || ' ₸' as "Средняя ЗП по всем сотр."
from department d
join employee e on e.department_id = d.department_id
cross join avg_salary sl
where e.salary > sl.avg_sal
group by d.department_id, d.name, sl.avg_sal
having count(e.employee_id) > 3
order by "Количество сотрудников" desc;

-- 4. списка сотрудников, не имеющих руководителя, работающего в том же отделе (Выполнил за ~7 мин);
select e.name as "ФИО сотрудника",
  e.department_id as "ID департамента сотр.",
  e2.name as "ФИО начальника",
  e2.department_id as "ID департамента нач."
from employee e
left join employee e2 on e.chief_id = e2.employee_id
where e.department_id <> e2.department_id;

-- 5. список отделов с максимальной суммарной зарплатой сотрудников (Выполнил за ~20 мин);
with dept_salaries as (
  select e.department_id,
         sum(e.salary) as total_salary
  from employee e
  group by e.department_id
),
max_salary as (
  select max(total_salary) as max_total
  from dept_salaries
)
select d.name as "Департамент",
       to_char(ds.total_salary, 'FM999G999G999') || ' ₸' as "Макс. суммы зарплат"
from dept_salaries ds
join department d on d.department_id = ds.department_id
join max_salary m on ds.total_salary = m.max_total;

-- Топ 3 департамента с максимальными суммами ЗП
select department_name as "Департамент", to_char(total_salary, 'FM999G999G999') || ' ₸' as "Макс. суммы зарплат"
 from (
  select
    d.name as department_name,
    sum(e.salary) as total_salary,
    dense_rank() over (order by sum(e.salary) desc) as rank
  from department d
  join employee e on e.department_id = d.department_id
  group by d.name
)
where rank <= 3;



-- 6. списка сотрудников, зарплата которых выше, чем зарплата их самого верхнего руководителя с учетом иерархии (Выполнил за ~30 мин).

select e.employee_id as "ID сотрудника",
       e.name as "ФИО сотрудника",
       to_char(e.salary, 'FM999G999G999') || ' ₸' as "ЗП Сотрудника"
from employee e
join (
    select employee_id,
           connect_by_root employee_id as root_id
    from employee
    start with chief_id = employee_id
    connect by nocycle prior employee_id = chief_id
) h on e.employee_id = h.employee_id
join employee r on h.root_id = r.employee_id
where e.salary > r.salary
  and e.employee_id <> r.employee_id
order by e.employee_id;



/*
==== Задание №2

Имеется сырой лог АТС в виде Oracle-таблицы LOG_RAW с полями:
- внутренний уникальный идентификатор звонка из АТС,
- дата начала звонка,
- дата окончания звонка,
- исходящий номер,
- входящий номер,
- статус,
- признак перенаправления ('Yes' либо 'No').
Все поля этой таблицы типа varchar2. Индексов нет.
Возможные статусы: 'ANSWERED' (отвечен), 'REJECTED' (отменен), 'BUSY' (линия занята).

Пример данных:
bd7ec9a7e040a8c00201 | 01.07.2016 11:55:46 | 01.07.2016 12:04:01 | 79110012233 | 008 | ANSWERED | Yes

Все данные всех полей присутствуют всегда. Пользователи будут искать данные лога по дате начала звонка, статусу и признаку перенаправления. В БД на данный момент уже имеется таблица контрагентов contragents с полями:
- contragent_id integer (PK)
- fio (varchar2 2000 char)
- phone_num (varchar2 128 char)
- ...
Имеется функциональный индекс по lower(phone_num).

*/

create table LOG_RAW(
  id_call_internal varchar2(2000 char) unique not null,
  dt_call_start varchar2(19 char) not null,
  dt_call_end varchar2(19 char) not null,
  outgoing_number varchar2(128 char) not null,
  incoming_number varchar2(128 char) not null,
  call_status varchar2(10) not null,
  is_redirected varchar2(5 char) not null
);

comment on table LOG_RAW is 'Сырые АТС логи';
comment on column LOG_RAW.id_call_internal is 'внутренний уникальный идентификатор звонка из АТС';
comment on column LOG_RAW.dt_call_start is 'дата начала звонка';
comment on column LOG_RAW.dt_call_start is 'дата окончания звонка';
comment on column LOG_RAW.outgoing_number is 'исходящий номер';
comment on column LOG_RAW.incoming_number is 'входящий номер';
comment on column LOG_RAW.call_status is 'статус, возможные ANSWERED (отвечен), REJECTED (отменен), BUSY (линия занята)';
comment on column LOG_RAW.is_redirected is 'признак перенаправления (Yes либо No)';

alter table LOG_RAW
add constraint chk_call_status
check(call_status in ('ANSWERED', 'REJECTED', 'BUSY'));

alter table LOG_RAW
add constraint chk_is_redirected
check(is_redirected in ('Yes', 'No'));

commit;

INSERT INTO LOG_RAW (
  id_call_internal,
  dt_call_start,
  dt_call_end,
  outgoing_number,
  incoming_number,
  call_status,
  is_redirected
) VALUES (
  'bd7ec9a7e040a8c00201',
  '01.07.2016 11:55:46',
  '01.07.2016 12:04:01',
  '79110012233',
  '008',
  'ANSWERED',
  'Yes'
);

INSERT INTO LOG_RAW (
  id_call_internal,
  dt_call_start,
  dt_call_end,
  outgoing_number,
  incoming_number,
  call_status,
  is_redirected
) VALUES (
  '233d7ec9a7e040a8c00201',
  '02.03.2025 12:57:46',
  '02.03.2025 13:04:01',
  '78880013233',
  '007',
  'REJECTED',
  'Yes'
);

INSERT INTO LOG_RAW (
  id_call_internal,
  dt_call_start,
  dt_call_end,
  outgoing_number,
  incoming_number,
  call_status,
  is_redirected
) VALUES (
  '3344d7ec9a7e040a8c00201',
  '03.03.2025 12:57:46',
  '03.03.2025 13:04:01',
  '78880013233',
  '009',
  'BUSY',
  'No'
);
commit;

create table contragents
(
 contragent_id integer primary key,
 fio varchar2 (2000 char) not null,
 phone_num varchar2 (128 char) not null
);

create index idx_lower_phone on contragents (lower(phone_num));

create sequence seq_contragent_id
  minvalue 1
  start with 1
  increment by 1;

insert into contragents (contragent_id, fio, phone_num)
values (seq_contragent_id.nextval, 'Company Test1', '009');

insert into contragents (contragent_id, fio, phone_num)
values (seq_contragent_id.nextval, 'Company Test2', '007');

insert into contragents (contragent_id, fio, phone_num)
values (seq_contragent_id.nextval, 'Company Test3', '008');

commit;

/*
1. Необходимо спроектировать оптимальную структуру хранения данных лога АТС в СУБД Oracle с привязкой к существующему контрагенту (если такое соответствие найдено),
 либо без привязки (если соответствия нет).  (Выполнил за ~40 мин)
*/

create table ATS_LOG_RAW(
   id_log integer primary key,
   id_call_internal varchar2(2000 char) unique not null,
   dt_call_start TIMESTAMP(0) not null,
   dt_call_end TIMESTAMP(0) not null,
   outgoing_number varchar2(128 char) not null,
   incoming_number varchar2(128 char) not null,
   call_status varchar2(10) not null, -- Можно реализовать отдельный справочник со всеми статусами, для приведения к третьей нормальной форме
   is_redirected number(1) not null,
   b_deleted number(1) default 0 not null,
   contragent_id integer references contragents
)
partition by range (dt_call_start) interval (numtoyminterval(1, 'MONTH'))
(
   partition p_interval values less than (timestamp '2025-01-01 00:00:00')
); -- Партицирование по месяцам для более быстрого доступа к логам за месяц

alter table ATS_LOG_RAW
add constraint chk_ats_call_status
check(call_status in ('ANSWERED', 'REJECTED', 'BUSY'));

alter table ATS_LOG_RAW
add constraint chk_ats_is_redirected
check(is_redirected in (0, 1));

create index idx_atslog_dt_call_start on ATS_LOG_RAW(dt_call_start);
create index idx_atslog_call_status on ATS_LOG_RAW(call_status);
create index idx_is_redirected on ATS_LOG_RAW(is_redirected);

create sequence seq_ats_log_id
  minvalue 1
  start with 1
  increment by 1;

comment on table ATS_LOG_RAW is 'АТС логи с контрагентами';
comment on column ATS_LOG_RAW.id_log is 'Уникальный идентификатор записи лога';
comment on column ATS_LOG_RAW.id_call_internal is 'Внутренний уникальный идентификатор вызова';
comment on column ATS_LOG_RAW.dt_call_start is 'Дата и время начала вызова';
comment on column ATS_LOG_RAW.dt_call_end is 'Дата и время окончания вызова';
comment on column ATS_LOG_RAW.outgoing_number is 'Номер телефона, с которого был исходящий вызов';
comment on column ATS_LOG_RAW.incoming_number is 'Номер телефона, на который был входящий вызов';
comment on column ATS_LOG_RAW.call_status is 'Статус вызова, возможные ANSWERED (отвечен), REJECTED (отменен), BUSY (линия занята)';
comment on column ATS_LOG_RAW.is_redirected is 'Флаг, указывающий, был ли вызов переадресован (1 - да, Yes, 0 - нет, No)';
comment on column ATS_LOG_RAW.b_deleted is 'Флаг логического удаления записи (1 - удалена, 0 - активна)';
comment on column ATS_LOG_RAW.contragent_id is 'Идентификатор контрагента, связанный с вызовом, ссылка на таблицу contragents';

INSERT INTO ATS_LOG_RAW (
    id_log, id_call_internal, dt_call_start, dt_call_end,
    outgoing_number, incoming_number, call_status, is_redirected, b_deleted
) VALUES (
    seq_ats_log_id.nextval, '233d7ec9a7e040a8c00201', TIMESTAMP '2025-03-15 10:00:00', TIMESTAMP '2025-03-15 10:05:00',
    '71234567890', '008', 'ANSWERED', 1, 0
);

INSERT INTO ATS_LOG_RAW (
    id_log, id_call_internal, dt_call_start, dt_call_end,
    outgoing_number, incoming_number, call_status, is_redirected, b_deleted, Contragent_Id
) VALUES (
    seq_ats_log_id.nextval, '3344d7ec9a7e040a8c00201', TIMESTAMP '2025-03-15 11:00:00', TIMESTAMP '2025-03-15 11:15:00',
    '71180013233', '009', 'ANSWERED', 1, 0, 1
);

INSERT INTO ATS_LOG_RAW (
    id_log, id_call_internal, dt_call_start, dt_call_end,
    outgoing_number, incoming_number, call_status, is_redirected, b_deleted, Contragent_Id
) VALUES (
    seq_ats_log_id.nextval, '55d7ec9a7e040a8c00201', TIMESTAMP '2025-04-16 11:00:00', TIMESTAMP '2025-04-16 11:15:00',
    '81180013233', '009', 'ANSWERED', 1, 0, 1
);
commit;

/* Просмотр имеющихся партиций по месяцам
SELECT partition_name, high_value
FROM user_tab_partitions
WHERE table_name = 'ATS_LOG_RAW';
*/

/* 2. Написать на PL/SQL логику заливки данных из таблицы LOG_RAW в структуру, разработанную. в п.1 этого задания. (Выполнил за ~2 ч с учётом тестов) */

-- Пакет для работы с таблицами связанных с АТС
create or replace package ats_util is

-- Загрузка всех данных из LOG_RAW
  procedure loadAllATSLogs;

-- Загрузка данных с использование батчей, контрагент учитывается только по исходящим номерам
  procedure loadAllATSLogsBatch(p_batch_size in pls_integer);

-- Получение всех данных из ATS_LOG_RAW
  procedure getATSLogs(
      p_call_start timestamp,
      p_call_status varchar2,
      p_is_redirected number,
      p_allATSLogs out sys_refcursor
  );

end ats_util;
/
create or replace package body ats_util is

  procedure loadAllATSLogs is
    v_id_contragent contragents.contragent_id%type := null;
    v_exists number;
  begin

    for v_log in (
      select id_call_internal,
             to_timestamp(dt_call_start, 'DD.MM.YYYY HH24:MI:SS') as dt_call_start,
             to_timestamp(dt_call_end, 'DD.MM.YYYY HH24:MI:SS') as dt_call_end,
             outgoing_number,
             incoming_number,
             call_status,
             case
               when trim(lower(is_redirected)) = 'yes' then 1
               when trim(lower(is_redirected)) = 'no' then 0
             end as is_redirected
      from LOG_RAW
    ) loop

      begin
        select con.contragent_id
        into v_id_contragent
        from contragents con
        where trim(con.phone_num) = trim(v_log.incoming_number)
           or trim(con.phone_num) = trim(v_log.outgoing_number);
      exception
        when no_data_found then
          v_id_contragent := null;
        when others then
          dbms_output.put_line('Ошибка при поиске контрагента: ' || SQLERRM);
          continue;
      end;

      -- На случай если нужна проверка на существование записи
      select count(*) into v_exists
      from ATS_LOG_RAW
      where id_call_internal = v_log.id_call_internal
        and dt_call_start = v_log.dt_call_start;

      if v_exists = 0 then
        begin
          insert into ATS_LOG_RAW (
            id_log, id_call_internal, dt_call_start, dt_call_end,
            outgoing_number, incoming_number, call_status,
            is_redirected, b_deleted, contragent_id
          )
          values (
            seq_ats_log_id.nextval,
            v_log.id_call_internal,
            v_log.dt_call_start,
            v_log.dt_call_end,
            v_log.outgoing_number,
            v_log.incoming_number,
            v_log.call_status,
            v_log.is_redirected,
            0,
            v_id_contragent
          );
        exception
          when others then
            dbms_output.put_line('Ошибка при вставке: ' || v_log.id_call_internal || ' ' || SQLERRM);
        end;
      else
        dbms_output.put_line('Пропуск записи: уже существует id_call_internal = ' || v_log.id_call_internal || ', dt_call_start = ' || TO_CHAR(v_log.dt_call_start, 'DD.MM.YYYY HH24:MI:SS'));
      end if;

    end loop;

    commit;
  end loadAllATSLogs;


  -- Более быстрый вариант по производительности, но маппинг на совпадение номеров контрагентов только по входящим номерам (можно добавить проверки по обоим)
  procedure loadAllATSLogsBatch(p_batch_size in pls_integer) is

  type t_log_rec is record (
      id_call_internal  LOG_RAW.id_call_internal%type,
      dt_call_start     timestamp,
      dt_call_end       timestamp,
      outgoing_number   LOG_RAW.outgoing_number%type,
      incoming_number   LOG_RAW.incoming_number%type,
      call_status       LOG_RAW.call_status%type,
      is_redirected     number
  );

  type t_log_tab is table of t_log_rec;
  v_logs t_log_tab;

  type t_contragent_map is table of contragents.contragent_id%type index by varchar2(50);
  v_contragent_map t_contragent_map;

  v_offset pls_integer := 0;
  v_exists number;

  begin

    loop

      select id_call_internal,
             TO_TIMESTAMP(dt_call_start, 'DD.MM.YYYY HH24:MI:SS') as dt_call_start,
             TO_TIMESTAMP(dt_call_end, 'DD.MM.YYYY HH24:MI:SS') as dt_call_end,
             outgoing_number,
             incoming_number,
             call_status,
             case
               when trim(lower(is_redirected)) = 'yes' then 1
               else 0
             end as is_redirected
      bulk collect into v_logs
      from (
        select id_call_internal, dt_call_start, dt_call_end,
               outgoing_number, incoming_number, call_status, is_redirected
        from LOG_RAW l
        order by id_call_internal
        offset v_offset rows fetch next p_batch_size rows only
      );

      exit when v_logs.count = 0;

      v_contragent_map.DELETE;

      for i in 1 .. v_logs.COUNT loop
        begin
          select con.contragent_id
            into v_contragent_map(trim(v_logs(i).incoming_number))
          from contragents con
          where trim(con.phone_num) = trim(v_logs(i).incoming_number)
             or trim(con.phone_num) = trim(v_logs(i).outgoing_number);
        exception
          when no_data_found then
            v_contragent_map(trim(v_logs(i).incoming_number)) := null;
          when others then
            dbms_output.put_line('Ошибка при поиске контрагента по номеру: ' || v_logs(i).incoming_number || ' — ' || SQLERRM);
            continue;
        end;
      end loop;

      begin
        for i in 1 .. v_logs.count loop
          begin
            -- На случай если нужна проверка на существование записи
            select count(*) into v_exists
            from ATS_LOG_RAW
            where id_call_internal = v_logs(i).id_call_internal
              and dt_call_start = v_logs(i).dt_call_start;

            if v_exists = 0 then
              insert into ATS_LOG_RAW (
                id_log, id_call_internal, dt_call_start, dt_call_end,
                outgoing_number, incoming_number, call_status,
                is_redirected, b_deleted, contragent_id
              ) values (
                seq_ats_log_id.nextval,
                v_logs(i).id_call_internal,
                v_logs(i).dt_call_start,
                v_logs(i).dt_call_end,
                v_logs(i).outgoing_number,
                v_logs(i).incoming_number,
                v_logs(i).call_status,
                v_logs(i).is_redirected,
                0,
                v_contragent_map(trim(v_logs(i).incoming_number))
              );
            else
              dbms_output.put_line('Пропуск записи: уже существует id_call_internal = ' || v_logs(i).id_call_internal || ', dt_call_start = ' || TO_CHAR(v_logs(i).dt_call_start, 'DD.MM.YYYY HH24:MI:SS'));
            end if;

          exception
            when others then
              dbms_output.put_line('Ошибка при вставке записи ' || i || ', offset ' || v_offset || ': ' || SQLERRM);
          end;
        end loop;
      end;

      commit;
      v_offset := v_offset + p_batch_size;

    end loop;

  exception
    when others then
      rollback;
      dbms_output.put_line('Критическая ошибка при переносе данных из LOG_RAW: ' || SQLERRM);

  end loadAllATSLogsBatch;

-- Получение всех данных из ATS_LOG_RAW
  procedure getATSLogs(
      p_call_start timestamp,
      p_call_status varchar2,
      p_is_redirected number,
      p_allATSLogs out sys_refcursor
  ) is
    begin

    -- При большом объёме логов для ускорения выполнения можно распараллелить исполнение запроса /*+ parallel(t 4) */
    open p_allATSLogs for
        select ats.id_log,
               ats.id_call_internal,
               ats.dt_call_start,
               ats.dt_call_end,
               ats.outgoing_number,
               ats.incoming_number,
               ats.call_status,
               ats.is_redirected,
               ats.b_deleted,
               ats.contragent_id
            from ATS_LOG_RAW ats
        where (ats.dt_call_start = p_call_start or p_call_start is null)
        and (ats.call_status = p_call_status or p_call_status is null)
        and (ats.is_redirected = p_is_redirected or p_is_redirected is null);

    end getATSLogs;


end ats_util;
/



-- Как вариант автоматизации процесса сбора логов с LOG_RAW, в виде job в oracle, который запускается процедуру периодически каждый день в 1:00 ночи.
-- И возможно начинать стоит с последнего добавленного лога в таблице ATS_LOG_RAW
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'LOAD_ATS_LOGS_DAILY',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
      BEGIN
        ats_util.loadAllATSLogs;
      END;',
    start_date      => TRUNC(SYSDATE) + 1 + 1/24, -- завтра в 01:00:00
    repeat_interval => 'FREQ=DAILY; BYHOUR=1; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Ежедневный запуск процедуры загрузки логов ATS в 01:00'
  );
END;
/

