package com.Rayfalling.middleware.data.Recommend;

public class Position {
    private int id = 0;
    private int label = 0;
    
    public Position(int id, int label) {
        this.id = id;
        this.label = label;
    }
    
    public int getId() {
        return id;
    }
    
    public int getLabel() {
        return label;
    }
}
