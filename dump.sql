--
-- PostgreSQL database dump
--

-- Dumped from database version 12.2
-- Dumped by pg_dump version 12.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: identities; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.identities AS (
	user_identity integer,
	auth_identity integer
);


ALTER TYPE public.identities OWNER TO postgres;

--
-- Name: commentpost(integer, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.commentpost(comment_post_id integer, comment_user_id integer, comment_content character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into post_comment(post_id, content, user_id, timestamp)
        values (comment_post_id,comment_user_id,comment_content, localtimestamp)
        returning id into RESULT;
        UPDATE post
        SET comment_number = (select comment_number from post where id = comment_post_id) + 1
        where id = comment_post_id;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$$;


ALTER FUNCTION public.commentpost(comment_post_id integer, comment_user_id integer, comment_content character varying) OWNER TO postgres;

--
-- Name: confirmauth(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.confirmauth(confirm_auth_id integer, status integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    IDENTITY int;
    RESULT   int;
    CNT      int;
    QUOTA    int;
BEGIN
    BEGIN
        update authentication_info
        set authentication_status = status
        where id = confirm_auth_id;
        CNT = (select count(*) from position_info where post_user_id = confirm_auth_id);
        IDENTITY = (select identity from "authentication_info" where user_id = confirm_auth_id);
        if IDENTITY = 1 Then
            if CNT > 5 Then
                QUOTA = 0;
            else
                QUOTA = 5 - CNT;
            end if;
        end if;
        if IDENTITY = 0 Then
            if CNT > 1 Then
                QUOTA = 0;
            else
                QUOTA = 1 - CNT;
            end if;
        end if;
        Insert Into user_quota(uid, quota)
        values (confirm_auth_id, QUOTA)
        on conflict(uid) do update
            set quota = QUOTA
        where uid = confirm_auth_id;
        RESULT = 1;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.confirmauth(confirm_auth_id integer, status integer) OWNER TO postgres;

--
-- Name: deletepost(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.deletepost(post_id integer, post_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    RESULT         int;
    STORED_USER_ID int;

BEGIN
    BEGIN
        STORED_USER_ID = (select user_id from post where id = post_id);
        if STORED_USER_ID != post_user_id THEN
            RESULT = -1;
        else
            Delete from post where user_id = post_user_id AND id = post_id;
            RESULT = 0;
        end if;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$$;


ALTER FUNCTION public.deletepost(post_id integer, post_user_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: post; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post (
    id integer NOT NULL,
    content character varying NOT NULL,
    group_id integer NOT NULL,
    user_id integer NOT NULL,
    like_number integer DEFAULT 0 NOT NULL,
    comment_number integer DEFAULT 0 NOT NULL,
    favorite_number integer DEFAULT 0 NOT NULL,
    is_pinned boolean DEFAULT false NOT NULL,
    "timestamp" timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE public.post OWNER TO postgres;

--
-- Name: TABLE post; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.post IS '动态信息表';


--
-- Name: fetchallpost(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fetchallpost(post_group_id integer, sort integer) RETURNS SETOF public.post
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- sort 为0时热度排序，为1时时间排序
DECLARE

BEGIN
    BEGIN
        IF sort = 0 THEN
            Return Query SELECT *
                         from post
                         where group_id = post_group_id
                         group by post.id
                         order by sum(like_number + favorite_number + comment_number) desc;
        elseif sort = 1 THEN
            Return Query SELECT *
                         from post
                         where group_id = post_group_id
                         group by post.id
                         order by timestamp;
        else
            RAISE Exception 'Unknown sort method';
        end if;
    END;
END;
$$;


ALTER FUNCTION public.fetchallpost(post_group_id integer, sort integer) OWNER TO postgres;

--
-- Name: groupadmindelete(integer, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.groupadmindelete(group_delete_id integer, group_user_id integer, group_delete_reason character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID  申请的ID
    -- 返回  -1  申请已经存在
DECLARE
    RESULT  int;
    IfExist int;

BEGIN
    BEGIN
        IfExist = (select count(*) from group_modify where group_id = group_delete_id);
        IF IfExist = 1 THEN
            RESULT = -1;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        INSERT into group_modify(request_uid, type, reason, transform_uid, group_id)
        values (group_user_id, 0, group_delete_reason, null, group_delete_id)
        RETURNING id into RESULT;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.groupadmindelete(group_delete_id integer, group_user_id integer, group_delete_reason character varying) OWNER TO postgres;

--
-- Name: groupadminuserban(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.groupadminuserban(ban_group_id integer, ban_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  0   执行成功
    -- 返回  -1  执行失败
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into group_banned(user_id, group_id)
        values (ban_group_id, ban_user_id)
        on conflict (user_id,group_id) do nothing
        returning id into RESULT;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.groupadminuserban(ban_group_id integer, ban_user_id integer) OWNER TO postgres;

--
-- Name: groupadminuserwarn(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.groupadminuserwarn(warn_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  0   执行成功
    -- 返回  -1  申请已经存在
DECLARE
    RESULT int;
    CREDIT int;

BEGIN
    BEGIN
        CREDIT = (select credit from user_credit where user_id = warn_user_id) - 1;
        if CREDIT = 0 Then
            update user_credit
            set banned_begin_time = localtimestamp,
                credit            = credit
            where user_id = warn_user_id;
        else
            update user_credit
            set credit = credit
            where user_id = warn_user_id;
        end if;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.groupadminuserwarn(warn_user_id integer) OWNER TO postgres;

--
-- Name: likepost(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.likepost(post_like_id integer, post_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 数据库异常
DECLARE
    RESULT int;

BEGIN
    BEGIN
        Insert Into post_like(post_id, user_id)
        values (post_like_id, post_user_id)
        returning id into RESULT;
        UPDATE post
        SET like_number = (select like_number from post where id = post_like_id) + 1
        where id = post_like_id;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$$;


ALTER FUNCTION public.likepost(post_like_id integer, post_user_id integer) OWNER TO postgres;

--
-- Name: newpost(integer, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.newpost(post_group_id integer, post_user_id integer, post_content character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 添加失败
DECLARE
    IsInGroup int;
    RESULT    int;

BEGIN
    BEGIN
        IsInGroup = (SELECT count(*) from group_user_map where user_id = post_user_id and group_id = post_group_id);
        IF IsInGroup = 1 Then
            RESULT = -1;
            RETURN RESULT;
        end if;
    end;

    BEGIN
        Insert Into post(content, group_id, user_id, like_number, comment_number, favorite_number, is_pinned, timestamp)
        values (post_content, post_group_id, post_user_id, 0, 0, 0, false, localtimestamp)
        returning id into RESULT;
        return RESULT;
    Exception
        when others then
            RESULT = -1;
            RETURN RESULT;
    END;
END;
$$;


ALTER FUNCTION public.newpost(post_group_id integer, post_user_id integer, post_content character varying) OWNER TO postgres;

--
-- Name: postdeleteposition(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postdeleteposition(position_post_user_id integer, position_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 用户不是该记录拥有者或删除失败
DECLARE
    QUOTA    int;
    IDENTITY int;
    CNT      int;
    RESULT   int;

BEGIN
    BEGIN
        CNT = (SELECT count(id) from position_info where post_user_id = position_post_user_id and id = position_id);
        if CNT = 0 then
            RESULT = -1;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        Delete from position_info where post_user_id = position_post_user_id and id = position_id;
    END;

    BEGIN
        QUOTA = (select quota from user_quota where uid = position_post_user_id);
        IDENTITY = (select identity from "authentication_info" where user_id = position_post_user_id);
        if IDENTITY = 1 Then
            if QUOTA + 1 > 5 Then
                QUOTA = 5;
            else
                QUOTA = QUOTA + 1;
            end if;
        end if;
        if IDENTITY = 0 Then
            if QUOTA + 1 > 1 Then
                QUOTA = 1;
            else
                QUOTA = QUOTA + 1;
            end if;
        end if;
        update "user_quota" set quota = QUOTA where uid = position_post_user_id;
        RESULT = 0;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.postdeleteposition(position_post_user_id integer, position_id integer) OWNER TO postgres;

--
-- Name: postjoingroup(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postjoingroup(group_id integer, group_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
DECLARE
    RESULT int;

BEGIN
    BEGIN
        insert into group_user_map(user_id, group_id, state, user_join_time)
        VALUES (group_user_id, group_id, 1, localtimestamp)
        on conflict do nothing;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.postjoingroup(group_id integer, group_user_id integer) OWNER TO postgres;

--
-- Name: postnewgroup(character varying, character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postnewgroup(group_name character varying, group_avatar character varying, group_description character varying, group_category integer, group_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -2 额度已用完
    -- 返回  -3 创建条件不足
DECLARE
    CREDIT   int;
    COUNT    int;
    RESULT   int;
    GROUP_ID int;

BEGIN
    BEGIN
        CREDIT = (select credit from user_credit where user_id = group_user_id);
        IF CREDIT < 10 THEN
            RESULT = -3;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        COUNT = (select distinct COUNT(id)
                 from post
                 where user_id = group_user_id
                   AND length(content) >= 200
                   AND (select distinct COUNT(group_id)
                        from post
                        where user_id = group_user_id
                          AND length(content) >= 200) >= 3);
        IF CREDIT < 15 THEN
            RESULT = -3;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        COUNT = (select COUNT(*) from "group_user_map" where user_id = group_user_id);
        IF CREDIT >= 2 THEN
            RESULT = -2;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        insert into "group"(name, logo, description, group_category_id, logo_last_update)
        values (group_name, group_avatar, group_description, group_category, localtimestamp)
        on conflict (name) do nothing
        returning id into GROUP_ID;
        if GROUP_ID is not null then
            insert into group_user_map(user_id, group_id, state, user_join_time)
            VALUES (group_user_id, GROUP_ID, 0, localtimestamp);
            UPDATE "user"
            set identity = 100
            where phone = group_user_id;
            RESULT = 0;
        else
            RESULT = -1;
        end if;
    EXCEPTION
        when others then
            RESULT = -1;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.postnewgroup(group_name character varying, group_avatar character varying, group_description character varying, group_category integer, group_user_id integer) OWNER TO postgres;

--
-- Name: postnewposition(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postnewposition(position_post_user_id integer, position_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1 用户不是该记录拥有者或删除失败
DECLARE
    QUOTA    int;
    IDENTITY int;
    CNT      int;
    RESULT   int;

BEGIN
    BEGIN
        CNT = (SELECT count(id) from position_info where post_user_id = position_post_user_id and id = position_id);
        if CNT = 0 then
            RESULT = -1;
            RETURN RESULT;
        end if;
    END;

    BEGIN
        Delete from position_info where post_user_id = position_post_user_id and id = position_id;
    END;

    BEGIN
        QUOTA = (select quota from user_quota where uid = position_post_user_id);
        CNT = (select count(*) from position_info where post_user_id = position_post_user_id);
        IDENTITY = (select identity from "authentication_info" where user_id = position_post_user_id);
        if IDENTITY = 1 Then
            if CNT > 5 Then
                QUOTA = 0;
            else
                QUOTA = 5 - CNT;
            end if;
        end if;
        if IDENTITY = 0 Then
            if CNT > 1 Then
                QUOTA = 0;
            else
                QUOTA = 1 - CNT;
            end if;
        end if;
        update "user_quota" set quota = QUOTA where uid = position_post_user_id;
        RESULT = 0;
    END;

    return RESULT;
END;
$$;


ALTER FUNCTION public.postnewposition(position_post_user_id integer, position_id integer) OWNER TO postgres;

--
-- Name: postnewposition(character varying, character varying, character varying, character varying, character varying, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postnewposition(position_name character varying, position_company character varying, position_description character varying, position_post_mail character varying, position_grade character varying, position_location character varying, position_position_category_id integer, position_post_user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  ID 插入的ID
    -- 返回  -1  用户未认证或额度已用完
DECLARE
    QUOTA  int;
    RESULT int;

BEGIN
    BEGIN
        QUOTA = (SELECT quota from user_quota where uid = position_post_user_id);
        IF QUOTA <= 0 THEN
            RESULT = -1;
            return RESULT;
        else
            QUOTA = QUOTA - 1;
            UPDATE user_quota set quota = QUOTA where uid = position_post_user_id;
        end if;
    END;

    BEGIN
        INSERT INTO position_info(name, company, description, post_mail, grade, location, position_category_id,
                                  post_user_id)
        values (position_name, position_company, position_description, position_post_mail, position_grade,
                position_location, position_position_category_id, position_post_user_id);
        RESULT = 0;
    EXCEPTION
        when others then
            QUOTA = QUOTA + 1;
            UPDATE user_quota set quota = QUOTA where uid = position_post_user_id;
            RESULT = -1;
    END;
    return RESULT;
END;
$$;


ALTER FUNCTION public.postnewposition(position_name character varying, position_company character varying, position_description character varying, position_post_mail character varying, position_grade character varying, position_location character varying, position_position_category_id integer, position_post_user_id integer) OWNER TO postgres;

--
-- Name: group; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."group" (
    id integer NOT NULL,
    name character varying NOT NULL,
    logo character varying NOT NULL,
    description character varying NOT NULL,
    group_category_id integer NOT NULL,
    logo_last_update timestamp without time zone NOT NULL
);


ALTER TABLE public."group" OWNER TO postgres;

--
-- Name: TABLE "group"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public."group" IS '圈子信息表';


--
-- Name: postsearchgroup(character varying, integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.postsearchgroup(group_desc character varying, group_category integer[]) RETURNS SETOF public."group"
    LANGUAGE plpgsql
    AS $$
    -- 返回 group
DECLARE

BEGIN
    BEGIN
        if -1 = any (group_category) Then
            RETURN Query select *
                         from "group"
                         where name like group_desc
                            or description like group_desc;
        else
            RETURN Query select *
                         from "group"
                         where id = any (group_category)
                           and (name like group_desc
                             or description like group_desc);
        end if;
    END;
END ;
$$;


ALTER FUNCTION public.postsearchgroup(group_desc character varying, group_category integer[]) OWNER TO postgres;

--
-- Name: queryidentity(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.queryidentity(user_phone character varying) RETURNS SETOF public.identities
    LANGUAGE plpgsql
    AS $$
DECLARE
    RESULT        identities;

BEGIN
    BEGIN
        select "user".identity, authentication_info.identity
        into RESULT
        from "user"
                 left join authentication_info on "user".id = authentication_info.user_id
        where phone = user_phone;
    END;

    return NEXT RESULT;
END;
$$;


ALTER FUNCTION public.queryidentity(user_phone character varying) OWNER TO postgres;

--
-- Name: queryquota(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.queryquota(username character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回  int 额度
    -- 返回  -1  用户未认证或额度已用完
DECLARE
    RESULT int;

BEGIN
    BEGIN
        select quota
        into RESULT
        from user_quota
                 left join "user" on user_quota.uid = "user".id
        where phone = username;
        if RESULT IS NULL then
            RESULT = -1;
        end if;
    EXCEPTION
        when others then
            RESULT = -1;
    END;
    return RESULT;
END;
$$;


ALTER FUNCTION public.queryquota(username character varying) OWNER TO postgres;

--
-- Name: register(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.register(user_phone character varying, user_password character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    RESULT int;
    Count  int;
    UserID int;

BEGIN
    Count = (select count(*)
             from "user"
             where "user".phone = user_phone);
    if Count = 1 then
        RESULT = -1;
    else
        insert into "user" (password, phone) values (user_password, user_phone) returning id into UserID;
        insert into user_credit (user_id, credit) values (UserID, 10);
        RESULT = 0;
    end if;
    return RESULT;
END;
$$;


ALTER FUNCTION public.register(user_phone character varying, user_password character varying) OWNER TO postgres;

--
-- Name: resetpassword(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.resetpassword(user_phone character varying, user_password character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    RESULT int;
    Count  int;

BEGIN
    Count = (select count(*) from "user" where "user".phone = user_phone);
    if Count = 1 then
        UPDATE "user"
        SET password = user_password
        where phone = user_phone;
        RESULT = 0;
    else
        RESULT = -1;
    end if;
    return RESULT;
END;
$$;


ALTER FUNCTION public.resetpassword(user_phone character varying, user_password character varying) OWNER TO postgres;

--
-- Name: position_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.position_info (
    id integer NOT NULL,
    name character varying NOT NULL,
    company character varying NOT NULL,
    description character varying NOT NULL,
    post_mail character varying NOT NULL,
    grade integer DEFAULT 0 NOT NULL,
    location character varying,
    position_category_id integer NOT NULL,
    post_user_id integer NOT NULL,
    post_time timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE public.position_info OWNER TO postgres;

--
-- Name: TABLE position_info; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.position_info IS '职位信息表';


--
-- Name: searchposition(character varying, character varying, integer[], integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.searchposition(content character varying, query_location character varying, position_category_ids integer[], query_grade integer[]) RETURNS SETOF public.position_info
    LANGUAGE plpgsql
    AS $$
    -- 返回 position_info
DECLARE

BEGIN
    BEGIN
        if -1 = any (position_category_ids) Then
            RETURN Query select *
                         from position_info
                         where location like query_location
                           and (name like content or description like content)
                           and grade = any (query_grade);
        else
            RETURN Query select *
                         from position_info
                         where location like query_location
                           and (name like content or description like content)
                           and position_category_id = any (position_category_ids)
                           and grade = any (query_grade);
        end if;
    END;
END ;
$$;


ALTER FUNCTION public.searchposition(content character varying, query_location character varying, position_category_ids integer[], query_grade integer[]) OWNER TO postgres;

--
-- Name: submitauthentication(character varying, integer, character varying, character varying, character varying, boolean, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.submitauthentication(user_phone character varying, user_identity integer, user_company character varying, user_position character varying, user_mail character varying, user_mail_can_verify boolean, user_company_serial character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    RESULT int;
    Count  int;
    UserId int;

BEGIN
    BEGIN
        UserId = (select id from "user" where phone = user_phone);
    Exception
        when others then
            RESULT = -1;
    END;

    Begin
        Count = (select count(*) from authentication_info where user_id = UserId);
        if Count = 1 then
            Update authentication_info
            set begin_time            = localtimestamp,
                end_time              = localtimestamp + interval '90 days',
                identity              = user_identity,
                company               = user_company,
                company_serial        = user_company_serial,
                position              = user_position,
                mail                  = user_mail,
                mail_can_verify       = user_mail_can_verify,
                authentication_status = 0
            where user_id = UserId;
            RESULT = 0;
        else
            INSERT INTO authentication_info(user_id, identity, begin_time, end_time, company, position, mail,
                                            company_serial, authentication_status, mail_can_verify)
            values (UserId, user_identity, localtimestamp, localtimestamp + interval '90 days', user_company,
                    user_position,
                    user_mail, user_company_serial, 0, user_mail_can_verify);
            RESULT = 0;
        end if;
    Exception
        when others then
            RESULT = -1;
    END;

    return RESULT;
END ;
$$;


ALTER FUNCTION public.submitauthentication(user_phone character varying, user_identity integer, user_company character varying, user_position character varying, user_mail character varying, user_mail_can_verify boolean, user_company_serial character varying) OWNER TO postgres;

--
-- Name: updatepassword(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.updatepassword(user_phone character varying, user_password_old character varying, user_password_new character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    RESULT int;
    Count  int;

BEGIN
    Count = (select count(*) from "user" where "user".phone = user_phone and user_password_old = password);
    if Count = 1 then
        UPDATE "user"
        SET password = user_password_new
        where phone = user_phone;
    else
        RESULT = -1;
    end if;
    return RESULT;
END;
$$;


ALTER FUNCTION public.updatepassword(user_phone character varying, user_password_old character varying, user_password_new character varying) OWNER TO postgres;

--
-- Name: userinfoupdate(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.userinfoupdate(username character varying, user_nickname character varying, user_gender character varying, user_description character varying, user_avatar character varying, user_expected_career_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    -- 返回    0  更新成功
    -- 返回    -1 更新信息表失败
DECLARE
    RESULT int;
    UserId int;

BEGIN
    BEGIN
        UserId = (select id from "user" where phone = username);
    END;

    BEGIN
        INSERT INTO user_info(user_id, nickname, nikename_last_update, gender, description, avatar,
                              expected_career_id, register_time)
        VALUES (UserId, user_nickname, localtimestamp, user_gender, user_description, user_avatar,
                user_description, localtimestamp)
        ON conflict(user_id) DO UPDATE
            SET nickname             = user_nickname,
                nikename_last_update = localtimestamp,
                gender               = user_gender,
                description          = user_description,
                avatar               = user_avatar,
                expected_career_id   = user_expected_career_id;
        RESULT = 0;
    EXCEPTION
        when others then
            RESULT = -1;
    END;
    return RESULT;
END;
$$;


ALTER FUNCTION public.userinfoupdate(username character varying, user_nickname character varying, user_gender character varying, user_description character varying, user_avatar character varying, user_expected_career_id integer) OWNER TO postgres;

--
-- Name: authentication_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.authentication_info (
    id integer NOT NULL,
    user_id integer NOT NULL,
    identity integer DEFAULT 0 NOT NULL,
    begin_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    company character varying NOT NULL,
    "position" character varying NOT NULL,
    mail character varying NOT NULL,
    company_serial character varying NOT NULL,
    authentication_status integer DEFAULT '-1'::integer NOT NULL,
    mail_can_verify boolean DEFAULT false NOT NULL
);


ALTER TABLE public.authentication_info OWNER TO postgres;

--
-- Name: TABLE authentication_info; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.authentication_info IS '身份认证';


--
-- Name: authentication_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.authentication_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authentication_info_id_seq OWNER TO postgres;

--
-- Name: authentication_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.authentication_info_id_seq OWNED BY public.authentication_info.id;


--
-- Name: post_comment_reply; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_comment_reply (
    id integer NOT NULL,
    comment_id integer NOT NULL,
    type character varying DEFAULT 'comment'::character varying NOT NULL,
    content character varying NOT NULL,
    target_id integer NOT NULL,
    from_uid integer NOT NULL,
    to_uid integer,
    "timestamp" timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE public.post_comment_reply OWNER TO postgres;

--
-- Name: TABLE post_comment_reply; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.post_comment_reply IS '评论回复表';


--
-- Name: comment_reply_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comment_reply_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comment_reply_id_seq OWNER TO postgres;

--
-- Name: comment_reply_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comment_reply_id_seq OWNED BY public.post_comment_reply.id;


--
-- Name: group_banned; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_banned (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.group_banned OWNER TO postgres;

--
-- Name: TABLE group_banned; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.group_banned IS '圈子禁止列表';


--
-- Name: group_banned_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_banned_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_banned_id_seq OWNER TO postgres;

--
-- Name: group_banned_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_banned_id_seq OWNED BY public.group_banned.id;


--
-- Name: group_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_category (
    id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.group_category OWNER TO postgres;

--
-- Name: TABLE group_category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.group_category IS '圈子类别信息表';


--
-- Name: group_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_category_id_seq OWNER TO postgres;

--
-- Name: group_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_category_id_seq OWNED BY public.group_category.id;


--
-- Name: group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_id_seq OWNER TO postgres;

--
-- Name: group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_id_seq OWNED BY public."group".id;


--
-- Name: group_modify; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_modify (
    id integer NOT NULL,
    request_uid integer NOT NULL,
    type integer DEFAULT 1 NOT NULL,
    reason character varying NOT NULL,
    transform_uid integer,
    group_id integer NOT NULL
);


ALTER TABLE public.group_modify OWNER TO postgres;

--
-- Name: group_modify_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_modify_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_modify_id_seq OWNER TO postgres;

--
-- Name: group_modify_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_modify_id_seq OWNED BY public.group_modify.id;


--
-- Name: group_user_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.group_user_map (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL,
    state integer NOT NULL,
    user_join_time timestamp without time zone NOT NULL
);


ALTER TABLE public.group_user_map OWNER TO postgres;

--
-- Name: group_user_map_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.group_user_map_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_user_map_id_seq OWNER TO postgres;

--
-- Name: group_user_map_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.group_user_map_id_seq OWNED BY public.group_user_map.id;


--
-- Name: message; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    receiver_id integer NOT NULL,
    content character varying NOT NULL,
    sebd_time timestamp without time zone NOT NULL
);


ALTER TABLE public.message OWNER TO postgres;

--
-- Name: TABLE message; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.message IS '用户私信表';


--
-- Name: message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.message_id_seq OWNER TO postgres;

--
-- Name: message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.message_id_seq OWNED BY public.message.id;


--
-- Name: message_list; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.message_list (
    id integer NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    relative_id integer NOT NULL,
    read boolean DEFAULT false NOT NULL
);


ALTER TABLE public.message_list OWNER TO postgres;

--
-- Name: TABLE message_list; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.message_list IS '消息通知';


--
-- Name: message_list_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.message_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.message_list_id_seq OWNER TO postgres;

--
-- Name: message_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.message_list_id_seq OWNED BY public.message_list.id;


--
-- Name: position_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.position_category (
    id integer NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.position_category OWNER TO postgres;

--
-- Name: TABLE position_category; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.position_category IS '职位类别信息表';


--
-- Name: position_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.position_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.position_category_id_seq OWNER TO postgres;

--
-- Name: position_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.position_category_id_seq OWNED BY public.position_category.id;


--
-- Name: position_recommend_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.position_recommend_data (
    id integer NOT NULL,
    position_id integer NOT NULL,
    next_id integer NOT NULL,
    hit_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.position_recommend_data OWNER TO postgres;

--
-- Name: position_recommend_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.position_recommend_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.position_recommend_data_id_seq OWNER TO postgres;

--
-- Name: position_recommend_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.position_recommend_data_id_seq OWNED BY public.position_recommend_data.id;


--
-- Name: position_user_recommend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.position_user_recommend (
    id integer NOT NULL,
    user_id integer NOT NULL,
    recommend json NOT NULL
);


ALTER TABLE public.position_user_recommend OWNER TO postgres;

--
-- Name: position_user_recommend_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.position_user_recommend_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.position_user_recommend_id_seq OWNER TO postgres;

--
-- Name: position_user_recommend_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.position_user_recommend_id_seq OWNED BY public.position_user_recommend.id;


--
-- Name: post_comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_comment (
    id integer NOT NULL,
    post_id integer NOT NULL,
    content character varying NOT NULL,
    user_id integer NOT NULL,
    "timestamp" timestamp without time zone DEFAULT LOCALTIMESTAMP NOT NULL
);


ALTER TABLE public.post_comment OWNER TO postgres;

--
-- Name: TABLE post_comment; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.post_comment IS '动态评论信息表';


--
-- Name: post_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.post_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.post_comment_id_seq OWNER TO postgres;

--
-- Name: post_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.post_comment_id_seq OWNED BY public.post_comment.id;


--
-- Name: post_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.post_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.post_id_seq OWNER TO postgres;

--
-- Name: post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.post_id_seq OWNED BY public.post.id;


--
-- Name: post_like; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.post_like (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.post_like OWNER TO postgres;

--
-- Name: TABLE post_like; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.post_like IS '点赞动态信息表';


--
-- Name: post_like_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.post_like_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.post_like_id_seq OWNER TO postgres;

--
-- Name: post_like_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.post_like_id_seq OWNED BY public.post_like.id;


--
-- Name: report_post; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_post (
    id integer NOT NULL,
    content character varying NOT NULL,
    user_id integer NOT NULL,
    post_id integer
);


ALTER TABLE public.report_post OWNER TO postgres;

--
-- Name: TABLE report_post; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.report_post IS '举报动态信息表';


--
-- Name: post_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.post_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.post_report_id_seq OWNER TO postgres;

--
-- Name: post_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.post_report_id_seq OWNED BY public.report_post.id;


--
-- Name: postion_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.postion_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.postion_info_id_seq OWNER TO postgres;

--
-- Name: postion_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.postion_info_id_seq OWNED BY public.position_info.id;


--
-- Name: report_comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_comment (
    id integer NOT NULL,
    content character varying NOT NULL,
    user_id integer NOT NULL,
    comment_id integer NOT NULL
);


ALTER TABLE public.report_comment OWNER TO postgres;

--
-- Name: report_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.report_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_comment_id_seq OWNER TO postgres;

--
-- Name: report_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.report_comment_id_seq OWNED BY public.report_comment.id;


--
-- Name: report_reply; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_reply (
    id integer NOT NULL,
    content character varying NOT NULL,
    user_id integer NOT NULL,
    reply_id integer NOT NULL
);


ALTER TABLE public.report_reply OWNER TO postgres;

--
-- Name: TABLE report_reply; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.report_reply IS '举报评论回复表';


--
-- Name: report_reply_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.report_reply_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.report_reply_id_seq OWNER TO postgres;

--
-- Name: report_reply_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.report_reply_id_seq OWNED BY public.report_reply.id;


--
-- Name: report_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.report_user (
    id integer NOT NULL,
    reporter_id integer NOT NULL,
    reported_id integer NOT NULL,
    reason character varying NOT NULL
);


ALTER TABLE public.report_user OWNER TO postgres;

--
-- Name: TABLE report_user; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.report_user IS '举报用户表';


--
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    password character varying NOT NULL,
    phone character varying NOT NULL,
    identity integer DEFAULT 101 NOT NULL
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- Name: user_credit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_credit (
    id integer NOT NULL,
    user_id integer NOT NULL,
    credit integer DEFAULT 10 NOT NULL,
    banned_begin_time timestamp without time zone
);


ALTER TABLE public.user_credit OWNER TO postgres;

--
-- Name: TABLE user_credit; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_credit IS '用户积分表';


--
-- Name: user_credit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_credit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_credit_id_seq OWNER TO postgres;

--
-- Name: user_credit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_credit_id_seq OWNED BY public.user_credit.id;


--
-- Name: user_follow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_follow (
    id integer NOT NULL,
    uid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE public.user_follow OWNER TO postgres;

--
-- Name: TABLE user_follow; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_follow IS '用户关注信息表';


--
-- Name: user_follow_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_follow_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_follow_id_seq OWNER TO postgres;

--
-- Name: user_follow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_follow_id_seq OWNED BY public.user_follow.id;


--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: user_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_info (
    id integer NOT NULL,
    user_id integer NOT NULL,
    nickname character varying NOT NULL,
    nikename_last_update timestamp without time zone NOT NULL,
    gender character varying NOT NULL,
    description character varying,
    avatar character varying,
    expected_career_id integer NOT NULL,
    register_time timestamp without time zone NOT NULL
);


ALTER TABLE public.user_info OWNER TO postgres;

--
-- Name: user_info_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_info_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_info_id_seq OWNER TO postgres;

--
-- Name: user_info_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_info_id_seq OWNED BY public.user_info.id;


--
-- Name: user_position_favorite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_position_favorite (
    id integer NOT NULL,
    position_info_id integer NOT NULL,
    user_id integer NOT NULL
);


ALTER TABLE public.user_position_favorite OWNER TO postgres;

--
-- Name: TABLE user_position_favorite; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_position_favorite IS '收藏职位信息表';


--
-- Name: user_position_favorite_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_position_favorite_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_position_favorite_id_seq OWNER TO postgres;

--
-- Name: user_position_favorite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_position_favorite_id_seq OWNED BY public.user_position_favorite.id;


--
-- Name: user_post_favorite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_post_favorite (
    id integer NOT NULL,
    user_id integer NOT NULL,
    post_id integer NOT NULL
);


ALTER TABLE public.user_post_favorite OWNER TO postgres;

--
-- Name: TABLE user_post_favorite; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_post_favorite IS '收藏动态信息表';


--
-- Name: user_post_favorite_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_post_favorite_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_post_favorite_id_seq OWNER TO postgres;

--
-- Name: user_post_favorite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_post_favorite_id_seq OWNED BY public.user_post_favorite.id;


--
-- Name: user_quota; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_quota (
    id integer NOT NULL,
    uid integer NOT NULL,
    quota integer NOT NULL
);


ALTER TABLE public.user_quota OWNER TO postgres;

--
-- Name: TABLE user_quota; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_quota IS '用户额度';


--
-- Name: user_quota_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_quota_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_quota_id_seq OWNER TO postgres;

--
-- Name: user_quota_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_quota_id_seq OWNED BY public.user_quota.id;


--
-- Name: user_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_report_id_seq OWNER TO postgres;

--
-- Name: user_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_report_id_seq OWNED BY public.report_user.id;


--
-- Name: authentication_info id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_info ALTER COLUMN id SET DEFAULT nextval('public.authentication_info_id_seq'::regclass);


--
-- Name: group id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."group" ALTER COLUMN id SET DEFAULT nextval('public.group_id_seq'::regclass);


--
-- Name: group_banned id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_banned ALTER COLUMN id SET DEFAULT nextval('public.group_banned_id_seq'::regclass);


--
-- Name: group_category id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_category ALTER COLUMN id SET DEFAULT nextval('public.group_category_id_seq'::regclass);


--
-- Name: group_modify id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_modify ALTER COLUMN id SET DEFAULT nextval('public.group_modify_id_seq'::regclass);


--
-- Name: group_user_map id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_user_map ALTER COLUMN id SET DEFAULT nextval('public.group_user_map_id_seq'::regclass);


--
-- Name: message id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message ALTER COLUMN id SET DEFAULT nextval('public.message_id_seq'::regclass);


--
-- Name: message_list id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_list ALTER COLUMN id SET DEFAULT nextval('public.message_list_id_seq'::regclass);


--
-- Name: position_category id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_category ALTER COLUMN id SET DEFAULT nextval('public.position_category_id_seq'::regclass);


--
-- Name: position_info id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_info ALTER COLUMN id SET DEFAULT nextval('public.postion_info_id_seq'::regclass);


--
-- Name: position_recommend_data id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_recommend_data ALTER COLUMN id SET DEFAULT nextval('public.position_recommend_data_id_seq'::regclass);


--
-- Name: position_user_recommend id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_user_recommend ALTER COLUMN id SET DEFAULT nextval('public.position_user_recommend_id_seq'::regclass);


--
-- Name: post id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post ALTER COLUMN id SET DEFAULT nextval('public.post_id_seq'::regclass);


--
-- Name: post_comment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment ALTER COLUMN id SET DEFAULT nextval('public.post_comment_id_seq'::regclass);


--
-- Name: post_comment_reply id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment_reply ALTER COLUMN id SET DEFAULT nextval('public.comment_reply_id_seq'::regclass);


--
-- Name: post_like id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_like ALTER COLUMN id SET DEFAULT nextval('public.post_like_id_seq'::regclass);


--
-- Name: report_comment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_comment ALTER COLUMN id SET DEFAULT nextval('public.report_comment_id_seq'::regclass);


--
-- Name: report_post id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_post ALTER COLUMN id SET DEFAULT nextval('public.post_report_id_seq'::regclass);


--
-- Name: report_reply id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_reply ALTER COLUMN id SET DEFAULT nextval('public.report_reply_id_seq'::regclass);


--
-- Name: report_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_user ALTER COLUMN id SET DEFAULT nextval('public.user_report_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: user_credit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_credit ALTER COLUMN id SET DEFAULT nextval('public.user_credit_id_seq'::regclass);


--
-- Name: user_follow id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_follow ALTER COLUMN id SET DEFAULT nextval('public.user_follow_id_seq'::regclass);


--
-- Name: user_info id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_info ALTER COLUMN id SET DEFAULT nextval('public.user_info_id_seq'::regclass);


--
-- Name: user_position_favorite id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_position_favorite ALTER COLUMN id SET DEFAULT nextval('public.user_position_favorite_id_seq'::regclass);


--
-- Name: user_post_favorite id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_post_favorite ALTER COLUMN id SET DEFAULT nextval('public.user_post_favorite_id_seq'::regclass);


--
-- Name: user_quota id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_quota ALTER COLUMN id SET DEFAULT nextval('public.user_quota_id_seq'::regclass);


--
-- Data for Name: authentication_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.authentication_info (id, user_id, identity, begin_time, end_time, company, "position", mail, company_serial, authentication_status, mail_can_verify) FROM stdin;
\.


--
-- Data for Name: group; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."group" (id, name, logo, description, group_category_id, logo_last_update) FROM stdin;
1	测试	没有logo.jpg	测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试	1	2020-04-24 15:14:09
\.


--
-- Data for Name: group_banned; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_banned (id, user_id, group_id) FROM stdin;
\.


--
-- Data for Name: group_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_category (id, name) FROM stdin;
1	学习
2	求职
3	公司
4	生活
\.


--
-- Data for Name: group_modify; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_modify (id, request_uid, type, reason, transform_uid, group_id) FROM stdin;
\.


--
-- Data for Name: group_user_map; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.group_user_map (id, user_id, group_id, state, user_join_time) FROM stdin;
\.


--
-- Data for Name: message; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message (id, sender_id, receiver_id, content, sebd_time) FROM stdin;
\.


--
-- Data for Name: message_list; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.message_list (id, type, relative_id, read) FROM stdin;
\.


--
-- Data for Name: position_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_category (id, name) FROM stdin;
1	技术
2	产品
3	运营
4	职能
5	设计
6	市场
7	金融
\.


--
-- Data for Name: position_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_info (id, name, company, description, post_mail, grade, location, position_category_id, post_user_id, post_time) FROM stdin;
1	软件开发	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	1	1	2019-10-13 00:00:00
2	C++工程师	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	1	2	2019-10-14 00:00:00
3	php工程师	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	1	3	2019-10-15 00:00:00
4	算法工程师	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	1	4	2019-10-16 00:00:00
5	java工程师	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	1	5	2019-10-17 00:00:00
6	前端开发工程师	百度	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	1	6	2019-10-18 00:00:00
7	客户端开发	滴滴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	1	7	2019-10-19 00:00:00
8	测试工程师	网易	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	1	8	2019-10-20 00:00:00
9	运维工程师	小米	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	1	9	2019-10-21 00:00:00
10	产品专员	华为	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	2	10	2019-10-22 00:00:00
11	网页产品经理	联想	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	2	11	2019-10-23 00:00:00
12	产品经理助理	学而思	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	2	12	2019-10-24 00:00:00
13	电商产品经理	猿辅导	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	2	13	2019-10-25 00:00:00
14	B端产品经理	用友	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	2	14	2019-10-26 00:00:00
15	数据产品经理	三七互娱	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	2	15	2019-10-27 00:00:00
16	产品运营	完美世界	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	3	16	2019-10-28 00:00:00
17	内容运营	西山居	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	3	17	2019-10-29 00:00:00
18	活动运营	快手	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	3	18	2019-10-30 00:00:00
19	商业化运营	bilibili	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	3	19	2019-10-31 00:00:00
20	策略运营	shopee	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	3	20	2019-11-01 00:00:00
21	用户运营	拼多多	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	3	1	2019-11-02 00:00:00
22	数据运营	斗鱼	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	3	2	2019-11-03 00:00:00
23	社区运营	虎牙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	3	3	2019-11-04 00:00:00
24	社群运营	欢聚时代	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	3	4	2019-11-05 00:00:00
25	人力资源专员	搜狐畅游	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	4	5	2019-11-06 00:00:00
26	招聘专员	小红书	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	4	6	2019-11-07 00:00:00
27	HRBP	作业帮	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	4	7	2019-11-08 00:00:00
28	培训经理	携程	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	4	8	2019-11-09 00:00:00
29	行政助理	去哪儿	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	4	9	2019-11-10 00:00:00
30	前台	同程艺龙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	4	10	2019-11-11 00:00:00
31	视觉设计师	跟谁学	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	5	11	2019-11-12 00:00:00
32	网页设计师	图森未来	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	5	12	2019-11-13 00:00:00
33	APP设计师	乐元素	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	5	13	2019-11-14 00:00:00
34	UI设计师	多益网络	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	5	14	2019-11-15 00:00:00
35	广告设计师	便利蜂	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	5	15	2019-11-16 00:00:00
36	交互设计师	360公司	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	5	16	2019-11-17 00:00:00
37	市场营销	深信服	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	6	17	2019-11-18 00:00:00
38	市场策划	奇安信	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	6	18	2019-11-19 00:00:00
39	商业渠道	4399	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	6	19	2019-11-20 00:00:00
40	海外公关	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	6	20	2019-11-21 00:00:00
41	政府关系	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	6	1	2019-11-22 00:00:00
42	广告协调	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	6	2	2019-11-23 00:00:00
43	媒介投放	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	6	3	2019-11-24 00:00:00
44	会计	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	7	4	2019-11-25 00:00:00
45	出纳	百度	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	7	5	2019-11-26 00:00:00
46	财务	滴滴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	7	6	2019-11-27 00:00:00
47	结算	网易	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	7	7	2019-11-28 00:00:00
48	税务	小米	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	7	8	2019-11-29 00:00:00
49	审计	华为	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	7	9	2019-11-30 00:00:00
50	风控	联想	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	7	10	2019-12-01 00:00:00
51	软件开发	学而思	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	1	11	2019-12-02 00:00:00
52	C++工程师	猿辅导	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	1	12	2019-12-03 00:00:00
53	php工程师	用友	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	1	13	2019-12-04 00:00:00
54	算法工程师	三七互娱	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	1	14	2019-12-05 00:00:00
55	java工程师	完美世界	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	1	15	2019-12-06 00:00:00
56	前端开发工程师	西山居	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	1	16	2019-12-07 00:00:00
57	客户端开发	快手	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	1	17	2019-12-08 00:00:00
58	测试工程师	bilibili	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	1	18	2019-12-09 00:00:00
59	运维工程师	shopee	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	1	19	2019-12-10 00:00:00
60	产品专员	拼多多	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	2	20	2019-12-11 00:00:00
61	网页产品经理	斗鱼	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	2	1	2019-12-12 00:00:00
62	产品经理助理	虎牙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	2	2	2019-12-13 00:00:00
63	电商产品经理	欢聚时代	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	2	3	2019-12-14 00:00:00
64	B端产品经理	搜狐畅游	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	2	4	2019-12-15 00:00:00
65	数据产品经理	小红书	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	2	5	2019-12-16 00:00:00
66	产品运营	作业帮	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	3	6	2019-12-17 00:00:00
67	内容运营	携程	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	3	7	2019-12-18 00:00:00
68	活动运营	去哪儿	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	3	8	2019-12-19 00:00:00
69	商业化运营	同程艺龙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	3	9	2019-12-20 00:00:00
70	策略运营	跟谁学	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	3	10	2019-12-21 00:00:00
71	用户运营	图森未来	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	0	北京	3	11	2019-12-22 00:00:00
72	数据运营	乐元素	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	0	上海	3	12	2019-12-23 00:00:00
73	社区运营	多益网络	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	3	13	2019-12-24 00:00:00
74	社群运营	便利蜂	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	3	14	2019-12-25 00:00:00
75	人力资源专员	360公司	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	4	15	2019-12-26 00:00:00
76	招聘专员	深信服	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	4	16	2019-12-27 00:00:00
77	HRBP	奇安信	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	4	17	2019-12-28 00:00:00
78	培训经理	4399	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	4	18	2019-12-29 00:00:00
79	行政助理	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	4	19	2019-12-30 00:00:00
80	前台	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	4	20	2019-12-31 00:00:00
81	视觉设计师	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	5	1	2020-01-01 00:00:00
82	网页设计师	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	5	2	2020-01-02 00:00:00
83	APP设计师	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	5	3	2020-01-03 00:00:00
84	UI设计师	百度	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	5	4	2020-01-04 00:00:00
85	广告设计师	滴滴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	5	5	2020-01-05 00:00:00
86	交互设计师	网易	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	5	6	2020-01-06 00:00:00
87	市场营销	小米	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	6	7	2020-01-07 00:00:00
88	市场策划	华为	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	6	8	2020-01-08 00:00:00
89	商业渠道	联想	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	6	9	2020-01-09 00:00:00
90	海外公关	学而思	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	6	10	2020-01-10 00:00:00
91	政府关系	猿辅导	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	6	11	2020-01-11 00:00:00
92	广告协调	用友	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	6	12	2020-01-12 00:00:00
93	媒介投放	三七互娱	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	6	13	2020-01-13 00:00:00
94	会计	完美世界	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	7	14	2020-01-14 00:00:00
95	出纳	西山居	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	7	15	2020-01-15 00:00:00
96	财务	快手	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	7	16	2020-01-16 00:00:00
97	结算	bilibili	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	7	17	2020-01-17 00:00:00
98	税务	shopee	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	7	18	2020-01-18 00:00:00
99	审计	拼多多	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	7	19	2020-01-19 00:00:00
100	风控	斗鱼	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	7	20	2020-01-20 00:00:00
101	软件开发	虎牙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	1	1	2020-01-21 00:00:00
102	C++工程师	欢聚时代	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	1	2	2020-01-22 00:00:00
103	php工程师	搜狐畅游	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	1	3	2020-01-23 00:00:00
104	算法工程师	小红书	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	1	4	2020-01-24 00:00:00
105	java工程师	作业帮	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	1	5	2020-01-25 00:00:00
106	前端开发工程师	携程	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	1	6	2020-01-26 00:00:00
107	客户端开发	去哪儿	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	1	7	2020-01-27 00:00:00
108	测试工程师	同程艺龙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	1	8	2020-01-28 00:00:00
109	运维工程师	跟谁学	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	1	9	2020-01-29 00:00:00
110	产品专员	图森未来	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	2	10	2020-01-30 00:00:00
111	网页产品经理	乐元素	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	2	11	2020-01-31 00:00:00
112	产品经理助理	多益网络	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	2	12	2020-02-01 00:00:00
113	电商产品经理	便利蜂	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	2	13	2020-02-02 00:00:00
114	B端产品经理	360公司	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	2	14	2020-02-03 00:00:00
115	数据产品经理	深信服	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	2	15	2020-02-04 00:00:00
116	产品运营	奇安信	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	3	16	2020-02-05 00:00:00
117	内容运营	4399	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	3	17	2020-02-06 00:00:00
118	活动运营	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	3	18	2020-02-07 00:00:00
119	商业化运营	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	3	19	2020-02-08 00:00:00
120	策略运营	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	3	20	2020-02-09 00:00:00
121	用户运营	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	3	1	2020-02-10 00:00:00
122	数据运营	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	3	2	2020-02-11 00:00:00
123	社区运营	百度	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	3	3	2020-02-12 00:00:00
124	社群运营	滴滴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	3	4	2020-02-13 00:00:00
125	人力资源专员	网易	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	4	5	2020-02-14 00:00:00
126	招聘专员	小米	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	4	6	2020-02-15 00:00:00
127	HRBP	华为	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	4	7	2020-02-16 00:00:00
128	培训经理	联想	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	4	8	2020-02-17 00:00:00
129	行政助理	学而思	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	4	9	2020-02-18 00:00:00
130	前台	猿辅导	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	4	10	2020-02-19 00:00:00
131	视觉设计师	用友	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	5	11	2020-02-20 00:00:00
132	网页设计师	三七互娱	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	5	12	2020-02-21 00:00:00
133	APP设计师	完美世界	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	5	13	2020-02-22 00:00:00
134	UI设计师	西山居	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	5	14	2020-02-23 00:00:00
135	广告设计师	快手	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	5	15	2020-02-24 00:00:00
136	交互设计师	bilibili	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	5	16	2020-02-25 00:00:00
137	市场营销	shopee	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	6	17	2020-02-26 00:00:00
138	市场策划	拼多多	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	6	18	2020-02-27 00:00:00
139	商业渠道	斗鱼	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	6	19	2020-02-28 00:00:00
140	海外公关	虎牙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	6	20	2020-02-29 00:00:00
141	政府关系	欢聚时代	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	6	1	2020-03-01 00:00:00
142	广告协调	搜狐畅游	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	6	2	2020-03-02 00:00:00
143	媒介投放	小红书	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	6	3	2020-03-03 00:00:00
144	会计	作业帮	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	7	4	2020-03-04 00:00:00
145	出纳	携程	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	7	5	2020-03-05 00:00:00
146	财务	去哪儿	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	7	6	2020-03-06 00:00:00
147	结算	同程艺龙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	7	7	2020-03-07 00:00:00
148	税务	跟谁学	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	7	8	2020-03-08 00:00:00
149	审计	图森未来	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	7	9	2020-03-09 00:00:00
150	风控	乐元素	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	7	10	2020-03-10 00:00:00
151	软件开发	多益网络	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	1	11	2020-03-11 00:00:00
152	C++工程师	便利蜂	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	1	12	2020-03-12 00:00:00
153	php工程师	360公司	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	1	13	2020-03-13 00:00:00
154	算法工程师	深信服	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	1	14	2020-03-14 00:00:00
155	java工程师	奇安信	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	1	15	2020-03-15 00:00:00
156	前端开发工程师	4399	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	1	16	2020-03-16 00:00:00
157	客户端开发	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	1	17	2020-03-17 00:00:00
158	测试工程师	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	1	18	2020-03-18 00:00:00
159	运维工程师	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	1	19	2020-03-19 00:00:00
160	产品专员	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	2	20	2020-03-20 00:00:00
161	网页产品经理	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	2	1	2020-03-21 00:00:00
162	产品经理助理	百度	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	2	2	2020-03-22 00:00:00
163	电商产品经理	滴滴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	2	3	2020-03-23 00:00:00
164	B端产品经理	网易	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	2	4	2020-03-24 00:00:00
165	数据产品经理	小米	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	2	5	2020-03-25 00:00:00
166	产品运营	华为	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	3	6	2020-03-26 00:00:00
167	内容运营	联想	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	3	7	2020-03-27 00:00:00
168	活动运营	学而思	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	3	8	2020-03-28 00:00:00
169	商业化运营	猿辅导	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	3	9	2020-03-29 00:00:00
170	策略运营	用友	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	3	10	2020-03-30 00:00:00
171	用户运营	三七互娱	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	3	11	2020-03-31 00:00:00
172	数据运营	完美世界	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	3	12	2020-04-01 00:00:00
173	社区运营	西山居	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	1	大连	3	13	2020-04-02 00:00:00
174	社群运营	快手	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	1	南京	3	14	2020-04-03 00:00:00
175	人力资源专员	bilibili	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	1	无锡	4	15	2020-04-04 00:00:00
176	招聘专员	shopee	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	1	杭州	4	16	2020-04-05 00:00:00
177	HRBP	拼多多	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	1	成都	4	17	2020-04-06 00:00:00
178	培训经理	斗鱼	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	1	重庆	4	18	2020-04-07 00:00:00
179	行政助理	虎牙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	1	西安	4	19	2020-04-08 00:00:00
180	前台	欢聚时代	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	1	天津	4	20	2020-04-09 00:00:00
181	视觉设计师	搜狐畅游	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	1	山东	5	1	2020-04-10 00:00:00
182	网页设计师	小红书	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	1	合肥	5	2	2020-04-11 00:00:00
183	APP设计师	作业帮	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	5	3	2020-04-12 00:00:00
184	UI设计师	携程	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	5	4	2020-04-13 00:00:00
185	广告设计师	去哪儿	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	0	深圳	5	5	2020-04-14 00:00:00
186	交互设计师	同程艺龙	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	0	沈阳	5	6	2020-04-15 00:00:00
187	市场营销	跟谁学	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	eee@tencent.com	0	大连	6	7	2020-04-16 00:00:00
188	市场策划	图森未来	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	fff@baijiahulian.com	0	南京	6	8	2020-04-17 00:00:00
189	商业渠道	乐元素	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ggg@meituan.com	0	无锡	6	9	2020-04-18 00:00:00
190	海外公关	多益网络	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	hhh@jd.com	0	杭州	6	10	2020-04-19 00:00:00
191	政府关系	便利蜂	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	iii@baidu.com	0	成都	6	11	2020-04-20 00:00:00
192	广告协调	360公司	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	jjj@xiaomi.com	0	重庆	6	12	2020-04-21 00:00:00
193	媒介投放	深信服	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	kkk@fenbi.com	0	西安	6	13	2020-04-22 00:00:00
194	会计	奇安信	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	lll@qq.com	0	天津	7	14	2020-04-23 00:00:00
195	出纳	4399	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	mmm@huawei.com	0	山东	7	15	2020-04-24 00:00:00
196	财务	阿里巴巴	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	nnn@yuanli.com	0	合肥	7	16	2020-04-25 00:00:00
197	结算	字节跳动	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	aaa@126.com	1	北京	7	17	2020-04-26 00:00:00
198	税务	腾讯	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	bbb@163.com	1	上海	7	18	2020-04-27 00:00:00
199	审计	京东	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ccc@antifin.com	1	深圳	7	19	2020-04-28 00:00:00
200	风控	美团	我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我我哦我我我我哦我我哦我我我我我\n	ddd@bytedance.com	1	沈阳	7	20	2020-04-29 00:00:00
\.


--
-- Data for Name: position_recommend_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_recommend_data (id, position_id, next_id, hit_count) FROM stdin;
1	1	51	1
2	2	52	2
3	3	53	3
4	4	54	4
5	5	55	5
6	6	56	6
7	7	57	7
8	8	58	8
9	9	59	9
10	10	60	10
11	11	61	11
12	12	62	12
13	13	63	13
14	14	64	14
15	15	65	15
16	16	66	16
17	17	67	17
18	18	68	18
19	19	69	19
20	20	70	20
21	21	71	21
22	22	72	22
23	23	73	23
24	24	74	24
25	25	75	25
26	26	76	26
27	27	77	27
28	28	78	28
29	29	79	29
30	30	80	30
31	31	81	31
32	32	82	32
33	33	83	33
34	34	84	34
35	35	85	35
36	36	86	36
37	37	87	37
38	38	88	38
39	39	89	39
40	40	90	40
41	41	91	41
42	42	92	42
43	43	93	43
44	44	94	44
45	45	95	45
46	46	96	46
47	47	97	47
48	48	98	48
49	49	99	49
50	50	100	50
51	101	151	51
52	102	152	52
53	103	153	53
54	104	154	54
55	105	155	55
56	106	156	56
57	107	157	57
58	108	158	58
59	109	159	59
60	110	160	60
61	111	161	61
62	112	162	62
63	113	163	63
64	114	164	64
65	115	165	65
66	116	166	66
67	117	167	67
68	118	168	68
69	119	169	69
70	120	170	70
71	121	171	71
72	122	172	72
73	123	173	73
74	124	174	74
75	125	175	75
76	126	176	76
77	127	177	77
78	128	178	78
79	129	179	79
80	130	180	80
81	131	181	81
82	132	182	82
83	133	183	83
84	134	184	84
85	135	185	85
86	136	186	86
87	137	187	87
88	138	188	88
89	139	189	89
90	140	190	90
91	141	191	91
92	142	192	92
93	143	193	93
94	144	194	94
95	145	195	95
96	146	196	96
97	147	197	97
98	148	198	98
99	149	199	99
100	150	200	100
\.


--
-- Data for Name: position_user_recommend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_user_recommend (id, user_id, recommend) FROM stdin;
1	1	{\r\n      "1": 0.1,\r\n      "2": 0.1\r\n    }
\.


--
-- Data for Name: post; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post (id, content, group_id, user_id, like_number, comment_number, favorite_number, is_pinned, "timestamp") FROM stdin;
\.


--
-- Data for Name: post_comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_comment (id, post_id, content, user_id, "timestamp") FROM stdin;
\.


--
-- Data for Name: post_comment_reply; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_comment_reply (id, comment_id, type, content, target_id, from_uid, to_uid, "timestamp") FROM stdin;
\.


--
-- Data for Name: post_like; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post_like (id, post_id, user_id) FROM stdin;
\.


--
-- Data for Name: report_comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_comment (id, content, user_id, comment_id) FROM stdin;
\.


--
-- Data for Name: report_post; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_post (id, content, user_id, post_id) FROM stdin;
\.


--
-- Data for Name: report_reply; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_reply (id, content, user_id, reply_id) FROM stdin;
\.


--
-- Data for Name: report_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.report_user (id, reporter_id, reported_id, reason) FROM stdin;
\.


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, password, phone, identity) FROM stdin;
1	ab123456789	13898301111	0
2	ab234567891	13898301112	0
3	ab345678912	13898301113	0
4	ab456789123	13898301114	0
5	ab567891234	13898301115	0
6	ab678912345	13898301116	0
7	ab789123456	13898301117	0
8	ab891234567	13898301118	101
9	ab912345678	13898301119	101
10	ab1122334455	13898301120	101
11	ab2233445566	13898301121	101
12	ab3344556677	13898301122	101
13	ab4455667788	13898301123	101
14	ab5566778899	13898301124	101
15	ab6677889911	13898301125	100
16	ab7788991122	13898301126	100
17	ab8899112233	13898301127	100
18	ab9911223344	13898301128	100
19	ab0011223344	13898301129	100
20	ab0123456789	13898301130	100
\.


--
-- Data for Name: user_credit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_credit (id, user_id, credit, banned_begin_time) FROM stdin;
\.


--
-- Data for Name: user_follow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_follow (id, uid, fid) FROM stdin;
\.


--
-- Data for Name: user_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_info (id, user_id, nickname, nikename_last_update, gender, description, avatar, expected_career_id, register_time) FROM stdin;
\.


--
-- Data for Name: user_position_favorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_position_favorite (id, position_info_id, user_id) FROM stdin;
\.


--
-- Data for Name: user_post_favorite; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_post_favorite (id, user_id, post_id) FROM stdin;
\.


--
-- Data for Name: user_quota; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_quota (id, uid, quota) FROM stdin;
\.


--
-- Name: authentication_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.authentication_info_id_seq', 1, false);


--
-- Name: comment_reply_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comment_reply_id_seq', 1, false);


--
-- Name: group_banned_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_banned_id_seq', 1, false);


--
-- Name: group_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_category_id_seq', 4, true);


--
-- Name: group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_id_seq', 1, true);


--
-- Name: group_modify_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_modify_id_seq', 1, true);


--
-- Name: group_user_map_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.group_user_map_id_seq', 1, false);


--
-- Name: message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.message_id_seq', 1, false);


--
-- Name: message_list_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.message_list_id_seq', 1, false);


--
-- Name: position_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_category_id_seq', 7, true);


--
-- Name: position_recommend_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_recommend_data_id_seq', 1, false);


--
-- Name: position_user_recommend_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_user_recommend_id_seq', 2, true);


--
-- Name: post_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.post_comment_id_seq', 1, false);


--
-- Name: post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.post_id_seq', 2, true);


--
-- Name: post_like_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.post_like_id_seq', 1, false);


--
-- Name: post_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.post_report_id_seq', 1, false);


--
-- Name: postion_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.postion_info_id_seq', 1, true);


--
-- Name: report_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.report_comment_id_seq', 1, false);


--
-- Name: report_reply_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.report_reply_id_seq', 1, false);


--
-- Name: user_credit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_credit_id_seq', 1, false);


--
-- Name: user_follow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_follow_id_seq', 1, false);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 13, true);


--
-- Name: user_info_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_info_id_seq', 1, false);


--
-- Name: user_position_favorite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_position_favorite_id_seq', 1, false);


--
-- Name: user_post_favorite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_post_favorite_id_seq', 1, false);


--
-- Name: user_quota_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_quota_id_seq', 1, false);


--
-- Name: user_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_report_id_seq', 1, false);


--
-- Name: authentication_info authentication_info_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_info
    ADD CONSTRAINT authentication_info_pk PRIMARY KEY (id);


--
-- Name: post_comment_reply comment_reply_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment_reply
    ADD CONSTRAINT comment_reply_pk PRIMARY KEY (id);


--
-- Name: group_banned group_banned_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_banned
    ADD CONSTRAINT group_banned_pk PRIMARY KEY (id);


--
-- Name: group_category group_category_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_category
    ADD CONSTRAINT group_category_pk PRIMARY KEY (id);


--
-- Name: group_modify group_modify_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_modify
    ADD CONSTRAINT group_modify_pk PRIMARY KEY (id);


--
-- Name: group group_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."group"
    ADD CONSTRAINT group_pk PRIMARY KEY (id);


--
-- Name: group_user_map group_user_map_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_user_map
    ADD CONSTRAINT group_user_map_pk PRIMARY KEY (id);


--
-- Name: message_list message_list_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message_list
    ADD CONSTRAINT message_list_pk PRIMARY KEY (id);


--
-- Name: message message_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pk PRIMARY KEY (id);


--
-- Name: position_category position_category_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_category
    ADD CONSTRAINT position_category_pk PRIMARY KEY (id);


--
-- Name: position_recommend_data position_recommend_data_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_recommend_data
    ADD CONSTRAINT position_recommend_data_pk PRIMARY KEY (id);


--
-- Name: position_user_recommend position_user_recommend_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_user_recommend
    ADD CONSTRAINT position_user_recommend_pk PRIMARY KEY (id);


--
-- Name: post_comment post_comment_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment
    ADD CONSTRAINT post_comment_pk PRIMARY KEY (id);


--
-- Name: post_like post_like_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_like
    ADD CONSTRAINT post_like_pk PRIMARY KEY (id);


--
-- Name: post post_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post
    ADD CONSTRAINT post_pk PRIMARY KEY (id);


--
-- Name: report_post post_report_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_post
    ADD CONSTRAINT post_report_pk PRIMARY KEY (id);


--
-- Name: position_info postion_info_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_info
    ADD CONSTRAINT postion_info_pk PRIMARY KEY (id);


--
-- Name: report_comment report_comment_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_comment
    ADD CONSTRAINT report_comment_pk PRIMARY KEY (id);


--
-- Name: report_reply report_reply_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_reply
    ADD CONSTRAINT report_reply_pk PRIMARY KEY (id);


--
-- Name: user_credit user_credit_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_credit
    ADD CONSTRAINT user_credit_pk PRIMARY KEY (id);


--
-- Name: user_follow user_follow_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_follow
    ADD CONSTRAINT user_follow_pk PRIMARY KEY (id);


--
-- Name: user_info user_info_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_info
    ADD CONSTRAINT user_info_pk PRIMARY KEY (id);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (id);


--
-- Name: user_position_favorite user_position_favorite_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_position_favorite
    ADD CONSTRAINT user_position_favorite_pk PRIMARY KEY (id);


--
-- Name: user_post_favorite user_post_favorite_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_post_favorite
    ADD CONSTRAINT user_post_favorite_pk PRIMARY KEY (id);


--
-- Name: user_quota user_quota_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_quota
    ADD CONSTRAINT user_quota_pk PRIMARY KEY (id);


--
-- Name: report_user user_report_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_user
    ADD CONSTRAINT user_report_pk PRIMARY KEY (id);


--
-- Name: authentication_info_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX authentication_info_id_uindex ON public.authentication_info USING btree (id);


--
-- Name: comment_reply_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX comment_reply_id_uindex ON public.post_comment_reply USING btree (id);


--
-- Name: group_banned_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX group_banned_id_uindex ON public.group_banned USING btree (id);


--
-- Name: group_category_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX group_category_id_uindex ON public.group_category USING btree (id);


--
-- Name: group_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX group_id_uindex ON public."group" USING btree (id);


--
-- Name: group_modify_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX group_modify_id_uindex ON public.group_modify USING btree (id);


--
-- Name: group_user_map_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX group_user_map_id_uindex ON public.group_user_map USING btree (id);


--
-- Name: message_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX message_id_uindex ON public.message USING btree (id);


--
-- Name: message_list_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX message_list_id_uindex ON public.message_list USING btree (id);


--
-- Name: position_category_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_category_id_uindex ON public.position_category USING btree (id);


--
-- Name: position_category_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_category_name_uindex ON public.position_category USING btree (name);


--
-- Name: position_recommend_data_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_recommend_data_id_uindex ON public.position_recommend_data USING btree (id);


--
-- Name: position_recommend_data_position_id_next_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_recommend_data_position_id_next_id_uindex ON public.position_recommend_data USING btree (position_id, next_id);


--
-- Name: position_user_recommend_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_user_recommend_id_uindex ON public.position_user_recommend USING btree (id);


--
-- Name: position_user_recommend_user_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_user_recommend_user_id_uindex ON public.position_user_recommend USING btree (user_id);


--
-- Name: post_comment_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX post_comment_id_uindex ON public.post_comment USING btree (id);


--
-- Name: post_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX post_id_uindex ON public.post USING btree (id);


--
-- Name: post_like_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX post_like_id_uindex ON public.post_like USING btree (id);


--
-- Name: post_report_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX post_report_id_uindex ON public.report_post USING btree (id);


--
-- Name: postion_info_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX postion_info_id_uindex ON public.position_info USING btree (id);


--
-- Name: report_comment_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX report_comment_id_uindex ON public.report_comment USING btree (id);


--
-- Name: report_reply_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX report_reply_id_uindex ON public.report_reply USING btree (id);


--
-- Name: user_credit_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_credit_id_uindex ON public.user_credit USING btree (id);


--
-- Name: user_follow_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_follow_id_uindex ON public.user_follow USING btree (id);


--
-- Name: user_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_id_uindex ON public."user" USING btree (id);


--
-- Name: user_info_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_info_id_uindex ON public.user_info USING btree (id);


--
-- Name: user_info_nickname_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_info_nickname_uindex ON public.user_info USING btree (nickname);


--
-- Name: user_info_user_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_info_user_id_uindex ON public.user_info USING btree (user_id);


--
-- Name: user_phone_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_phone_uindex ON public."user" USING btree (phone);


--
-- Name: user_position_favorite_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_position_favorite_id_uindex ON public.user_position_favorite USING btree (id);


--
-- Name: user_post_favorite_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_post_favorite_id_uindex ON public.user_post_favorite USING btree (id);


--
-- Name: user_quota_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_quota_id_uindex ON public.user_quota USING btree (id);


--
-- Name: user_quota_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_quota_uid_uindex ON public.user_quota USING btree (uid);


--
-- Name: user_report_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX user_report_id_uindex ON public.report_user USING btree (id);


--
-- Name: authentication_info authentication_info_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.authentication_info
    ADD CONSTRAINT authentication_info_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_comment_reply comment_reply_post_comment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment_reply
    ADD CONSTRAINT comment_reply_post_comment_id_fk FOREIGN KEY (comment_id) REFERENCES public.post_comment(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_comment_reply comment_reply_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment_reply
    ADD CONSTRAINT comment_reply_user_id_fk FOREIGN KEY (from_uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_comment_reply comment_reply_user_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment_reply
    ADD CONSTRAINT comment_reply_user_id_fk_2 FOREIGN KEY (to_uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_comment comment_report_comment_reply_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_comment
    ADD CONSTRAINT comment_report_comment_reply_id_fk FOREIGN KEY (comment_id) REFERENCES public.post_comment_reply(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_comment comment_report_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_comment
    ADD CONSTRAINT comment_report_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_banned group_banned_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_banned
    ADD CONSTRAINT group_banned_group_id_fk FOREIGN KEY (group_id) REFERENCES public."group"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_banned group_banned_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_banned
    ADD CONSTRAINT group_banned_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group group_group_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."group"
    ADD CONSTRAINT group_group_category_id_fk FOREIGN KEY (group_category_id) REFERENCES public.group_category(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_modify group_modify_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_modify
    ADD CONSTRAINT group_modify_group_id_fk FOREIGN KEY (group_id) REFERENCES public."group"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_modify group_modify_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_modify
    ADD CONSTRAINT group_modify_user_id_fk FOREIGN KEY (request_uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_modify group_modify_user_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_modify
    ADD CONSTRAINT group_modify_user_id_fk_2 FOREIGN KEY (transform_uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_user_map group_user_map_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_user_map
    ADD CONSTRAINT group_user_map_group_id_fk FOREIGN KEY (group_id) REFERENCES public."group"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: group_user_map group_user_map_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.group_user_map
    ADD CONSTRAINT group_user_map_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message message_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_user_id_fk FOREIGN KEY (sender_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: message message_user_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_user_id_fk_2 FOREIGN KEY (receiver_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: position_recommend_data position_recommend_data_position_info_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_recommend_data
    ADD CONSTRAINT position_recommend_data_position_info_id_fk FOREIGN KEY (position_id) REFERENCES public.position_info(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: position_recommend_data position_recommend_data_position_info_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_recommend_data
    ADD CONSTRAINT position_recommend_data_position_info_id_fk_2 FOREIGN KEY (next_id) REFERENCES public.position_info(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: position_user_recommend position_user_recommend_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_user_recommend
    ADD CONSTRAINT position_user_recommend_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_comment post_comment_post_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment
    ADD CONSTRAINT post_comment_post_id_fk FOREIGN KEY (post_id) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_comment post_comment_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_comment
    ADD CONSTRAINT post_comment_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post post_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post
    ADD CONSTRAINT post_group_id_fk FOREIGN KEY (group_id) REFERENCES public."group"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_like post_like_post_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_like
    ADD CONSTRAINT post_like_post_id_fk FOREIGN KEY (post_id) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post_like post_like_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post_like
    ADD CONSTRAINT post_like_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_post post_report_post_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_post
    ADD CONSTRAINT post_report_post_id_fk FOREIGN KEY (post_id) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_post post_report_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_post
    ADD CONSTRAINT post_report_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: post post_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.post
    ADD CONSTRAINT post_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: position_info postion_info_position_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_info
    ADD CONSTRAINT postion_info_position_category_id_fk FOREIGN KEY (position_category_id) REFERENCES public.position_category(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: position_info postion_info_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.position_info
    ADD CONSTRAINT postion_info_user_id_fk FOREIGN KEY (post_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_reply report_reply_post_comment_reply_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_reply
    ADD CONSTRAINT report_reply_post_comment_reply_id_fk FOREIGN KEY (reply_id) REFERENCES public.post_comment_reply(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_reply report_reply_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_reply
    ADD CONSTRAINT report_reply_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_credit user_credit_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_credit
    ADD CONSTRAINT user_credit_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_follow user_follow_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_follow
    ADD CONSTRAINT user_follow_user_id_fk FOREIGN KEY (uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_follow user_follow_user_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_follow
    ADD CONSTRAINT user_follow_user_id_fk_2 FOREIGN KEY (fid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_info user_info_position_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_info
    ADD CONSTRAINT user_info_position_category_id_fk FOREIGN KEY (expected_career_id) REFERENCES public.position_category(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_info user_info_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_info
    ADD CONSTRAINT user_info_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_position_favorite user_position_favorite_postion_info_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_position_favorite
    ADD CONSTRAINT user_position_favorite_postion_info_id_fk FOREIGN KEY (position_info_id) REFERENCES public.position_info(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_position_favorite user_position_favorite_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_position_favorite
    ADD CONSTRAINT user_position_favorite_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_post_favorite user_post_favorite_post_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_post_favorite
    ADD CONSTRAINT user_post_favorite_post_id_fk FOREIGN KEY (post_id) REFERENCES public.post(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_post_favorite user_post_favorite_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_post_favorite
    ADD CONSTRAINT user_post_favorite_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_quota user_quota_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_quota
    ADD CONSTRAINT user_quota_user_id_fk FOREIGN KEY (uid) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_user user_report_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_user
    ADD CONSTRAINT user_report_user_id_fk FOREIGN KEY (reported_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_user user_report_user_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.report_user
    ADD CONSTRAINT user_report_user_id_fk_2 FOREIGN KEY (reporter_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

