create or replace function FetchAllPost(post_group_id int, sort int)
    returns SETOF post
as
$FetchAllPost$
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
$FetchAllPost$ LANGUAGE plpgsql;