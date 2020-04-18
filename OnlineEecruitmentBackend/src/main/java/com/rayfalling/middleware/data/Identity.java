package com.Rayfalling.middleware.data;

/**
 * 身份数据枚举类
 */
public enum Identity {
    SUPER_ADMIN(0, 0, "超级管理员"),
    GROUP_ADMIN_HR(100, 1, "圈主-HR"),
    GROUP_ADMIN_STAFF(100, 0, "圈主-员工"),
    COMMON_USER_HR(101, 1, "普通用户-HR"),
    COMMON_USER_STAFF(101, 0, "普通用户-员工"),
    COMMON_USER_UNRECOGNIZED(101, -1, "普通用户-未认证");
    
    int mask, category;
    String description;
    
    Identity(int mask, int category, String description) {
        this.mask = mask;
        this.category = category;
        this.description = description;
    }
    
    public int mapCategory(String category) {
        switch (category) {
            case "HR":
                return 1;
            case "员工":
                return 0;
        }
        return 0;
    }
}
