package com.Rayfalling.middleware.data.Recommend;

import java.time.LocalDateTime;

public class Position {
    private int id = 0;
    private int label = 0;
    //创建时间
    private final LocalDateTime localDateTime;
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
}
