select *
from position_info
where id = any ($1);