package com.Rayfalling.middleware.data.Recommend;

import java.util.Objects;

public class RecommendMap {
    //正在浏览的职位
    private int sourceId = 0;
    
    //推荐的职位
    private int nextId = 0;
    
    //命中次数
    private int hitCount = 0;
    
    public RecommendMap(int sourceId, int nextId, int hitCount) {
        this.sourceId = sourceId;
        this.nextId = nextId;
        this.hitCount = hitCount;
    }
    
    public int getHitCount() {
        return hitCount;
    }
    
    public int getNextId() {
        return nextId;
    }
    
    public int getSourceId() {
        return sourceId;
    }
    
    public void hit() {
        hitCount++;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof RecommendMap)) return false;
        RecommendMap that = (RecommendMap) o;
        return getSourceId() == that.getSourceId() &&
               getNextId() == that.getNextId();
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(getSourceId(), getNextId(), getHitCount());
    }
}
