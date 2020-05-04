package com.Rayfalling.middleware.data.Recommend;

import java.sql.Timestamp;
import java.time.LocalDateTime;

public class Position {
    //创建时间
    private final LocalDateTime localDateTime;
    private int id = 0;
    private int label = 0;
    
    public Position(int id, int label, LocalDateTime localDateTime) {
        this.id = id;
        this.label = label;
        this.localDateTime = localDateTime;
    }
    
    public int getId() {
        return id;
    }
    
    public int getLabel() {
        return label;
    }
    
    public LocalDateTime getLocalDateTime() {
        return localDateTime;
    }
    
    public Long getTimestamp() {
        return Timestamp.valueOf(localDateTime).getTime();
    }
}
