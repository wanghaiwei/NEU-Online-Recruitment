create or replace function GroupAdminDelete(group_delete_id int, group_user_id int, group_delete_reason varchar)
    returns integer
as
$GroupAdminDelete$
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
$GroupAdminDelete$ LANGUAGE plpgsql;