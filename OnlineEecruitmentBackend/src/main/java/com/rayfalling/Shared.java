package com.Rayfalling;

import io.reactiverse.reactivex.pgclient.PgPool;
import io.vertx.reactivex.core.Vertx;
import io.vertx.reactivex.core.http.HttpServer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Shared {
    private static Logger RouterLogger = LogManager.getLogger("Router");
    private static Logger DatabaseLogger = LogManager.getLogger("Database");
    private static Logger logger = LogManager.getLogger("Main");
    private static Vertx vertx = Vertx.vertx();
    private static HttpServer httpServer;
    
    private static Shared instance = new Shared();
    
    /**
     * 工程 Postgresql 数据库连接池对象
     */
    private static PgPool pgPool;
    
    public static Logger getDatabaseLogger() {
        return DatabaseLogger;
    }
    
    public static Logger getLogger() {
        return logger;
    }
    
    public static Logger getRouterLogger() {
        return RouterLogger;
    }
    
    public static Vertx getVertx() {
        return vertx;
    }
    
    public static PgPool getPgPool() {
        return pgPool;
    }
    
    public static HttpServer getHttpServer() {
        return httpServer;
    }
    
    public static void setPgPool(PgPool pgPool) {
        Shared.pgPool = pgPool;
    }
    
    public static void setHttpServer(HttpServer httpServer) {
        Shared.httpServer = httpServer;
    }
}
