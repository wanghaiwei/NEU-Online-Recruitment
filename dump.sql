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
1	1	0	1111	\N	1
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
1	aaa	a	a	sda	1	ccc	1	1	2020-04-27 17:03:18.710101
\.


--
-- Data for Name: position_recommend_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_recommend_data (id, position_id, next_id, hit_count) FROM stdin;
\.


--
-- Data for Name: position_user_recommend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.position_user_recommend (id, user_id, recommend) FROM stdin;
\.


--
-- Data for Name: post; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.post (id, content, group_id, user_id, like_number, comment_number, favorite_number, is_pinned, "timestamp") FROM stdin;
2	dfgjdfj	1	1	56	22	46	f	2020-04-24 13:23:04.500617
1	213233	1	1	14	23	44	f	2020-04-22 13:23:04.5
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
1	1234556	18262258003	101
12	1234556	17704226312	101
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

SELECT pg_catalog.setval('public.position_user_recommend_id_seq', 1, false);


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

SELECT pg_catalog.setval('public.user_id_seq', 12, true);


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
-- Name: position_user_recommend_id_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX position_user_recommend_id_uindex ON public.position_user_recommend USING btree (id);


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

