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
